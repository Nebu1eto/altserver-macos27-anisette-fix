import Foundation

@main
struct AltServerAnisetteHelper {
    static func main() async throws {
        let fileManager = FileManager.default
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
        let supportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("AltServer", isDirectory: true)
        let userURL = supportURL.appendingPathComponent(
            "RemoteAnisetteUser.json",
            isDirectory: false
        )

        let identity: AnisetteV3Identity
        if let data = try? Data(contentsOf: userURL),
           let savedIdentity = try? JSONDecoder().decode(
               AnisetteV3Identity.self,
               from: data
           ) {
            identity = savedIdentity
        } else {
            try fileManager.createDirectory(
                at: supportURL,
                withIntermediateDirectories: true
            )
            let client = AnisetteV3Client()
            let provisionedIdentity = try await withRetries {
                try await client.provision(.create(serverURL: serverURL))
            }
            let data = try JSONEncoder().encode(provisionedIdentity)
            try data.write(to: userURL, options: .atomic)
            try fileManager.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: userURL.path
            )
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
