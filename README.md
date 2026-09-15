# AltServer macOS 27 Anisette Fix

[English](README.md) | [한국어](README.ko.md)

An unofficial, source-only compatibility project for the official AltServer
1.7.6 (build 94) on macOS 27 when installation reports:

```text
AltServer could not retrieve anisette data value "machineID".
```

## Publication scope

v1.0.8 / v3.7 is a source-only publication and follows v1.0.2. The GitHub
repository publishes this source, the build and transaction scripts, and the
documentation. It publishes no modified `AltServer.app`, installer archive,
app-bearing payload ZIP, IPA, provisioning profile, certificate, or other
binary asset. Obtain the official AltServer input yourself and build locally.

The current build script writes four private verification artifacts to
`out/v1.0.8`:

```text
AltServer-macOS27-v3.7.zip
AltServer-macOS27-v3.7.executables.txt
BUILD-METADATA.txt
CHECKSUMS-SHA256.txt
```

Those files are local build output, not repository release assets. The ZIP is
the only one that contains a modified app; it must be treated as a temporary,
locally verified artifact. A pre-existing output directory is stale until the
current build succeeds.

Maintainer testing on the current macOS 27/iOS 27 environment covered install,
sideload, and refresh. Independent exact-match validation is limited; compare
the official input hash and the generated metadata before use.

## Compatibility

- Apple Silicon Mac, native `arm64` process (Rosetta is rejected).
- macOS 27 is the tested and supported target. Other macOS versions are
  unsupported and unverified; the source does not enforce an OS-version gate.
- Official AltServer 1.7.6, build 94.
- The untouched main executable remains universal (`arm64` + `x86_64`); the
  injected helper and dylib are `arm64` only.

Testing was performed on macOS 27.0 build `26A5353q`.

An official AltServer update can overwrite the locally installed compatibility
build. Keep the official build or repeat the verified local build if macOS 27
still needs this fix; do not mix payload versions.

## Upstream context

The [official Sparkle feed](https://altstore.io/altserver/sparkle-macos.xml)
lists AltServer 1.7.6/build 94 (published 2026-09-10), including the reported
HTTP 503 sign-in handling, modern AuthKit client information, and the official
AltXPC fallback. [AltStore issue #1751](https://github.com/altstoreio/AltStore/issues/1751)
still records a macOS 27 `machineID` failure on 1.7.6, which is the narrow case
addressed here.

The public AltStore Classic 2.2.2 on-device transport is separate. This project
does not include a patched iPhone IPA or `AltSign-Dynamic`; future refresh
failures may require an official AltStore update.

[AltStore PR #1770](https://github.com/altstoreio/AltStore/pull/1770) is
experimental, unmerged macOS 26+ anisette fallback context. [PR #1790](https://github.com/altstoreio/AltStore/pull/1790)
is closed and unmerged; [commit `c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)
is PR-head context only, not an upstream dependency. An exact public Git commit
mapping official 1.7.6/build 94 to the downloaded archive cannot be proven from
the available evidence; the feed, archive/version/build, and hash are the
authoritative checks used here.

## Build and install locally

Start with the [building guide](BUILDING.md). In brief, download the official
archive from the version-pinned URL below, verify its SHA-256, extract it, and
use the unmodified `AltServer.app` as the build input:

```text
https://cdn.altstore.io/file/altstore/altserver/1_7_6.zip
SHA-256  ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9
```

From the repository root, build into the explicit output directory:

```bash
mkdir -p out
./scripts/build_release.sh "/path/to/official/AltServer.app" "$PWD/out/v1.0.8"
```

The script validates official bundle metadata, Developer ID/notarization
provenance, the universal main executable, pinned source hashes, deterministic
UUIDs, and the ZIP before publishing the four local files. It never creates an
iPhone IPA or a provisioning profile.

The current `scripts/Install.command` expects either a flat layout or a
`Payload/` layout. Use a private staging directory containing the script and
exactly the four output files under `Payload/`:

```bash
stage_dir="$(mktemp -d)"
cp scripts/Install.command scripts/Restore.command "$stage_dir/"
mkdir "$stage_dir/Payload"
cp out/v1.0.8/AltServer-macOS27-v3.7.zip \
   out/v1.0.8/AltServer-macOS27-v3.7.executables.txt \
   out/v1.0.8/BUILD-METADATA.txt \
   out/v1.0.8/CHECKSUMS-SHA256.txt "$stage_dir/Payload/"
chmod +x "$stage_dir/Install.command" "$stage_dir/Restore.command"

# Read-only validation as the invoking user; do not add sudo here.
(cd "$stage_dir" && ALTSERVER_INSTALL_DRY_RUN=1 ./Install.command)

# Actual replacement of /Applications/AltServer.app is root-only.
(cd "$stage_dir" && sudo ./Install.command)
```

The installer extracts the payload into a private temporary directory and
checks ZIP shape, manifest, metadata, checksums, bundle metadata, architecture,
symlinks, executable modes, recursive signature, and exactly one valid nonzero
`LC_UUID` on both injected objects. These checks finish before dry-run success
and before writes to `/Applications` or Application Support. Temporary
extraction and validation writes are expected.

If an existing official app is present, the installer stores a verified backup
at:

```text
~/Library/Application Support/AltServer-macOS27-Fix/Backups/
└── AltServer-<UTC>.<pid>.<rand>.backup/
    ├── AltServer.app
    └── metadata
```

For restoration, use the staged `Restore.command` with `sudo` (the same
non-root dry-run convention applies):

```bash
(cd "$stage_dir" && sudo ./Restore.command)
```

Restore selects the newest verified backup and accepts a verified backup path
argument. It also recognizes legacy `.app` plus adjacent `.metadata` records.
Backups remain after a successful restore. Install and Restore operate only on
the exact target `/Applications/AltServer.app` and terminate only a process
whose executable path is
`/Applications/AltServer.app/Contents/MacOS/AltServer`.

For a missing AltStore installation, use AltServer's official **Install
AltStore…** flow. If AltStore is already installed, use **My Apps > Refresh
All**; do not reinstall it solely because the Mac helper was installed. This
repository supplies no custom IPA.

## Apple Account verification

Apple's normal flow may show an **Apple Account Sign-In Requested** alert and a
six-digit code. Approve it only when you initiated the operation and the
displayed account is yours. Enter the code only in the AltStore or AltServer
prompt. Choose **Don't Allow** for an unsolicited alert. The compatibility
helper never receives or sends the code to the anisette service.

## What changes at runtime

The dylib first calls the official
`AOSUtilities.retrieveOTPHeadersForDSID:` implementation. A complete,
coherent, nonempty pair of either `X-Apple-MD-M`/`X-Apple-MD` or
`X-Apple-I-MD-M`/`X-Apple-I-MD` is canonicalized to both aliases and passed
through. Only a non-dictionary, missing/empty, partial/incomplete, or
conflicting response invokes the Foundation-based arm64 helper and public
anisette V3 protocol. `ALTAnisetteData` description hooks run only after exact
Objective-C ABI checks and preserve unrelated arguments and nonlegacy values.

The helper's provisioning lookup uses
`https://gsa.apple.com/grandslam/GsService2/lookup` with
`User-Agent: akd/1.0 CFNetwork/808.1.4`. The injected dylib has no GSA,
GrandSlam, User-Agent, or AltSign hook and does not rewrite the official
authentication path. The main AltServer code and device transport are left
unchanged.

## Privacy and security

The helper does not receive or send an Apple ID/Apple Account email, password,
session cookie, two-factor code, or authorization header to the anisette service. It
uses a dedicated URLSession configuration with ephemeral storage, cookies
disabled, credential storage disabled, cache disabled, and additional headers
cleared. HTTPS requests and WSS provisioning are limited to the configured
secure origin; redirects must keep scheme, host, and effective port. HTTP and
WebSocket messages are capped at 1 MiB.

The default V3 endpoint is `https://ani.sidestore.zip`. A personalized identity
is stored locally as
`~/Library/Application Support/AltServer/RemoteAnisetteUser.json` with mode
`0600`; it is not published or included in local release output. Use only a
service you trust, or change the source and rebuild for a self-hosted service.
Read [SECURITY.md](SECURITY.md) before using a public endpoint.

The identity is opened relative to an owner-checked private support directory.
The directory is owner-owned and mode `0700`; the identity must be an
owner-owned regular file with exactly mode `0600` and one hard link. A
no-follow, nonblocking open rejects symlinks, FIFOs, and other non-regular entries;
reads are bounded to 64 KiB. New identities use a unique `0600` exclusive
temporary file, `fsync`, and exclusive publication so concurrent runs cannot
replace an existing entry. If an existing identity fails these checks, the
helper rejects it; after review or quarantine, rerunning provisioning may be
required.

Never publish Apple ID/Apple Account credentials, verification codes, anisette
headers, device IDs, local paths, IP/location data, or `RemoteAnisetteUser.json` in an
issue or log. Share only a short redacted error, architecture, macOS version,
AltServer version/build, and failed step.

## Further reading

- [Installation guide](INSTALLATION.md) / [한국어 설치 안내](INSTALLATION.ko.md)
- [BUILDING.md](BUILDING.md) — source pins, reproducibility, and validation
- [TECHNICAL_DETAILS.md](TECHNICAL_DETAILS.md) — implementation boundaries
- [UPSTREAM_SOURCE.md](UPSTREAM_SOURCE.md) — official input provenance
- [SECURITY.md](SECURITY.md) — threat model and data handling
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) — dependency notices
- [CHANGELOG.md](CHANGELOG.md) — source-only release history

## License and status

The local patch source is provided under [GNU AGPL v3.0](LICENSE). AltServer,
Apple frameworks, and protocol reference projects retain their own terms. This
project is unofficial and is not affiliated with or endorsed by AltStore,
SideStore, or Apple.
