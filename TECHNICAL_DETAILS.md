# Technical Details

## Root cause

Official AltServer 1.7.6 (build 94) provides the HTTP 503/modern AuthKit
handling and the AltXPC fallback. It
still calls the macOS private API:

```objc
[AOSUtilities retrieveOTPHeadersForDSID:@"-2"]
```

On macOS 27 build `26A5353q`, AOSKit logs error `-45070` and returns an
empty dictionary. AltServer then throws a missing value error for
`X-Apple-MD-M`, surfaced as `machineID`. [AltStore issue #1751](https://github.com/altstoreio/AltStore/issues/1751)
remains open and has a 1.7.6 failure report. The local helper and dylib address
this remaining macOS 27 case.

The official 1.7.6 Sparkle release separately carries the HTTP 503 sign-in fix,
modern AuthKit client information, and AltXPC fallback. The v1.0.8 payload is
built from a verified official 1.7.6/build 94 app. The build gate checks the
official bundle ID, universal executable, Developer ID signature, Gatekeeper
assessment, and notarization ticket before injection.
The frozen v3.7 Objective-C source SHA is
`cc5736fe799fd058eb5faeff530be670c9a46e0dbb2610b1879fb9b936d08af8`.

## macOS 27 loader UUID requirement

During development of the v1.0.8 candidate, launch testing found that macOS 27
`dyld` rejects an injected dylib without a valid nonzero `LC_UUID`, reporting
`OS_REASON_DYLD` / `missing LC_UUID load command`. The builder's default arm64
link now includes a deterministic nonzero UUID, checks the dylib after linking
and again after signing, and repeats the check after ZIP extraction. The arm64
helper also carries a valid UUID. Two clean builds produce byte-identical
payload artifacts.

The installer first extracts the ZIP into a temporary directory and performs its
manifest, ZIP shape, executable-mode, and recursive-signature checks. It then
requires exactly one valid nonzero `LC_UUID` on the injected dylib. This check
occurs before dry-run success and before any write to `/Applications` or
Application Support; temporary extraction and validation writes are expected.
This launch-integrity guard is independent of the `machineID` fallback decision
and does not alter the official GSA/GrandSlam or User-Agent authentication path.

Upstream context (not local hooks): [PR #1770](https://github.com/altstoreio/AltStore/pull/1770)
is an experimental, unmerged macOS 26+ anisette fallback. As of 2026-09-12,
[PR #1790](https://github.com/altstoreio/AltStore/pull/1790) is closed and
unmerged; [`c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)
is the PR-head commit context only. Neither is an injected dependency.

## Compatibility layer

`AltServerAnisetteFix.dylib` is loaded from inside the signed app bundle via:

```text
@executable_path/../Frameworks/AltServerAnisetteFix.dylib
```

Its constructor loads AOSKit, locates the class method
`retrieveOTPHeadersForDSID:`, and replaces its implementation with
`method_setImplementation` after an exact type-encoding check.

On macOS 27, the hook first evaluates the official AOSKit response. A complete,
coherent, nonempty pair of official aliases (`X-Apple-MD-M`/`X-Apple-MD`) or
prefixed aliases (`X-Apple-I-MD-M`/`X-Apple-I-MD`) passes through after
canonicalization to both forms. Only a non-dictionary, missing/empty,
partial/incomplete, or conflicting alias response causes the hook to request
helper headers; the rest of AltServer remains unchanged.

The replacement launches `AltServerAnisetteHelper` as a child process and
reads a JSON dictionary from standard output. This process boundary keeps
networking and persistent identity management out of the injected library.

Before launch, the dylib checks the helper's embedded runtime SHA-256 and
Security framework strict signature, opens it without following links, and
copies the validated bytes into an owner-private immutable temporary directory.
It then `fork`/`execve`s that private copy. Standard output and error are each
capped at 1 MiB (2 MiB total), with a 15-second deadline; timeout, output
overflow, failed identity checks, or failed cleanup reject the helper result.

## ALTAnisetteData compatibility hook

AltServer 1.7.6 can reinsert a legacy device description while constructing or
updating its `ALTAnisetteData` object. After the helper returns current client
info, the injected dylib hooks both
`initWithMachineID:oneTimePassword:localUserID:routingInfo:deviceUniqueIdentifier:deviceSerialNumber:deviceDescription:date:locale:timeZone:`
and `setDeviceDescription:`. Each hook is installed only when the class and
method exist and their Objective-C type encoding exactly matches the expected
ABI. A missing description or one containing the legacy Xcode marker
`3594.4.19` is replaced with the helper's `X-Mme-Client-Info`; every other
initializer argument and nonlegacy description is forwarded unchanged.

If `AltSign` is loaded after the dylib constructor, a guarded one-shot
add-image callback schedules a delayed retry for this hook. The callback does
not poll continuously, and absent classes or ABI mismatches leave the original
methods untouched.

## GrandSlam transport ownership

The official AltServer 1.7.6/AltSign transport owns GrandSlam HTTP 503 handling,
modern AuthKit client information, and the AltXPC fallback. The v3.7 injected
dylib installs no GSA network hook, User-Agent hook, or AltSign hook. AltSign
PR #54 is documented above as upstream context only. The separate helper process
uses the upstream GSA lookup endpoint
`https://gsa.apple.com/grandslam/GsService2/lookup` with
`User-Agent: akd/1.0 CFNetwork/808.1.4` for its own provisioning lookup. The
patched dylib does not hook or alter the official GSA/GrandSlam or User-Agent
authentication path.

## Internal compatibility payload v3.7

The prepared v1.0.8 candidate uses internal compatibility payload v3.7. It builds
`X-Mme-Client-Info` at runtime from the current `hw.model`, macOS product
version/build, and Xcode `25183.54.10` for the helper's fallback request. The
official response remains authoritative whenever it contains a complete,
coherent, nonempty alias pair; helper data is used only for a non-dictionary,
missing/empty, partial/incomplete, or conflicting alias response.

When an existing `RemoteAnisetteUser.json` is decoded, the client-info field is
refreshed in memory while the existing identity and provisioning data are
retained. This update therefore does not reprovision an existing identity.
Requests and the helper's returned header dictionary use the local client info
in preference to a stale server-returned `X-Mme-Client-Info` value.

## V3 provisioning

The helper implements the public anisette V3 message sequence using
Foundation:

1. Fetch Apple provisioning endpoints from `gsa.apple.com`.
2. Open a WebSocket to `/v3/provisioning_session`.
3. Exchange identifier, `spim`, `cpim`, `ptm`, and `tk` messages.
4. Store the returned `adi_pb` personalization data locally.
5. POST the saved identity to `/v3/get_headers` for fresh headers.

CryptoKit SHA-256 is used to derive the local user identifier from random
bytes. No Apple Account credentials are inputs to this flow.

The default endpoint is `ani.sidestore.zip`, which is listed by SideStore as
an official recommended server. Provisioning and header requests are retried
up to three times to tolerate short-lived network or WebSocket failures. The
endpoint can be overridden with `ALTSERVER_ANISETTE_SERVER_URL` when running
the helper directly, but it must be an HTTPS URL without userinfo. Provisioning
uses WSS; HTTP redirects and responses are accepted only on the same secure
scheme, host, and effective port, and both HTTP response bodies and WebSocket
messages are capped at 1 MiB.

## Header mapping

The helper returns current `X-Apple-I-*` headers. The compatibility layer
normalizes the two alias pairs consumed by AltServer 1.7.6:

```text
X-Apple-MD-M <- X-Apple-I-MD-M
X-Apple-MD   <- X-Apple-I-MD
```

The official 1.7.6 GrandSlam/AltXPC behavior remains in the base app; the local
patch only supplements the missing AOSKit `machineID`.

The AOSKit hook accepts only a JSON dictionary with a complete, coherent,
nonempty alias pair. Malformed or non-dictionary official output, missing or
empty values, partial/incomplete aliases, and conflicting aliases invoke the
helper; a complete official pair is passed through/canonicalized. Malformed or
non-dictionary helper output is rejected. The helper likewise validates the
expected JSON/plist shapes and HTTP status before using a response.

The official 1.7.6 handling addresses the reported HTTP 503 path, but Apple or
the configured anisette V3 server may still return an HTML `503`, an `apptokens`
service failure, or another HTTP 401/503 response. These upstream failures are
outside the local compatibility patch's guarantee.

## iPhone transport boundary

v1.0.8 contains no patched iPhone IPA and no `AltSign-Dynamic` framework. Use
the standard official **Install AltStore…** flow. The public official AltStore
2.2.2 on-device transport is separate from this Mac patch; a future refresh
failure may require the official AltStore 2.3/update. This project therefore
does not claim that on-device signing or refresh is fully solved.

## Build and signing

The official-input provenance pins are TeamIdentifier `6XVY5G3U44`, main
executable SHA-256
`d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819`, and
archive SHA-256
`ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`. The
input must have a Developer ID signature and a valid notarization ticket; these
are verified before injection and are not carried onto the ad-hoc output.

macOS 27 is the tested/supported target, not a code-level OS-version gate.

The build records the Git revision and worktree state. A binary-affecting dirty
tree fails closed unless `ALTSERVER_ALLOW_DIRTY_ATTESTED_SOURCE=1` opts into a
`dirty-attested` build; that mode snapshots the approved source files before
compilation and verifies their identities throughout. The helper and dylib
`LC_UUID` values are deterministic derivations from their source hashes and
compile inputs, and are checked after link, signing, and ZIP extraction.

Installer and restore transactions are root-only and use the same descriptor-
bound root lock. Parent device/inode identities are rechecked around copy,
rename, remove, backup publication, and recovery. Backups use the verified
`{AltServer.app,metadata}` record while retaining compatibility with legacy
`.app` plus adjacent `.metadata` records.

The prepared v1.0.8/v3.7 candidate output in `out/v1.0.8` is pending GitHub
publication. Treat any pre-existing directory as stale until a fresh build
completes successfully and verifies the four-file output.

- Helper: Swift, Foundation, CryptoKit
- Compatibility library: Objective-C, Foundation, Objective-C runtime
- Main AltServer architecture: universal (`arm64` + `x86_64`)
- Injected helper/dylib architecture: `arm64` only (native Apple Silicon; no
  Rosetta)
- Input signature: official Developer ID + notarization verified before build
- Distribution signature: ad-hoc; Developer ID/notarization is not carried
  forward after injection
- App integrity: recursive `codesign --verify --deep --strict`
- Payload integrity: SHA-256 manifest
