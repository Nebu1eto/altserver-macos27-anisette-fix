# Third-Party Notices

## AltStore

- Project: <https://github.com/altstoreio/AltStore>
- Official input: AltServer 1.7.6/build 94
- Update feed: <https://altstore.io/altserver/sparkle-macos.xml>
- License: GNU Affero General Public License v3.0

The v1.0.8/v3.7 payload is injected into an unmodified official AltServer.app
after its Developer ID signature, Gatekeeper assessment, notarization ticket,
and universal `arm64`/`x86_64` executable are verified. The official 1.7.6
Sparkle release separately carries the HTTP 503 sign-in fix; this local payload
does not attribute that fix to an injected GSA hook. The official app is not
redistributed. The repository contains
only local helper/dylib patch source, upstream references, and checksums.

Upstream context, not local code hooks:

- AltStore [PR #1790](https://github.com/altstoreio/AltStore/pull/1790) is closed
  and unmerged as of 2026-09-12. Commit
  [`c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)
  is retained only as PR-head context, not as an upstream dependency.
- AltSign [PR #54](https://github.com/rileytestut/AltSign/pull/54) and commit
  [`e8728ae`](https://github.com/rileytestut/AltSign/commit/e8728aefab36e530f94bd8c29d751ca5d18a235e)
  are separate historical context; they are not bundled as `AltSign-Dynamic`.
- AltStore [PR #1770](https://github.com/altstoreio/AltStore/pull/1770) remains
  an experimental, unmerged macOS 26+ anisette fallback.

The v3.7 dylib does not hook GSA, User-Agent, or AltSign; the official 1.7.6
transport remains responsible for GrandSlam and AltXPC behavior. The main app
is kept universal, while the injected helper and dylib are arm64-only.

The helper's own provisioning lookup uses
`https://gsa.apple.com/grandslam/GsService2/lookup` with
`User-Agent: akd/1.0 CFNetwork/808.1.4`; this does not alter the official
GrandSlam/User-Agent authentication path. Official-input pins are TeamIdentifier
`6XVY5G3U44`, main SHA-256
`d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819`, and
archive SHA-256
`ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`. Developer
ID and notarization are verified before injection; the output is ad hoc signed.

## anisette V3 protocol references

- SideStore RemoteAnisette: <https://github.com/SideStore/RemoteAnisette>
- anisette-v3-server: <https://github.com/Dadoum/anisette-v3-server>
- SideStore server list: <https://github.com/SideStore/anisette-servers>

These projects were used as protocol and interoperability references. No
RemoteAnisette source file is included in this distribution.

## Apple frameworks

Foundation, CryptoKit, Objective-C runtime, AOSKit, and related macOS
components are system libraries supplied by Apple and are not redistributed.
