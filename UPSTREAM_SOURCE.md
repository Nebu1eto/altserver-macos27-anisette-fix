# Upstream Source

This repository contains the local v3.7 helper/dylib patch source, upstream
references, and reproducibility checksums. The prepared v1.0.8/v3.7 release
candidate is based on official AltServer 1.7.6/build 94; GitHub publication is
pending. The repository does not redistribute the official AltServer.app, an
official binary as source, provisioning profiles, Apple credentials,
certificates, or device identities. Obtain the official input independently and
verify it before building.

## Verified official input (2026-09-12)

- Product: AltServer 1.7.6, build 94
- Sparkle feed: <https://altstore.io/altserver/sparkle-macos.xml>
- Official archive: <https://cdn.altstore.io/file/altstore/altserver/1_7_6.zip>
- Archive SHA-256:
  `ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`
- Bundle identifier: `com.rileytestut.AltServer`
- Main executable: universal `arm64` + `x86_64`
- TeamIdentifier: `6XVY5G3U44`
- Main executable SHA-256:
  `d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819`
- Input attestation: Developer ID signature, recursive strict verification,
  Gatekeeper assessment, and notarization ticket are required by
  `scripts/build_release.sh`.

The official 1.7.6 Sparkle release separately includes HTTP 503/modern AuthKit
handling and the AltXPC fallback, but [AltStore issue #1751](https://github.com/altstoreio/AltStore/issues/1751)
remains open with a 1.7.6 macOS 27 `machineID` failure report. This is why the
local v3.7 fallback exists; it does not claim that upstream machineID behavior
is fixed.

## Upstream references

These are primary references for provenance and compatibility context, not
additional code injected by v3.7:

- [AltStore PR #1770](https://github.com/altstoreio/AltStore/pull/1770) —
  experimental, unmerged macOS 26+ anisette fallback.
- [AltStore PR #1790](https://github.com/altstoreio/AltStore/pull/1790) —
  closed and unmerged as of 2026-09-12. Commit
  [`c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)
  is retained as PR-head context only, not as an upstream dependency.
- [AltSign PR #54](https://github.com/rileytestut/AltSign/pull/54) and commit
  [`e8728ae`](https://github.com/rileytestut/AltSign/commit/e8728aefab36e530f94bd8c29d751ca5d18a235e)
  are historical context for a future official Classic update, not a v1.0.8
  component.

The public official AltStore Classic 2.2.2 on-device transport is separate from
the Mac patch. v1.0.8 contains no patched iPhone IPA or `AltSign-Dynamic`; an
on-device refresh failure may require an official AltStore 2.3/update.

## Local patch provenance

The build gate requires this exact Objective-C source SHA-256:

```text
src/AltServerAnisetteFix.m
cc5736fe799fd058eb5faeff530be670c9a46e0dbb2610b1879fb9b936d08af8
```

The current frozen implementation also pins the following local sources and
transaction scripts:

| input | SHA-256 |
| --- | --- |
| `src/AnisetteHelper/AnisetteV3Client.swift` | `acdb47708045b57039fd285eee20f4adfedef20b16693ba2e33df55adaab9294` |
| `src/AnisetteHelper/main.swift` | `3496167c1987c20f64b5bb0b7d85a18c0b5bf03a4c1ff4dba2f4acefde29d196` |
| `scripts/build_release.sh` | `535a162bc70eace0930d6206c3a280bdf220fcb098fb636e0c726242b7bbe592` |
| `scripts/Install.command` | `fceb29d7e6b49f851c65cdcfa60447e681db3c438151d46285e0918345f03b7f` |
| `scripts/Restore.command` | `a74433e8df9d92b9224d04ba78f0d9ec38e8c3f2ea4df4826dcb2454296ddad6` |

These are implementation/source pins, not downloadable release checksums.

v3.7 calls the official AOSKit method first, passes through/canonicalizes only a
complete coherent nonempty alias pair, and invokes the arm64 helper only for a
non-dictionary, missing/empty, partial/incomplete, or conflicting alias
response. The helper's own provisioning lookup uses the upstream GSA endpoint
`https://gsa.apple.com/grandslam/GsService2/lookup` with
`User-Agent: akd/1.0 CFNetwork/808.1.4`. The patched dylib contains no GSA,
User-Agent, or AltSign hook and does not alter the official GSA/GrandSlam
authentication path. The helper and dylib are local source; the main AltServer
executable is not rewritten and remains universal.

During development of the v1.0.8 candidate, macOS 27 testing also exposed a
loader requirement:
`dyld` rejects an injected dylib without a valid nonzero `LC_UUID`, reporting
`OS_REASON_DYLD` / `missing LC_UUID load command`. The default arm64 link now
includes a deterministic nonzero UUID; the build validates it after linking,
after signing, and after ZIP extraction, while the helper carries a valid UUID
as well. After temporary ZIP extraction and manifest/shape/mode/signature
validation, the installer checks exactly one valid nonzero UUID on the injected
dylib before dry-run success and before any write to `/Applications` or
Application Support; temporary extraction and validation writes are expected.
Two clean builds are byte-identical. This does not change
the `machineID` fallback or the official GSA/GrandSlam authentication path.

## Reproduce the payload

Place the independently obtained, unmodified official app at
`/Applications/AltServer.app`, then run:

```bash
chmod +x scripts/build_release.sh
mkdir -p out
./scripts/build_release.sh /Applications/AltServer.app ./out/v1.0.8
```

Do not use a pre-existing `out/v1.0.8`: until the current script completes
successfully, that directory is stale packaging from an earlier implementation.
Use only the newly generated and verified four-file output.

The script rejects stale/patched inputs, checks the official signature and
notarization before injection, strips and signs only the arm64 helper/dylib
ad hoc, preserves the main executable's text hash, and writes exactly four
regular files under `out/v1.0.8`: the payload ZIP, executable manifest,
metadata, and checksums. The ZIP is extracted into a temporary directory for
verification; the output contains no raw app or `Payload/` directory. It never builds
or packages an iPhone IPA.

The injected output is ad hoc signed and is not Developer ID signed or
notarized. The original official app is retained by the installer as an atomic
UTC-timestamped record
`Backups/AltServer-<UTC>.<pid>.<rand>.backup/{AltServer.app,metadata}` and can
be restored with `sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Restore.command`.
Actual Install and Restore are root-only; non-root dry-runs are read-only.
Install requires a valid non-root `SUDO_USER` and uses that user's canonical
backup root. Backup-root overrides fail closed for production/root transactions
and for unsafe or non-canonical paths; the sole override exception is a
canonical private `0700`, owner-owned
`$HOME/.altserver-install-*/Backups` fixture used only for non-root dry-run
validation. Unsupported target/path overrides also fail closed.
Restore also validates legacy `.app` plus adjacent `.metadata` records and
accepts an optional verified backup path argument. Install/restore share a root
lock and route copy, rename, remove, and recovery operations through
descriptor-bound identity checks. Both terminate only the exact executable
path `/Applications/AltServer.app/Contents/MacOS/AltServer`.
