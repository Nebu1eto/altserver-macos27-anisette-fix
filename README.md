# AltServer macOS 27 Anisette Fix

[English](README.md) | [한국어](README.ko.md)

An unofficial compatibility build for the official AltServer 1.7.6 (build 94)
on macOS 27 when app installation fails with:

```text
AltServer could not retrieve anisette data value "machineID".
```

## Release candidate and local artifacts (2026-09-14)

v1.0.8/v3.7 is the prepared release candidate based on the official AltServer
1.7.6 (build 94). GitHub publication is pending; do not treat this repository
as claiming an already-published installer asset, source archive, `latest`
release, or `SHA256SUMS.txt` download. Build the payload locally; `out/v1.0.8`
then contains exactly these four regular files and no raw app bundle or
`Payload/` directory:

```text
AltServer-macOS27-v3.7.zip
AltServer-macOS27-v3.7.executables.txt
BUILD-METADATA.txt
CHECKSUMS-SHA256.txt
```

The ZIP is the only file that contains the patched app, and is extracted to a
temporary directory for verification and installation.

Maintainer testing on the current macOS 27/iOS 27 environment covered
installation, sideload, and refresh. Independent exact-match validation remains
limited; verify the candidate's hashes and release metadata before use.

Any `out/v1.0.8` directory already present before a fresh successful build is
stale packaging from an earlier implementation. Do not stage or install those
files; run the current build first and use only its newly verified four-file
output.

### macOS 27 launch integrity

During development of the v1.0.8 candidate, macOS 27 `dyld` rejected the injected
dylib when it had no valid nonzero `LC_UUID`, reporting `OS_REASON_DYLD` and
`missing LC_UUID load command`. This is a launch-time loader requirement, not a
change to `machineID` behavior or the GSA authentication path. The builder's
default arm64 link now includes a deterministic nonzero `LC_UUID` and validates
it after linking, after signing, and again after ZIP extraction. The arm64
helper is also required to carry a valid UUID. Two clean builds produce
byte-identical payload artifacts.

## Compatibility

- Apple Silicon Macs (`arm64`)
- macOS 27 is the tested and supported target (native arm64; Rosetta is not
  supported). The source does not enforce an OS-version gate; other versions
  are unsupported and unverified.
- Based on the official AltServer 1.7.6, build 94
- The main AltServer executable remains universal (`arm64` + `x86_64`); the
  injected helper and dylib are arm64-only

This project was tested on macOS 27.0 build `26A5353q`.

## Upstream status (2026-09-12)

The official [Sparkle update feed](https://altstore.io/altserver/sparkle-macos.xml)
lists AltServer 1.7.6/build 94 (published 2026-09-10) with the HTTP 503 sign-in
fix. That release also carries the modern AuthKit client information and the
official AltXPC fallback. Nevertheless, [AltStore issue #1751](https://github.com/altstoreio/AltStore/issues/1751)
is still open and has a 1.7.6 report for the macOS 27 `machineID` error. The
unofficial v3.7 layer therefore supplements, rather than replaces, the
official path.

The public AltStore Classic 2.2.2 on-device transport is a separate component.
This candidate contains no patched iPhone IPA or `AltSign-Dynamic`; a future
on-device refresh failure may require an official AltStore 2.3/update. The
statements above are release and issue facts; the last sentence is a
compatibility boundary, not a claim that the on-device path is fully fixed.

Related upstream context: [PR #1770](https://github.com/altstoreio/AltStore/pull/1770)
is an experimental, unmerged macOS 26+ anisette fallback. As of 2026-09-12,
[PR #1790](https://github.com/altstoreio/AltStore/pull/1790) is closed and
unmerged; [commit `c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)
is the PR-head commit context only, not an upstream dependency. The
official 1.7.6 Sparkle release separately carries the HTTP 503 sign-in fix.
AltSign PR #54 is separate historical context and is not a component of this
local payload.

## Local installation

After building, stage the four output files where the repository installer can
find them (the installer accepts a flat layout or `scripts/Payload/`):

```bash
mkdir -p scripts/Payload
cp out/v1.0.8/* scripts/Payload/
# Non-root validation only; do not prefix the dry run with sudo.
ALTSERVER_INSTALL_DRY_RUN=1 ./scripts/Install.command
# Actual installation is root-only and must retain a valid non-root SUDO_USER.
sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Install.command
```

The installer first extracts the ZIP into a temporary directory, verifies the
ZIP, manifest, metadata, checksums, bundle metadata, architecture, symlinks,
executable modes, and recursive signature, then checks that the injected dylib
has exactly one valid nonzero `LC_UUID`. This check occurs before dry-run
success and before any write to `/Applications` or Application Support;
temporary extraction and validation writes are expected. Use AltServer's normal official **Install AltStore…** flow for a missing
AltStore installation, or open AltStore on the iPhone and use **Refresh All**
when it is already installed. No custom IPA is included or required.

### If macOS Blocks `Install.command`

Gatekeeper may block the script because this unofficial candidate build is not
notarized by Apple. After attempting to open `scripts/Install.command`:

1. Open **System Settings**.
2. Select **Privacy & Security** and scroll down to **Security**.
3. Find the message about `Install.command` and click **Open Anyway**.
4. Confirm by clicking **Open**, then enter your Mac login password if asked.

The **Open Anyway** button is available for about one hour after the blocked
open attempt. This adds an exception for this script; do not disable
Gatekeeper or SIP globally. See
[Apple's official instructions](https://support.apple.com/en-us/102445) for
more information.

If AltStore is already installed on the iPhone, **do not reinstall it**.
Installing the patched AltServer on the Mac is enough. In AltStore, open
**My Apps** and use **Refresh All**, or refresh the affected app individually.
Reinstall AltStore only if it is missing or no longer opens.

The installer verifies the existing official AltServer before replacing it and
atomically publishes a backup record under
`~/Library/Application Support/AltServer-macOS27-Fix/Backups/` with this shape:

```text
Backups/AltServer-<UTC>.<pid>.<rand>.backup/{AltServer.app,metadata}
```

`metadata` records the official build and executable hash. `Restore.command`
selects the newest verified new record and also accepts a verified path argument
for either that record or a legacy `AltServer-<UTC>.<pid>.<rand>.app` plus its
adjacent `.metadata` file:

```bash
sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Restore.command \
  "$HOME/Library/Application Support/AltServer-macOS27-Fix/Backups/AltServer-<UTC>.<pid>.<rand>.backup"
```

Restore keeps the backup after success. Install and restore terminate only a
process whose exact executable path is
`/Applications/AltServer.app/Contents/MacOS/AltServer`; they send `TERM`, wait
for exit, and send `KILL` only if that same path remains. To validate a local
payload without changing `/Applications` or Application Support, run the
non-root dry run `ALTSERVER_INSTALL_DRY_RUN=1 ./scripts/Install.command` (or
the corresponding non-root dry run of `Restore.command`). Actual Install and
Restore reject non-root execution. Install resolves the canonical home of a
valid non-root `SUDO_USER` and uses that user's canonical backup root. Backup-
root overrides fail closed for production/root transactions and for unsafe or
non-canonical paths; the sole override exception is a canonical private `0700`,
owner-owned `$HOME/.altserver-install-*/Backups` fixture used only for non-root
dry-run validation. Unsupported target/path overrides also fail closed. Both
transactions use the shared root lock and descriptor-bound identity checks.

## Apple Account Verification

During an installation or refresh, a trusted Apple device may show an
**Apple Account Sign-In Requested** alert. If it appears immediately after
you started the operation in AltStore:

1. Check that the displayed Apple Account is yours.
2. Tap **Allow**.
3. Enter the displayed six-digit verification code only in the prompt shown
   by AltStore or AltServer.

This is part of AltServer's normal Apple Account authentication flow, not an
extra sign-in introduced by this compatibility fix. The compatibility helper
does not receive or send the verification code to the anisette V3 server.

If you did not initiate an installation or refresh, tap **Don't Allow**.
Never share the verification code, screenshots containing it, or anisette
headers in a GitHub issue, chat, or support request. The approximate location
shown in Apple's alert is IP-based and may differ from your physical
location.

## What It Does

Official AltServer 1.7.6 (build 94) includes the HTTP 503/modern AuthKit
handling and official AltXPC fallback. It still asks the private macOS `AOSKit`
framework for anisette headers. On macOS 27, that call can return error `-45070`
and an empty dictionary, so AltServer cannot obtain `X-Apple-MD-M`
(`machineID`), as tracked by issue #1751. This local helper and dylib handle
that remaining case.

This project:

1. Loads a small arm64 compatibility library from inside the AltServer app
   bundle.
2. Calls the official `AOSUtilities.retrieveOTPHeadersForDSID:` implementation
   first and accepts a complete, coherent, nonempty pair of either the official
   aliases (`X-Apple-MD-M`/`X-Apple-MD`) or the prefixed aliases
   (`X-Apple-I-MD-M`/`X-Apple-I-MD`). Accepted values pass through after
   canonicalization to both key forms.
3. Only a non-dictionary, missing/empty, partial/incomplete, or conflicting
   alias response invokes the Foundation-based helper implementing the public
   anisette V3 protocol; helper headers are then canonicalized to the same
   aliases.
4. Hooks `ALTAnisetteData` description methods only after exact Objective-C ABI
   checks, preserving unrelated arguments and nonlegacy descriptions.

The helper uses the upstream GSA lookup endpoint
`https://gsa.apple.com/grandslam/GsService2/lookup` with
`User-Agent: akd/1.0 CFNetwork/808.1.4` during its own provisioning flow. The
patched dylib does not hook or modify the official GSA/GrandSlam or User-Agent
authentication path; the official AltServer 1.7.6/AltSign transport remains
responsible for that path. The helper is a narrowly scoped fallback for an
incomplete official AOSKit response.

The rest of AltServer's signing, installation, and device communication logic
is unchanged.

See [TECHNICAL_DETAILS.md](TECHNICAL_DETAILS.md) for the full implementation
overview.

## Privacy

The compatibility helper does **not** send your Apple Account email,
password, session cookies, or two-factor authentication codes to the
anisette server. AltStore and AltServer still communicate with Apple as part
of their normal account authentication and app-signing flow.

It connects to:

- `https://gsa.apple.com/grandslam/GsService2/lookup` for the helper's Apple
  provisioning lookup
- `https://ani.sidestore.zip` for the V3 `provisioning_session` and `get_headers`
  paths

A personalized V3 device identity is stored locally at:

```text
~/Library/Application Support/AltServer/RemoteAnisetteUser.json
```

The file is created with permission mode `0600`. It is not included in release
archives and should not be shared.

Read [SECURITY.md](SECURITY.md) before using a public anisette server.

The helper's GSA lookup request is the endpoint and User-Agent shown above; it
does not receive Apple Account credentials. The injected dylib never rewrites
that request or the official GrandSlam authentication exchange.

## Build From Source

Requirements:

- Apple Silicon Mac
- macOS 27 Command Line Tools (native arm64, not Rosetta)
- `/Applications/AltServer.app` from the official 1.7.6 release (build 94)

```bash
chmod +x scripts/build_release.sh
mkdir -p out
./scripts/build_release.sh /Applications/AltServer.app ./out/v1.0.8
```

Do not use an existing `out/v1.0.8` from before this build: it is stale until
the current script completes successfully. Only the freshly generated,
verified four-file output is installable.

The script verifies the official bundle identifier, version/build, universal
main executable, Developer ID signature, Gatekeeper assessment, notarization
ticket, and the frozen v3.7 source SHA
`cc5736fe799fd058eb5faeff530be670c9a46e0dbb2610b1879fb9b936d08af8` before
injection. The output directory contains exactly four regular files; the ZIP
is extracted to a temporary directory for app verification. The output is
intentionally ad-hoc signed and is not Developer ID signed or notarized. See
[BUILDING.md](BUILDING.md) for all frozen source/script pins, the dirty-source
attestation rule, and the exact checks and artifacts.

The build's deterministic UUID and ZIP checks are launch-integrity checks only;
they do not change the `machineID` fallback decision or the official GSA/
GrandSlam authentication path.

Provenance pins for the official input are TeamIdentifier `6XVY5G3U44`, main
executable SHA-256
`d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819`, and
official archive SHA-256
`ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`. The
input must pass Developer ID signature, recursive strict verification,
Gatekeeper assessment, and notarization-ticket validation before injection.

## Verification

The prepared v1.0.8/v3.7 candidate is checked from the four files in
`out/v1.0.8` and from a temporary extraction of its ZIP. It is tested for:

- recursive code-signature validation
- clean first-time V3 provisioning
- reuse of the same personalized V3 identity
- restoration of the original AltServer
- reinstallation of the patched AltServer
- deterministic v3.7 payload ZIP, executable manifest, metadata, and checksums
- absence of IPA, dynamic AltSign, provisioning profiles, and personal build
  paths
- absence of local usernames, personal certificates, and identity files

## Limitations

- This is an unofficial, non-notarized release candidate.
- The helper and injected dylib are `arm64` only; the universal main app is
  retained, but Rosetta execution is rejected.
- AltServer updates may overwrite the compatibility build.
- macOS beta updates may change private framework behavior again.
- Availability depends on the configured anisette V3 server.
- Official AltServer 1.7.6 fixes the reported HTTP 503 path, but issue #1751
  confirms that the macOS 27 `machineID` path can still fail on 1.7.6.
- Apple or the configured anisette V3 server may still
  return an HTML `503`, an `apptokens` service failure, or another HTTP
  401/503 response.
- This candidate contains no patched iPhone IPA or dynamic AltSign. The public
  AltStore 2.2.2 on-device transport is separate and may need an official 2.3
  or later update for future refresh failures.
- The local patch addresses only the missing macOS 27 AOSKit `machineID` case;
  it does not guarantee that Apple, anisette, or on-device service failures are
  resolved.

## Credits

- [AltStore](https://github.com/altstoreio/AltStore)
- [SideStore RemoteAnisette](https://github.com/SideStore/RemoteAnisette),
  used as a protocol reference
- [anisette-v3-server](https://github.com/Dadoum/anisette-v3-server),
  used as a protocol reference

No RemoteAnisette source file is redistributed in this repository.

## License

This project and the modified AltServer distribution are provided under the
[GNU Affero General Public License v3.0](LICENSE).

This repository is not affiliated with or endorsed by AltStore, SideStore, or
Apple.
