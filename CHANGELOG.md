# Release Notes

## v1.0.8 / v3.7 (prepared release candidate; publication pending) - 2026-09-14

- Prepares the candidate from the official AltServer 1.7.6/build 94. The official
  release fixes the HTTP 503 sign-in path, includes modern AuthKit client
  information, and provides the AltXPC fallback.
- Builds internal compatibility payload v3.7. It calls the official AOSKit
  anisette path first, passes through/canonicalizes a complete coherent alias
  pair, and invokes the arm64 helper only for a non-dictionary,
  missing/empty, partial/incomplete, or conflicting alias response. The local
  dylib contains no GSA, User-Agent, or AltSign hook.
- Keeps the official universal AltServer executable (`arm64` + `x86_64`) while
  limiting the injected helper and dylib to native Apple Silicon arm64; Rosetta
  execution is rejected.
- Verifies the official Developer ID/notarized input before injection, then
  emits a deterministic ad-hoc-signed payload. The original official app is
  preserved as a UTC-timestamped backup and can be restored.
- Maintainer testing on the current macOS 27/iOS 27 environment covered
  installation, sideload, and refresh; independent exact-match validation
  remains limited.
- Contains no patched iPhone IPA or `AltSign-Dynamic`. The
  standard official **Install AltStore…** flow remains the supported device
  path; public AltStore 2.2.2 on-device transport is separate.
- As of this date, AltStore [issue #1751](https://github.com/altstoreio/AltStore/issues/1751)
  remains open and has a 1.7.6 `machineID` failure report. This candidate does
  not claim that the on-device path is fully solved; a future refresh failure
  may require an official AltStore 2.3/update.
- Upstream context: [PR #1770](https://github.com/altstoreio/AltStore/pull/1770)
  remains experimental/unmerged. As of 2026-09-12, [PR #1790](https://github.com/altstoreio/AltStore/pull/1790)
  is closed and unmerged; [`c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)
  is its PR-head commit context only. The official 1.7.6 Sparkle release
  separately carries the HTTP 503 sign-in fix.
- Official-input pins are TeamIdentifier `6XVY5G3U44`, main SHA-256
  `d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819`, and
  archive SHA-256
  `ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`; the
  input must pass Developer ID and notarization checks before injection.
- GitHub installer/source assets and the `latest` release remain pending
  publication; the candidate's local output is the four-file `out/v1.0.8`
  directory.
- During development of this candidate, macOS 27 `dyld` launch testing found that
  an injected dylib without a valid nonzero `LC_UUID` is rejected with
  `OS_REASON_DYLD` / `missing LC_UUID load command`. The builder now includes a
  default deterministic UUID, validates it post-link, post-sign, and after ZIP
  extraction, and requires the helper to carry a valid UUID. After temporary
  ZIP extraction and manifest, shape, mode, and signature checks, the installer
  checks exactly one valid nonzero UUID on the injected dylib. It performs this
  check before dry-run success and before any write to
  `/Applications` or Application Support; temporary extraction and validation
  writes are expected.
  Two clean builds are byte-identical. This launch-integrity fix does not alter
  the `machineID` fallback decision or the official GSA/GrandSlam path.
- The builder derives helper/dylib `LC_UUID` values deterministically from
  pinned source hashes and compile inputs. Binary-affecting dirty worktrees fail
  closed unless `ALTSERVER_ALLOW_DIRTY_ATTESTED_SOURCE=1` opts into source
  snapshots and a `dirty-attested` metadata record.
- Actual Install and Restore are root-only (`sudo`); dry-runs are non-root and
  read-only. Install requires a valid non-root `SUDO_USER` and its canonical
  backup root. Backup-root overrides fail closed for production/root
  transactions and for unsafe or non-canonical paths; the sole override exception is a
  canonical private `0700`, owner-owned
  `$HOME/.altserver-install-*/Backups` fixture used only for non-root dry-run
  validation. Unsupported target/path overrides also fail closed; both
  transactions use descriptor-bound operations and a shared root lock, while
  Restore accepts both the new backup pair and legacy `.app` plus
  `.metadata` records.
- The helper runtime verifies its SHA-256 and strict Security signature, uses an
  owner-private immutable copy with `fork`/`execve`, caps stdout/stderr at 1 MiB
  each (2 MiB total), and enforces a 15-second timeout. Its HTTPS/WSS client
  permits only same-origin secure redirects and caps HTTP responses and
  WebSocket messages at 1 MiB.
- Existing `out/v1.0.8` contents are stale until a fresh build succeeds; they
  are not release artifacts to stage or install.

The entries below are archive-only historical records, not v1.0.8 operating
instructions. In particular, the v3.6/IPA/Option-click path is not present in
v1.0.8 and must not be followed.

## v1.0.7 / v3.6 (archive-only history; not v1.0.8) - 2026-09-11

- Rebuilds the macOS payload from the closest public AltServer 1.7.5/build-92
  compatibility base (`ad16c74`) with AltSign PR #53 transport and the
  minimal PR #54 verification-session fix.
- Records internal compatibility payload v3.6 while retaining the macOS 27
  AOSKit `machineID`/client-info hooks and disabling the now-duplicate local
  GrandSlam URLSession User-Agent hook.
- Historical notes referred to a generic-device arm64 AltStore IPA and an
  Option-click custom-IPA flow. Those artifacts and that workflow are archive
  history only; v1.0.8 contains neither and this is not operating guidance.

## v1.0.6 (archive-only history; not v1.0.8) - 2026-09-11

- Updates the internal anisette helper to v3.5 while retaining the existing
  macOS 27 `machineID` workaround.
- Adds an exact-ABI `NSURLSession` hook that rewrites only the stale
  `User-Agent` for the exact `gsa.apple.com/grandslam/GsService2` request to
  the tested upstream AltSign #51 value:
  `AuthKit/1 (Macintosh; OS X 26.5.2) (com.apple.dt.Xcode/26.0)`.
- Preserves official AltServer 1.7.5 per-request ephemeral-session and 5xx
  handling. This release does not add GrandSlam retries.

## v1.0.5 (archive-only history; not v1.0.8) - 2026-09-10

- Rebases the distribution on official AltServer 1.7.5, build 92, with
  internal anisette helper v3.4.
- Preserves the official 1.7.5 GrandSlam separate-session and 5xx handling
  fix, which resolves `The data is not in the correct format`.
- Keeps the local helper/dylib workaround for the remaining macOS 27 AOSKit
  response with an empty `machineID`.

## v1.0.4 (archive-only history; not v1.0.8) - 2026-09-05

- Updates the internal anisette helper to v3.3 while keeping
  `X-Mme-Client-Info` dynamic from the current `hw.model`, macOS product
  version/build, and Xcode `25183.54.10`.
- Hooks the `ALTAnisetteData` initializer and `setDeviceDescription:` from the
  injected dylib only after exact Objective-C ABI checks. When AltServer 1.7.2
  re-inserts the legacy Xcode `3594.4.19` device description, the hook replaces
  it with the helper's client info while preserving all other fields and
  nonlegacy descriptions.
- Handles late `AltSign` loading with a guarded one-shot delayed hook retry.
- Adds class/method and malformed helper-JSON/required-header guards so
  unsupported runtime shapes are rejected without changing unrelated methods.
- Clarifies that Apple HTML `503`/`apptokens` service failures are not
  guaranteed to be fixed locally. Error `3840` can be a wrapper around an HTTP
  error body being parsed as a plist.

## v1.0.3 (archive-only history; not v1.0.8) - 2026-09-05

- Updates the internal anisette helper to v3.2 for macOS 27 compatibility.
- Builds `X-Mme-Client-Info` from the current `hw.model`, macOS product
  version/build, and Xcode `25183.54.10` instead of the stale
  MacBookPro13,2/macOS 13.1/22C65/Xcode 3594.4.19 value.
- Refreshes client info in memory for existing identities without
  reprovisioning and prefers the local value over a stale server-returned
  `X-Mme-Client-Info`.
- Keeps the dylib hook path that replaces the empty AOSKit header response on
  macOS 27.
- Notes that `The data is not in the correct format` may reflect an Apple or
  anisette HTTP error response; this does not guarantee that every HTTP
  401/503 or other service outage is fixed locally.

## v1.0.2 (archive-only history; not v1.0.8) - 2026-06-13

- Documents how to allow `Install.command` through Gatekeeper using System
  Settings > Privacy & Security > Open Anyway.
- Links to Apple's official English and Korean instructions.
- Clarifies that users should not disable Gatekeeper or SIP globally.
- Contains no changes to the patched AltServer binary.

## v1.0.1 - 2026-06-13

- Reduces the installer archive from about 81 MB to about 7 MB.
- Distributes the installer and corresponding source as separate assets.
- Removes the bundled original AltServer application from the installer.
- Restores the official AltServer from the local pre-installation backup.
- Avoids creating duplicate backups when the patched build is reinstalled.
- (Archive-only history) Uses one `SHA256SUMS.txt` file for historical
  downloadable release assets; this file is not a v1.0.8 artifact.
- Includes English and Korean documentation directly in the installer.

## v1.0.0 - 2026-06-13

- Works around the missing anisette `machineID` in AltServer 1.7.2 on macOS
  27.
- Creates a personalized identity through the public anisette V3 protocol.
- Reuses the identity and stores it locally with permission mode `0600`.
- Does not send Apple Account credentials to the anisette service.
- Includes double-clickable installation and restoration scripts.
- Includes ad-hoc code signatures and SHA-256 checksums.
- Includes the complete modification source and upstream commit information.
- Uses the recommended `ani.sidestore.zip` V3 endpoint by default.
- Retries transient provisioning and header-generation failures up to three
  times.
- Documents that an existing AltStore installation does not need to be
  reinstalled when refreshing apps.
- Documents Apple's sign-in approval alert and six-digit verification-code
  flow, including anti-phishing guidance.

Tested with:

- macOS 27.0 beta, build `26A5353q`
- Apple Silicon
- AltServer 1.7.2, build 90
