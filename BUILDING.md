# Building

This document describes the v1.0.8/v3.7 macOS payload build. It does not build
or distribute an iPhone IPA. Use the standard official **Install AltStore…**
flow for the on-device app.

## Requirements and input

- Apple Silicon Mac running the tested/supported macOS 27 target natively
  (`arm64`; Rosetta is rejected). The source has no OS-version gate; other
  versions are unsupported and unverified.
- Xcode Command Line Tools available through `xcrun`.
- The official, unmodified `/Applications/AltServer.app` from AltServer
  1.7.6/build 94. The input must remain universal (`arm64` + `x86_64`),
  Developer ID signed, deeply verifiable, Gatekeeper-accepted, and notarized.

The official app itself is a build input and is not redistributed as source or a
release asset. The locally injected payload is the prepared v1.0.8/v3.7 release
candidate based on official AltServer 1.7.6/build 94; GitHub publication is
pending.
`scripts/build_release.sh` rejects a stale or already-patched app, dynamic
`AltSign` payloads, and embedded IPA files. It also verifies the frozen v3.7
source gate before compiling:

```text
src/AltServerAnisetteFix.m
SHA-256  cc5736fe799fd058eb5faeff530be670c9a46e0dbb2610b1879fb9b936d08af8
```

The frozen implementation pins checked by the current build are:

| input | path | SHA-256 |
| --- | --- | --- |
| Objective-C patch | `src/AltServerAnisetteFix.m` | `cc5736fe799fd058eb5faeff530be670c9a46e0dbb2610b1879fb9b936d08af8` |
| Swift client | `src/AnisetteHelper/AnisetteV3Client.swift` | `acdb47708045b57039fd285eee20f4adfedef20b16693ba2e33df55adaab9294` |
| Swift entry point | `src/AnisetteHelper/main.swift` | `3496167c1987c20f64b5bb0b7d85a18c0b5bf03a4c1ff4dba2f4acefde29d196` |
| build script | `scripts/build_release.sh` | `535a162bc70eace0930d6206c3a280bdf220fcb098fb636e0c726242b7bbe592` |
| installer | `scripts/Install.command` | `fceb29d7e6b49f851c65cdcfa60447e681db3c438151d46285e0918345f03b7f` |
| restore | `scripts/Restore.command` | `a74433e8df9d92b9224d04ba78f0d9ec38e8c3f2ea4df4826dcb2454296ddad6` |

These are implementation/source pins, not downloadable release checksums.

The repository contains the local helper/dylib source and upstream references;
it contains no personal signing profile,
credentials, device identifier, or official AltServer.app.

## macOS 27 loader requirement

During development of the v1.0.8 candidate, macOS 27 launch testing exposed a
`dyld` failure: it rejects an injected dylib without a valid nonzero `LC_UUID` with
`OS_REASON_DYLD` / `missing LC_UUID load command`. The default arm64 link now
provides a deterministic nonzero UUID for the injected dylib and helper. The
builder validates the dylib after linking, after signing, and after ZIP
extraction; the helper must also carry a valid UUID. Two clean builds produce
byte-identical payload artifacts. This loader requirement is separate from the
`machineID` fallback behavior and does not change the official GSA/GrandSlam or
User-Agent authentication path.

## Build the deterministic payload

Run the script from the repository root. Create the explicit output parent first;
the builder deliberately does not create an arbitrary parent directory:

```bash
chmod +x scripts/build_release.sh
mkdir -p out
./scripts/build_release.sh \
  /Applications/AltServer.app \
  ./out/v1.0.8
```

Before injection the script checks the input bundle identifier
`com.rileytestut.AltServer`, version `1.7.6`, build `94`, universal main
executable, Developer ID authority, recursive `codesign --verify --deep
--strict`, Gatekeeper assessment, and notarization ticket. It fingerprints the
official main `__TEXT,__text` slice and requires that hash to remain unchanged.
The provenance pins are TeamIdentifier `6XVY5G3U44`, official main executable
SHA-256
`d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819`, and
official archive SHA-256
`ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`.

The script then compiles the helper and compatibility dylib for arm64, strips
debug data and personal path literals, rejects GSA/User-Agent/GrandSlam network
hook strings and symbols, verifies the dylib install name
`@rpath/AltServerAnisetteFix.dylib`, and signs the injected objects ad hoc. The
main AltServer executable and all untouched universal resources are retained;
only the helper and dylib are arm64-only.

The staged app is labeled `1.7.6-macOS27-v3.7`/build `94`, receives the relative
`DYLD_INSERT_LIBRARIES` entry, and is recursively re-signed ad hoc. Developer ID
and notarization from the official input are intentionally not carried forward.
The helper's own provisioning lookup uses
`https://gsa.apple.com/grandslam/GsService2/lookup` and
`User-Agent: akd/1.0 CFNetwork/808.1.4`; the injected dylib does not hook or
modify the official GSA/GrandSlam or User-Agent authentication path.

The builder records the Git revision and worktree state. Documentation-only
changes may be present, but binary-affecting dirty state fails closed unless
`ALTSERVER_ALLOW_DIRTY_ATTESTED_SOURCE=1` is explicitly set. That opt-in marks
the build `dirty-attested`, snapshots the approved sources before compilation,
and verifies the snapshot identities throughout the build. Helper and dylib
`LC_UUID` values are deterministic derivations from their source hashes and
compile inputs; each is checked after linking, signing, and ZIP extraction.

## Output and reproducibility checks

`./out/v1.0.8` contains exactly these four regular files:

```text
AltServer-macOS27-v3.7.zip
AltServer-macOS27-v3.7.executables.txt
BUILD-METADATA.txt
CHECKSUMS-SHA256.txt
```

It contains no raw `AltServer.app`, `Payload/`, IPA, or other release file. The
ZIP is the only app-bearing artifact.

Any pre-existing `out/v1.0.8` is stale until this script completes
successfully. Do not stage or install it; rebuild and use only the newly
verified output.

The ZIP writer uses fixed timestamps and sorted paths, validates relative
symlinks, rejects duplicate/traversal/AppleDouble entries, and records a finite
executable-mode manifest. `BUILD-METADATA.txt` records `ReleaseVersion=1.0.8`,
`PatchVersion=v3.7`, `BaseVersion=1.7.6`, `BaseBuild=94`,
`AltSign=Official-static-only`, `PatchedIPA=Not-included`,
`NetworkHooks=No-GSA-or-User-Agent-hook`, and preservation of the main text
hash.

Verify the generated artifacts without installing them. Extract the ZIP into a
temporary directory; do not expect a raw app in `out/v1.0.8`:

```bash
cd out/v1.0.8
shasum -a 256 \
  AltServer-macOS27-v3.7.zip \
  AltServer-macOS27-v3.7.executables.txt \
  BUILD-METADATA.txt \
  CHECKSUMS-SHA256.txt
verify_dir="$(mktemp -d)"
trap 'rm -rf "$verify_dir"' EXIT
unzip -q AltServer-macOS27-v3.7.zip -d "$verify_dir"
codesign --verify --deep --strict "$verify_dir/AltServer.app"
lipo -archs "$verify_dir/AltServer.app/Contents/MacOS/AltServer"
grep -E '^(ReleaseVersion|PatchVersion|BaseVersion|BaseBuild|PatchedIPA|NetworkHooks)=' \
  BUILD-METADATA.txt
```

Expected architecture output includes both `arm64` and `x86_64` for the main
executable. The helper and dylib must each report only `arm64`; do not run the
payload through Rosetta.

## Installer, restore, and dry run

The installer validates the payload ZIP, manifest, metadata, checksums, bundle
metadata, architecture, symlinks, and recursive signature before changing
`/Applications/AltServer.app`. To use the local four-file output, stage it under
`scripts/Payload/` (or use an equivalent flat installer layout), then run these
commands from the repository root:

```bash
mkdir -p scripts/Payload
cp out/v1.0.8/* scripts/Payload/
# Non-root validation only; do not prefix the dry run with sudo.
ALTSERVER_INSTALL_DRY_RUN=1 ./scripts/Install.command
# Actual installation is root-only and requires a valid non-root SUDO_USER.
sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Install.command
```

When an existing official app is present it is copied to an atomic UTC backup
record under:

```text
~/Library/Application Support/AltServer-macOS27-Fix/Backups/AltServer-<UTC>.<pid>.<rand>.backup/
├── AltServer.app
└── metadata
```

It then replaces the exact app path and verifies the installed result. To check
the release without changing `/Applications` or Application Support:

```bash
ALTSERVER_INSTALL_DRY_RUN=1 ./scripts/Install.command
```

For a real install, run `sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Install.command`.
Actual install and restore are root-only; the
non-root dry-run is the validation path. Install resolves the canonical home of
the valid non-root `SUDO_USER` and writes backups only under that user's
canonical backup root. Backup-root overrides fail closed for production/root
transactions and for unsafe or non-canonical paths; the sole override exception
is a canonical private `0700`, owner-owned
`$HOME/.altserver-install-*/Backups` fixture used only for non-root dry-run
validation. Unsupported target/path overrides also fail closed. To recover the
official app, run
`sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Restore.command`; it selects the
newest verified new record and also accepts a verified path argument:

```bash
sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Restore.command \
  "$HOME/Library/Application Support/AltServer-macOS27-Fix/Backups/AltServer-<UTC>.<pid>.<rand>.backup"
```

Restore also validates legacy `AltServer-<UTC>.<pid>.<rand>.app` records with
adjacent `.metadata` files, performs the same strict signature and Gatekeeper
checks, and leaves the backup available after a restore. Install and restore
serialize their root transaction with the same lock and route copy, rename,
remove, and recovery operations through descriptor-bound parent/device/inode
checks. Both scripts terminate only a process whose executable path exactly
equals `/Applications/AltServer.app/Contents/MacOS/AltServer`: they send
`TERM`, wait, then send `KILL` only if that exact path remains.

After temporary ZIP extraction and its manifest, ZIP shape, executable-mode, and
recursive-signature checks, the installer checks exactly one valid nonzero
`LC_UUID` on the injected dylib. This check occurs before dry-run success and
before any write to `/Applications` or Application Support; temporary
extraction and validation writes are expected. A missing, zero, malformed, or
duplicate UUID makes the payload non-installable on macOS 27.

Both scripts require a native Apple Silicon process and reject Rosetta. Neither
script installs a patched iPhone IPA or changes the official AltStore on-device
transport.

## Signing and privacy boundary

The official 1.7.6 app is verified before any file is copied. Injection removes
the original nested signatures and applies ad-hoc signatures to the staged
payload; the result must not be described as Developer ID signed or notarized.
The repository carries only local patch source plus upstream references and
checksums. It contains no provisioning profile,
account credential, personal certificate, or device identity. See [UPSTREAM_SOURCE.md](UPSTREAM_SOURCE.md)
for the immutable upstream references and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
for license/provenance notices.

At runtime, a complete coherent official AOSKit dictionary with a nonempty
alias pair passes through after canonicalization. The helper is used only for a
non-dictionary, missing/empty, partial/incomplete, or conflicting alias
response. macOS 27 is the tested/supported target, not a code-level OS gate.

The helper process is accepted only when its runtime SHA-256 and strict
Security signature validation match the embedded payload. The dylib copies the
validated helper into an owner-private immutable temporary directory, then
`fork`/`execve`s that copy. Standard output and error are capped at 1 MiB each
(2 MiB total), and the child has a 15-second deadline; excess output, timeout,
or cleanup/identity failure rejects the fallback. Helper HTTP uses HTTPS and
the provisioning socket uses WSS; redirects stay on the same secure scheme,
host, and effective port, and HTTP responses/WebSocket messages are capped at
1 MiB.
