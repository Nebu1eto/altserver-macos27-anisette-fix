# Third-Party Notices

v1.0.8 / v3.7 is source-only and follows v1.0.2. This repository publishes
source, scripts, references, and documentation only. It redistributes none of
the third-party binaries listed below: no official `AltServer.app`, installer
archive, app-bearing payload ZIP, IPA, provisioning profile, certificate, or
system framework is included in the publication. A local build links against
the tools and frameworks already installed on the builder's Mac.

The license descriptions below are notices for review, not legal advice or a
claim of legal certainty. Check each upstream repository's current `LICENSE`
and terms before redistribution.

## Dependencies and references

| Component | Version or revision used | Role | License notice | Source |
| --- | --- | --- | --- | --- |
| AltStore / AltServer | 1.7.6, build 94 (official archive; exact public Git commit mapping is not proven) | Unmodified local build input and runtime base | AltStore repository declares GNU AGPL v3.0; verify upstream terms | <https://github.com/altstoreio/AltStore> |
| SideStore RemoteAnisette | Protocol reference; no vendored revision | V3 interoperability reference | See upstream `LICENSE`; no license conclusion is made here | <https://github.com/SideStore/RemoteAnisette> |
| anisette-v3-server | Protocol reference; no vendored revision | V3 interoperability reference | See upstream `LICENSE`; no license conclusion is made here | <https://github.com/Dadoum/anisette-v3-server> |
| SideStore anisette servers | Service directory reference | Default endpoint context (`ani.sidestore.zip`) | Service terms and operator policy apply; not a bundled dependency | <https://github.com/SideStore/anisette-servers> |
| Apple Foundation | macOS 27 SDK supplied by host | URLSession, JSON, plist, file and process APIs | Apple SDK and macOS terms | <https://developer.apple.com/documentation/foundation> |
| Apple CryptoKit | macOS 27 SDK supplied by host | SHA-256 for local identifier derivation | Apple SDK and macOS terms | <https://developer.apple.com/documentation/cryptokit> |
| Apple Security / Objective-C runtime / AOSKit | macOS 27 system frameworks supplied by host | Signature checks and AOSKit/ABI integration | Apple system software terms; AOSKit is private | <https://developer.apple.com/documentation/security> |
| Swift compiler and Xcode Command Line Tools | Host-provided; not pinned by this source publication | Compile the Swift helper | Apple toolchain terms | <https://developer.apple.com/xcode/resources/> |
| Python standard library | Host-provided Python 3 (`hashlib`, `os`, `pathlib`, `stat`, `zipfile`) | Deterministic archive, manifest, and checksum checks | Python Software Foundation License | <https://docs.python.org/3/license.html> |
| macOS command-line utilities | Host macOS 27 (`codesign`, `spctl`, `stapler`, `xcrun`, `lipo`, `ditto`, `unzip`, `shasum`, and POSIX tools) | Build/install validation and transactions | Apple/macOS terms and each utility's system license | <https://support.apple.com/macos> |

The official archive is obtained separately from
`https://cdn.altstore.io/file/altstore/altserver/1_7_6.zip` and verified with
SHA-256
`ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`. The local
build verifies the official TeamIdentifier `6XVY5G3U44` and main executable
SHA-256
`d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819` before
injection. These checks do not grant permission to redistribute Apple's app or
other third-party binaries.

## Upstream context links

- [AltStore PR #1770](https://github.com/altstoreio/AltStore/pull/1770) is
  experimental and unmerged macOS 26+ anisette fallback context.
- [AltStore PR #1790](https://github.com/altstoreio/AltStore/pull/1790) is closed
  and unmerged; [`c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)
  is PR-head context only, not a dependency.
- [AltSign PR #54](https://github.com/rileytestut/AltSign/pull/54) is separate
  historical context. No `AltSign-Dynamic` framework is bundled or published.

The helper's own provisioning lookup uses
`https://gsa.apple.com/grandslam/GsService2/lookup` and
`User-Agent: akd/1.0 CFNetwork/808.1.4`. This is not a GSA/User-Agent hook in
the dylib; the official AltServer/AltSign transport retains ownership of the
official GrandSlam authentication path.

## Local source license

The patch source and scripts in this repository are offered under the
[GNU AGPL v3.0](LICENSE). This notice does not relicense AltStore, Apple
software, protocol references, or any service. The project is independent and
not affiliated with or endorsed by AltStore, SideStore, or Apple.
