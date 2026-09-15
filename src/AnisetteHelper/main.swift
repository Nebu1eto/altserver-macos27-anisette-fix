import Foundation
import Darwin

@main
struct AltServerAnisetteHelper {
    static func main() async throws {
        let serverURL: URL
        if let configuredServerURL = ProcessInfo.processInfo.environment[
            "ALTSERVER_ANISETTE_SERVER_URL"
        ] {
            guard let parsedServerURL = URL(string: configuredServerURL),
                  AnisetteURLPolicy.isValidServerURL(parsedServerURL) else {
                throw AnisetteV3Client.ClientError.invalidResponse("server URL")
            }
            serverURL = parsedServerURL
        } else {
            serverURL = URL(string: "https://ani.sidestore.zip")!
        }
        let identityStorage = try AnisetteIdentityStorage()

        let identity: AnisetteV3Identity
        if let savedIdentity = try identityStorage.load() {
            identity = savedIdentity
        } else {
            let client = AnisetteV3Client()
            let provisionedIdentity = try await withRetries {
                try await client.provision(.create(serverURL: serverURL))
            }
            let data = try JSONEncoder().encode(provisionedIdentity)
            try identityStorage.save(data)
            identity = provisionedIdentity
        }

        let headers = try await withRetries {
            try await AnisetteV3Client().fetchHeaders(for: identity)
        }
        let output = try JSONSerialization.data(withJSONObject: headers)
        FileHandle.standardOutput.write(output)
    }

    private static func withRetries<T>(
        attempts: Int = 3,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        precondition(attempts > 0)

        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch where attempt < attempts {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }
        }

        fatalError("Unreachable")
    }
}

/// Descriptor-relative storage for the persisted RemoteAnisette identity.
///
/// The identity is deliberately kept behind this small POSIX boundary.  Path
/// based Foundation reads and writes follow links and make it possible for
/// another process to change the object between validation and use.  Every
/// operation below opens the private support directory and then addresses the
/// identity by name relative to that descriptor.
struct AnisetteIdentityStorage: Sendable {
    private static let identityName = "RemoteAnisetteUser.json"
    private static let maxIdentityBytes = 64 * 1024
    private static let maxInterruptedIOAttempts = 16
    private static let privateDirectoryMode: mode_t = 0o700
    private static let privateFileMode: mode_t = 0o600

    private let homeDirectory: URL

    init() throws {
        homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            .standardizedFileURL
        guard homeDirectory.isFileURL,
              homeDirectory.path.hasPrefix("/") else {
            throw StorageError.invalidHomeDirectory
        }

        // Verify (and, where safe, tighten) the complete expected directory
        // chain before any identity bytes are read or written.
        let supportFD = try openSupportDirectory()
        close(supportFD)
    }

    /// Loads and decodes the existing identity.  A missing target is the one
    /// normal case that means a new identity should be provisioned.
    func load() throws -> AnisetteV3Identity? {
        let supportFD = try openSupportDirectory()
        defer { close(supportFD) }

        let fd = openat(
            supportFD,
            Self.identityName,
            O_RDONLY | O_NONBLOCK | O_NOFOLLOW | O_CLOEXEC
        )
        guard fd >= 0 else {
            let error = errno
            if error == ENOENT {
                return nil
            }
            throw StorageError.posix(operation: "open identity", code: error)
        }
        defer { close(fd) }

        let bytes = try readVerifiedIdentity(fd)
        do {
            return try JSONDecoder().decode(AnisetteV3Identity.self, from: bytes)
        } catch {
            throw StorageError.invalidIdentity
        }
    }

    /// Creates the identity without ever replacing an existing directory
    /// entry.  `renameatx_np(..., RENAME_EXCL)` makes the final publication
    /// atomic and fails closed if another process created the target (including
    /// a symlink) while provisioning was in flight.
    func save(_ data: Data) throws {
        guard data.count <= Self.maxIdentityBytes else {
            throw StorageError.identityTooLarge
        }

        let supportFD = try openSupportDirectory()
        defer { close(supportFD) }

        let temporaryName = ".RemoteAnisetteUser.\(UUID().uuidString).tmp"
        let temporaryFD = openat(
            supportFD,
            temporaryName,
            O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW,
            Self.privateFileMode
        )
        guard temporaryFD >= 0 else {
            throw StorageError.posix(operation: "create identity temporary", code: errno)
        }

        var published = false
        defer {
            close(temporaryFD)
            if !published {
                _ = unlinkat(supportFD, temporaryName, 0)
            }
        }

        try writeAll(data, to: temporaryFD)
        if fsync(temporaryFD) != 0 {
            throw StorageError.posix(operation: "fsync identity temporary", code: errno)
        }
        _ = try verifyRegularFile(temporaryFD, expectedSize: off_t(data.count))

        let result = renameatx_np(
            supportFD,
            temporaryName,
            supportFD,
            Self.identityName,
            UInt32(RENAME_EXCL)
        )
        guard result == 0 else {
            throw StorageError.posix(operation: "publish identity", code: errno)
        }
        published = true

        // Ensure the directory entry itself reaches disk before returning.
        // This does not replace the descriptor-based validation above; it only
        // gives a completed first-write durable semantics.
        if fsync(supportFD) != 0 {
            throw StorageError.posix(operation: "fsync identity directory", code: errno)
        }
    }

    private func openSupportDirectory() throws -> Int32 {
        let homeFD = try openDirectory(
            path: homeDirectory.path,
            operation: "open home directory"
        )
        defer { close(homeFD) }

        let libraryFD = try openOrCreateDirectory(
            parentFD: homeFD,
            name: "Library",
            privateDirectory: false
        )
        defer { close(libraryFD) }

        let applicationSupportFD = try openOrCreateDirectory(
            parentFD: libraryFD,
            name: "Application Support",
            privateDirectory: false
        )
        defer { close(applicationSupportFD) }

        return try openOrCreateDirectory(
            parentFD: applicationSupportFD,
            name: "AltServer",
            privateDirectory: true
        )
    }

    private func openOrCreateDirectory(
        parentFD: Int32,
        name: String,
        privateDirectory: Bool
    ) throws -> Int32 {
        let flags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        var fd = openat(parentFD, name, flags)
        if fd < 0 {
            let error = errno
            guard error == ENOENT else {
                throw StorageError.posix(operation: "open directory \(name)", code: error)
            }

            if mkdirat(parentFD, name, Self.privateDirectoryMode) != 0 {
                let mkdirError = errno
                guard mkdirError == EEXIST else {
                    throw StorageError.posix(
                        operation: "create directory \(name)",
                        code: mkdirError
                    )
                }
            }
            fd = openat(parentFD, name, flags)
            guard fd >= 0 else {
                throw StorageError.posix(operation: "open directory \(name)", code: errno)
            }
        }

        do {
            try verifyDirectory(fd, privateDirectory: privateDirectory)
            return fd
        } catch {
            close(fd)
            throw error
        }
    }

    private func openDirectory(path: String, operation: String) throws -> Int32 {
        let fd = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else {
            throw StorageError.posix(operation: operation, code: errno)
        }
        do {
            try verifyDirectory(fd, privateDirectory: false)
            return fd
        } catch {
            close(fd)
            throw error
        }
    }

    private func verifyDirectory(
        _ fd: Int32,
        privateDirectory: Bool
    ) throws {
        var metadata = stat()
        guard fstat(fd, &metadata) == 0 else {
            throw StorageError.posix(operation: "stat directory", code: errno)
        }
        guard metadata.st_mode & S_IFMT == S_IFDIR else {
            throw StorageError.notDirectory
        }
        guard metadata.st_uid == geteuid() else {
            throw StorageError.directoryOwnerMismatch
        }
        // A directory has at least its own `.` and parent `..` links.  Unlike
        // regular files, directory link counts may grow as child directories
        // are created, so only the lower bound is meaningful here.
        guard metadata.st_nlink >= 2 else {
            throw StorageError.invalidDirectoryLinks
        }

        guard privateDirectory else { return }
        let mode = metadata.st_mode & 0o7777
        if mode != Self.privateDirectoryMode {
            guard fchmod(fd, Self.privateDirectoryMode) == 0 else {
                throw StorageError.posix(operation: "tighten directory mode", code: errno)
            }
            guard fstat(fd, &metadata) == 0 else {
                throw StorageError.posix(operation: "restat directory", code: errno)
            }
        }
        guard metadata.st_mode & 0o7777 == Self.privateDirectoryMode else {
            throw StorageError.invalidDirectoryMode
        }
    }

    private func readVerifiedIdentity(_ fd: Int32) throws -> Data {
        let before = try verifyRegularFile(fd)
        guard before.st_size >= 0,
              before.st_size <= off_t(Self.maxIdentityBytes) else {
            throw StorageError.identityTooLarge
        }

        var bytes = Data()
        bytes.reserveCapacity(Int(before.st_size))
        var buffer = [UInt8](repeating: 0, count: 16 * 1024)
        var interruptedReads = 0
        while true {
            let count = buffer.withUnsafeMutableBytes { rawBuffer -> Int in
                guard let baseAddress = rawBuffer.baseAddress else { return 0 }
                return read(fd, baseAddress, rawBuffer.count)
            }
            if count > 0 {
                bytes.append(buffer, count: count)
                guard bytes.count <= Self.maxIdentityBytes else {
                    throw StorageError.identityTooLarge
                }
                interruptedReads = 0
                continue
            }
            if count == 0 {
                break
            }
            let error = errno
            if error == EINTR {
                interruptedReads += 1
                guard interruptedReads <= Self.maxInterruptedIOAttempts else {
                    throw StorageError.posix(operation: "read identity", code: EINTR)
                }
                continue
            }
            throw StorageError.posix(operation: "read identity", code: error)
        }

        let after = try verifyRegularFile(fd)
        guard sameFileIdentity(before, after),
              after.st_size == off_t(bytes.count),
              off_t(bytes.count) == before.st_size else {
            throw StorageError.identityChanged
        }
        return bytes
    }

    private func verifyRegularFile(
        _ fd: Int32,
        expectedSize: off_t? = nil
    ) throws -> stat {
        var metadata = stat()
        guard fstat(fd, &metadata) == 0 else {
            throw StorageError.posix(operation: "stat identity", code: errno)
        }
        guard metadata.st_mode & S_IFMT == S_IFREG else {
            throw StorageError.notRegularFile
        }
        guard metadata.st_uid == geteuid() else {
            throw StorageError.fileOwnerMismatch
        }
        guard metadata.st_nlink == 1 else {
            throw StorageError.invalidFileLinks
        }
        guard metadata.st_mode & 0o7777 == Self.privateFileMode else {
            throw StorageError.invalidFileMode
        }
        if let expectedSize {
            guard metadata.st_size == expectedSize else {
                throw StorageError.identityChanged
            }
        }
        return metadata
    }

    private func writeAll(_ data: Data, to fd: Int32) throws {
        var offset = 0
        var interruptedWrites = 0
        try data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            while offset < rawBuffer.count {
                let count = write(
                    fd,
                    baseAddress.advanced(by: offset),
                    rawBuffer.count - offset
                )
                if count > 0 {
                    offset += count
                    interruptedWrites = 0
                    continue
                }
                if count < 0 {
                    let error = errno
                    if error == EINTR {
                        interruptedWrites += 1
                        guard interruptedWrites <= Self.maxInterruptedIOAttempts else {
                            throw StorageError.posix(operation: "write identity", code: EINTR)
                        }
                        continue
                    }
                    throw StorageError.posix(operation: "write identity", code: error)
                }
                throw StorageError.posix(operation: "write identity", code: errno)
            }
        }
    }

    private func sameFileIdentity(_ lhs: stat, _ rhs: stat) -> Bool {
        lhs.st_dev == rhs.st_dev &&
            lhs.st_ino == rhs.st_ino &&
            lhs.st_mode == rhs.st_mode &&
            lhs.st_uid == rhs.st_uid &&
            lhs.st_nlink == rhs.st_nlink &&
            lhs.st_size == rhs.st_size &&
            lhs.st_mtimespec.tv_sec == rhs.st_mtimespec.tv_sec &&
            lhs.st_mtimespec.tv_nsec == rhs.st_mtimespec.tv_nsec &&
            lhs.st_ctimespec.tv_sec == rhs.st_ctimespec.tv_sec &&
            lhs.st_ctimespec.tv_nsec == rhs.st_ctimespec.tv_nsec
    }

    enum StorageError: Error {
        case invalidHomeDirectory
        case posix(operation: String, code: Int32)
        case notDirectory
        case directoryOwnerMismatch
        case invalidDirectoryLinks
        case invalidDirectoryMode
        case notRegularFile
        case fileOwnerMismatch
        case invalidFileLinks
        case invalidFileMode
        case identityTooLarge
        case identityChanged
        case invalidIdentity
    }
}
