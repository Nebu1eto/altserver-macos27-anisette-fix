# AltServer macOS 27 Anisette Fix

[English](README.md) | [한국어](README.ko.md)

An unofficial compatibility patch for this macOS 27 error:

```text
AltServer could not retrieve anisette data value "machineID".
```

v1.0.8 is a **source-only release** based on official AltServer 1.7.6
(build 94). It addresses the Mac-side anisette path only; it does not replace
AltStore or the iPhone transport.

## What is included

This repository contains source code, build/install/restore scripts, and
documentation. You must download the official `AltServer.app` yourself from
the official URL below and build locally.

This repository and its GitHub release do **not** include an AltServer binary or
app, IPA, certificate, provisioning profile, installer package, or any other
binary release asset. Local build output is private and is not a downloadable
release asset.

## Quick start

1. **Check requirements.** Use an Apple Silicon Mac running macOS 27 natively
   (`arm64`) with the macOS 27 Command Line Tools. Rosetta and other macOS
   versions are unsupported and unverified.
2. **Download and verify the official input.** Download the official
   [AltServer 1.7.6 archive](https://cdn.altstore.io/file/altstore/altserver/1_7_6.zip)
   and verify this SHA-256 before extracting it:
   `ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`.
   Do not build from an already modified app. See [INSTALLATION.md](INSTALLATION.md)
   for the exact commands.
3. **Build locally.** From this repository, follow [BUILDING.md](BUILDING.md) to
   build the patch from your verified official app. The output stays on your
   Mac; this project does not publish the resulting app.
4. **Stage privately and validate.** Put the two scripts and the four build
   output files in a private staging directory as described in
   [INSTALLATION.md](INSTALLATION.md). Quit AltServer, then run the
   `Install.command` dry run as your normal user first:
   `ALTSERVER_INSTALL_DRY_RUN=1 ./Install.command` (do not add `sudo`).
5. **Install.** After the dry run succeeds, run `Install.command` with `sudo`
   from that same staging directory, following [INSTALLATION.md](INSTALLATION.md).
6. **Refresh AltStore.** Launch the locally built AltServer. If AltStore is not
   installed, use AltServer's official **Install AltStore…** flow. If it is
   already installed, open **My Apps > Refresh All** on the iPhone.

## Restore

`Install.command` keeps a verified backup of the official app. To undo the
change, quit AltServer and use the staged `Restore.command`; perform its
non-root dry run first, then the `sudo` restore described in
[INSTALLATION.md](INSTALLATION.md). A successful restore leaves the backup in
place.

## Privacy and security

The default anisette V3 endpoint, `https://ani.sidestore.zip`, is a public
third-party service. Anisette provisioning data can be sensitive, so use only
a service you trust and read [SECURITY.md](SECURITY.md) before proceeding.

An existing identity file with unsafe ownership or permissions may be rejected.
Review or quarantine it, then run provisioning again if needed. Never share
Apple Account credentials or codes, anisette data, identity files, device IDs,
or unredacted logs.

## Limits and status

The maintainer confirmed install, sideload, and refresh on the tested macOS 27 /
iOS 27 setup. This remains unofficial, and the locally built app is not
notarized. A macOS or AltServer update can overwrite or break this workaround;
the patch covers only the Mac-side `machineID` failure. This project is not
affiliated with or endorsed by AltStore, SideStore, or Apple.

## Further reading

- [INSTALLATION.md](INSTALLATION.md) — user installation and restore steps
- [BUILDING.md](BUILDING.md) — local build and verification
- [SECURITY.md](SECURITY.md) — privacy and threat model
- [TECHNICAL_DETAILS.md](TECHNICAL_DETAILS.md) — implementation boundaries
- [UPSTREAM_SOURCE.md](UPSTREAM_SOURCE.md) — official input provenance
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) — dependency notices
- [CHANGELOG.md](CHANGELOG.md) — release history
- [LICENSE](LICENSE) — GNU AGPL v3.0 license for this source
