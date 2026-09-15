# AltServer macOS 27 Anisette Fix

[English](README.md) | [한국어](README.ko.md)

macOS 27에서 공식 AltServer 1.7.6(build 94)로 설치할 때 다음 오류가
발생하는 경우를 위한 비공식 소스 전용 호환 프로젝트입니다.

```text
AltServer could not retrieve anisette data value "machineID".
```

## 공개 범위

v1.0.8 / v3.7은 v1.0.2의 후속 소스 전용 공개입니다. GitHub 저장소에는 이
소스, 빌드·트랜잭션 스크립트와 문서만 포함됩니다. 수정된
`AltServer.app`, installer archive, 앱이 들어 있는 payload ZIP, IPA,
provisioning profile, 인증서 또는 다른 binary asset은 공개하지 않습니다.
공식 AltServer 입력은 직접 받아 로컬에서 빌드하세요.

현재 빌드 스크립트는 검증용 로컬 출력 네 개를 `out/v1.0.8`에 만듭니다.

```text
AltServer-macOS27-v3.7.zip
AltServer-macOS27-v3.7.executables.txt
BUILD-METADATA.txt
CHECKSUMS-SHA256.txt
```

이 파일들은 저장소 release asset이 아닌 로컬 빌드 결과입니다. 수정된 앱이
들어 있는 것은 ZIP뿐이며 임시 로컬 검증 결과로만 취급해야 합니다. 기존
출력 디렉터리는 현재 빌드가 성공할 때까지 stale입니다.

현재 macOS 27/iOS 27 환경에서 maintainer가 설치, sideload 및 refresh를
테스트했습니다. 독립적인 exact-match 검증은 제한적이므로 사용 전에 공식
입력 hash와 생성된 metadata를 대조하세요.

## 호환 환경

- Apple Silicon Mac, 네이티브 `arm64` 프로세스(Rosetta는 거부됨)
- macOS 27이 테스트·지원 대상입니다. 다른 macOS 버전은 지원·검증하지
  않으며 소스가 OS 버전 gate를 강제하지는 않습니다.
- 공식 AltServer 1.7.6, build 94
- 수정하지 않은 주 실행 파일은 universal(`arm64` + `x86_64`)이고 주입되는
  helper와 dylib는 `arm64` 전용입니다.

macOS 27.0 build `26A5353q`에서 테스트했습니다.

공식 AltServer 업데이트가 로컬에 설치된 호환 빌드를 덮어쓸 수 있습니다.
macOS 27에서 이 수정이 계속 필요하면 검증된 로컬 빌드를 다시 설치하고,
payload 버전을 섞지 마세요.

## upstream 문맥

[공식 Sparkle feed](https://altstore.io/altserver/sparkle-macos.xml)는
AltServer 1.7.6/build 94(2026-09-10 게시)를 가리키며 보고된 HTTP 503 로그인
처리, modern AuthKit client 정보와 공식 AltXPC fallback을 포함합니다.
[AltStore issue #1751](https://github.com/altstoreio/AltStore/issues/1751)은
1.7.6에서도 macOS 27 `machineID` 실패를 기록하고 있으며, 이 프로젝트는
그 좁은 경우만 보완합니다.

공개된 AltStore Classic 2.2.2 기기 내 transport는 별도입니다. 이 프로젝트에는
수정된 iPhone IPA나 `AltSign-Dynamic`이 없으며, 이후 refresh 실패에는 공식
AltStore 업데이트가 필요할 수 있습니다.

[AltStore PR #1770](https://github.com/altstoreio/AltStore/pull/1770)은
실험 단계의 미병합 macOS 26+ anisette fallback 문맥입니다.
[PR #1790](https://github.com/altstoreio/AltStore/pull/1790)은 closed and
unmerged이며 [commit `c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)는
PR head 문맥일 뿐 upstream 의존성이 아닙니다. 공식 1.7.6/build 94를
다운로드 archive와 정확히 매핑하는 public Git commit은 현재 증거만으로
입증할 수 없습니다. 따라서 feed, archive/version/build 및 hash를
authoritative 확인값으로 사용합니다.

## 로컬 빌드와 설치

[빌드 안내](BUILDING.md)를 먼저 읽으세요. 아래 URL에서 공식 archive를
받고 SHA-256을 확인한 뒤 압축을 풀어 수정하지 않은 `AltServer.app`을
빌드 입력으로 사용합니다.

```text
https://cdn.altstore.io/file/altstore/altserver/1_7_6.zip
SHA-256  ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9
```

저장소 루트에서 명시적인 출력 디렉터리로 빌드합니다.

```bash
mkdir -p out
./scripts/build_release.sh "/path/to/official/AltServer.app" "$PWD/out/v1.0.8"
```

스크립트는 공식 bundle metadata, Developer ID/notarization provenance,
universal 주 실행 파일, 고정 source hash, deterministic UUID와 ZIP을
검증한 뒤 네 개의 로컬 파일만 게시합니다. iPhone IPA나 provisioning
profile은 만들거나 패키징하지 않습니다.

현재 `scripts/Install.command`는 flat layout 또는 `Payload/` layout을
받습니다. private staging 디렉터리에 script를 두고 `Payload/` 안에는 출력
네 파일만 복사하세요.

```bash
stage_dir="$(mktemp -d)"
cp scripts/Install.command scripts/Restore.command "$stage_dir/"
mkdir "$stage_dir/Payload"
cp out/v1.0.8/AltServer-macOS27-v3.7.zip \
   out/v1.0.8/AltServer-macOS27-v3.7.executables.txt \
   out/v1.0.8/BUILD-METADATA.txt \
   out/v1.0.8/CHECKSUMS-SHA256.txt "$stage_dir/Payload/"
chmod +x "$stage_dir/Install.command" "$stage_dir/Restore.command"

# 호출 사용자로 read-only 검증. 이 단계에는 sudo를 붙이지 않습니다.
(cd "$stage_dir" && ALTSERVER_INSTALL_DRY_RUN=1 ./Install.command)

# /Applications/AltServer.app 교체는 root 전용입니다.
(cd "$stage_dir" && sudo ./Install.command)
```

installer는 payload를 private temporary directory에 풀고 ZIP shape,
manifest, metadata, checksum, bundle metadata, architecture, symlink,
executable mode, recursive signature 및 두 injected object의 정확히 하나인
valid nonzero `LC_UUID`를 확인합니다. 이 검사는 dry-run 성공과
`/Applications` 또는 Application Support 쓰기보다 먼저 끝납니다. 임시
추출·검증 쓰기는 정상입니다.

기존 공식 앱이 있으면 다음 경로에 검증된 백업을 저장합니다.

```text
~/Library/Application Support/AltServer-macOS27-Fix/Backups/
└── AltServer-<UTC>.<pid>.<rand>.backup/
    ├── AltServer.app
    └── metadata
```

복원할 때는 같은 staging 디렉터리의 `Restore.command`를 `sudo`로
실행합니다(non-root dry-run 규칙은 동일합니다).

```bash
(cd "$stage_dir" && sudo ./Restore.command)
```

Restore는 검증된 최신 백업을 선택하고 검증된 백업 경로 인자도 받습니다.
인접한 `.metadata`를 가진 기존 legacy `.app` 레코드도 인식합니다. 성공
후에도 백업은 보존됩니다. Install과 Restore는 정확한
`/Applications/AltServer.app`만 다루며, 실행 파일 경로가
`/Applications/AltServer.app/Contents/MacOS/AltServer`와 정확히 같은
프로세스만 종료합니다.

AltStore가 없다면 AltServer의 공식 **Install AltStore…** 절차를 사용하세요.
이미 설치되어 있으면 Mac helper를 설치했다는 이유만으로 재설치하지 말고
iPhone의 **My Apps > Refresh All**을 사용하세요. 이 저장소는 custom IPA를
제공하지 않습니다.

## Apple 계정 확인

정상적인 Apple 절차에서 **Apple Account Sign-In Requested** 알림과 6자리
코드가 나타날 수 있습니다. 작업을 직접 시작했고 표시된 계정이 본인일 때만
승인하세요. 코드는 AltStore 또는 AltServer의 입력창에만 입력합니다. 시작하지
않은 알림은 **Don't Allow**를 선택하세요. 호환성 helper는 코드를 전달받거나
anisette 서비스로 보내지 않습니다.

## 런타임에서 바뀌는 부분

dylib는 먼저 공식 `AOSUtilities.retrieveOTPHeadersForDSID:` 구현을
호출합니다. `X-Apple-MD-M`/`X-Apple-MD` 또는
`X-Apple-I-MD-M`/`X-Apple-I-MD` 중 하나의 완전하고 일관되며 비어 있지 않은
쌍만 두 alias로 canonicalize해 통과시킵니다. 공식 응답이 dictionary가
아니거나 missing/empty, partial/incomplete 또는 conflicting일 때만
Foundation 기반 arm64 helper와 공개 anisette V3 protocol을 호출합니다.
`ALTAnisetteData` description hook은 정확한 Objective-C ABI를 확인한 뒤에만
실행하며 관련 없는 인자와 nonlegacy 값은 보존합니다.

helper 자체 provisioning lookup은
`https://gsa.apple.com/grandslam/GsService2/lookup`과
`User-Agent: akd/1.0 CFNetwork/808.1.4`를 사용합니다. injected dylib에는
GSA, GrandSlam, User-Agent 또는 AltSign hook이 없고 공식 인증 경로를
재작성하지 않습니다. 주 AltServer 코드와 기기 transport는 바꾸지 않습니다.

## 개인정보와 보안

helper는 Apple ID/Apple 계정 email, 암호, session cookie, 2단계 인증 코드 또는
authorization header를 anisette 서비스에 받거나 보내지 않습니다. 전용
URLSession을 사용하며 ephemeral 저장소, cookie 비활성화, credential storage
비활성화, cache 비활성화, additional header 초기화를 적용합니다. HTTPS와
WSS는 설정된 secure origin으로 제한하고 redirect도 scheme, host, effective
port가 같을 때만 허용합니다. HTTP와 WebSocket 메시지는 각각 1 MiB로
제한됩니다.

기본 V3 endpoint는 `https://ani.sidestore.zip`입니다. 개인화된 identity는
`~/Library/Application Support/AltServer/RemoteAnisetteUser.json`에 mode
`0600`으로 로컬 저장되며 공개되거나 로컬 출력에 포함되지 않습니다. 신뢰할
수 있는 서비스만 사용하거나 source를 바꾸어 self-hosted service용으로 다시
빌드하세요. 공개 endpoint를 사용하기 전에 [SECURITY.md](SECURITY.md)를
읽으세요.

identity는 owner를 확인한 private support 디렉터리 descriptor에 상대적으로
열립니다. 디렉터리는 owner 소유이고 mode `0700`이어야 하며, identity는
owner 소유의 regular file이고 mode가 정확히 `0600`, hard link가 하나여야
합니다. no-follow와 nonblocking open으로 symlink, FIFO와 다른 non-regular
entry를 거부하고, 읽기는 64 KiB로 제한합니다. 새 identity는 고유한 `0600`
exclusive 임시 파일에 쓰고 `fsync`한 뒤 exclusive publish하므로 동시 실행이
기존 entry를 바꿀 수 없습니다. 기존 identity가 이 검사를 통과하지 못하면
helper는 사용하지 않으므로, 검토·격리 후 provisioning을 다시 실행해야 할
수 있습니다.

이슈나 로그에는 Apple ID/Apple 계정 자격 증명, 인증 코드, anisette header, device ID,
로컬 경로, IP/위치 정보 또는 `RemoteAnisetteUser.json`을 올리지 마세요.
짧게 redacted한 오류, architecture, macOS 버전, AltServer version/build와
실패 단계만 공유하세요.

## 문서

- [설치 안내](INSTALLATION.ko.md) / [English installation guide](INSTALLATION.md)
- [BUILDING.md](BUILDING.md) — source pin, 재현성과 검증
- [TECHNICAL_DETAILS.md](TECHNICAL_DETAILS.md) — 구현 경계
- [UPSTREAM_SOURCE.md](UPSTREAM_SOURCE.md) — 공식 입력 provenance
- [SECURITY.md](SECURITY.md) — threat model과 데이터 처리
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) — 의존성 고지
- [CHANGELOG.md](CHANGELOG.md) — 소스 전용 release 기록

## 라이선스와 상태

로컬 patch source는 [GNU AGPL v3.0](LICENSE)으로 제공합니다. AltServer,
Apple framework와 protocol reference project는 각자의 조건이 적용됩니다.
이 프로젝트는 비공식이며 AltStore, SideStore 또는 Apple과 제휴·승인을
받지 않았습니다.
