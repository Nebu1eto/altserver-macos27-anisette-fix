# Changelog

## v1.0.8 / v3.7 — source-only publication — 2026-09-15

This release follows v1.0.2 in the existing GitHub repository. It publishes
source, build/transaction scripts, and documentation only. No modified
`AltServer.app`, installer archive, app-bearing payload ZIP, IPA, provisioning
profile, certificate, or other binary asset is published.

- Targets the macOS 27 `machineID` failure observed with official AltServer
  1.7.6/build 94 while preserving the official universal main executable.
- Calls the official AOSKit anisette path first and invokes the arm64 helper
  only for a non-dictionary, missing/empty, partial/incomplete, or conflicting
  alias response. The dylib has no GSA, GrandSlam, User-Agent, or AltSign hook.
- Keeps the official 1.7.6 HTTP 503/modern AuthKit handling and AltXPC fallback;
  these remain upstream behavior, not local hooks.
- Builds the helper and dylib for native Apple Silicon `arm64`; Rosetta is
  rejected. The helper uses the public anisette V3 protocol and the default
  `https://ani.sidestore.zip` service.
- Verifies official input provenance (archive SHA-256, TeamIdentifier,
  universal executable, Developer ID signature, Gatekeeper assessment, and
  notarization ticket) before local injection. The output is ad hoc signed and
  not notarized.
- Adds deterministic nonzero `LC_UUID` derivation and validation after linking,
  signing, ZIP extraction, and installer validation. This addresses a macOS 27
  loader requirement and does not change the `machineID` decision or official
  GSA/GrandSlam path.
- Produces four private local build files under `out/v1.0.8`: the app-bearing
  payload ZIP, executable manifest, metadata, and checksums. The repository
  does not publish those files; a stale pre-existing output must be rebuilt.
- Records source/worktree provenance and pins the Objective-C source, Swift
  client, Swift entry point, build script, Install.command, and Restore.command
  hashes. Binary-affecting dirty trees require explicit source attestation and
  immutable source snapshots.
- Uses dedicated ephemeral/sanitized URLSession settings: cookies, credential
  storage, cache, and inherited additional headers are disabled or cleared.
  HTTPS/WSS redirects stay on the same secure origin, and network messages are
  capped at 1 MiB.
- Uses root-only Install/Restore transactions with non-root read-only dry runs,
  canonical backup paths, descriptor-bound identity checks, a shared root lock,
  and exact target/process matching. Backups remain restorable after success.
- Keeps the iPhone boundary explicit: no patched IPA or `AltSign-Dynamic` is
  included; use the official AltStore install and refresh flows.
- Maintainer testing covered install, sideload, and refresh on the current
  macOS 27/iOS 27 environment. Independent exact-match validation remains
  limited.
- Documents that no exact public Git commit mapping for official 1.7.6/build 94
  can be proven; PR #1790 and commit `c558994` are context only.

## v1.0.2 — 2026-06-13 (historical)

- Documented the per-script Gatekeeper **Open Anyway** flow.
- Linked Apple's official English and Korean guidance.
- Clarified that Gatekeeper and SIP must not be disabled globally.
- Made no change to the patched AltServer implementation.

Earlier release notes are historical context only. They are not instructions
for the v1.0.8 source-only workflow.
