# AltServer macOS 27 Anisette Fix

[English](README.md) | [한국어](README.ko.md)

macOS 27에서 공식 AltServer 1.7.6(build 94)로 앱을 설치할 때 다음 오류가
발생하는 문제를 보완하기 위한 비공식 호환 빌드입니다.

```text
AltServer could not retrieve anisette data value "machineID".
```

## 릴리스 후보와 로컬 산출물 (2026-09-14)

v1.0.8/v3.7은 공식 AltServer 1.7.6(build 94)을 기반으로 준비한 릴리스
후보입니다. GitHub 공개는 대기 중이며, 이 저장소가 installer, source
archive, `latest` 릴리스 또는 `SHA256SUMS.txt` 다운로드가 이미 공개되었다고
주장하지 않습니다. 로컬에서 빌드하면 `out/v1.0.8`에는 raw 앱이나
`Payload/` 디렉터리 없이 다음 정확히 4개의 일반 파일만 생성됩니다.

```text
AltServer-macOS27-v3.7.zip
AltServer-macOS27-v3.7.executables.txt
BUILD-METADATA.txt
CHECKSUMS-SHA256.txt
```

수정된 앱은 ZIP 안에만 있으며 검증·설치할 때 임시 디렉터리로 풉니다.

현재 macOS 27/iOS 27 환경에서 maintainer가 설치, sideload 및 refresh를
테스트했습니다. 독립적인 exact-match 검증은 제한적이므로 사용 전에 후보의
hash와 release metadata를 대조하세요.

새로 성공한 빌드 전에 이미 존재하는 `out/v1.0.8`은 이전 구현에서 나온
stale 패키징일 수 있습니다. 해당 파일을 `Payload`에 복사하거나 설치하지
말고, 현재 빌드를 먼저 성공시킨 뒤 새로 검증된 네 파일만 사용하세요.

### macOS 27 launch 무결성

v1.0.8 후보를 개발하던 중 macOS 27 `dyld`가 valid nonzero
`LC_UUID`가 없는 injected dylib를 `OS_REASON_DYLD`와
`missing LC_UUID load command`로 거부하는 문제가 발견되었습니다. 이는
launch 시점 loader 요구사항이며 `machineID` 동작이나 GSA 인증 경로 변경이
아닙니다. 이제 builder의 기본 arm64 link가 deterministic nonzero `LC_UUID`를
포함하고, link 후·서명 후·ZIP 추출 후에 이를 검증합니다. arm64 helper도
valid UUID를 가져야 하며, 두 번의 clean build는 payload 산출물이 byte-identical
해야 합니다.

## 호환 환경

- Apple Silicon Mac (`arm64`)
- macOS 27은 테스트·지원 대상입니다(네이티브 arm64; Rosetta는 지원하지
  않음). 소스가 OS 버전 gate를 강제하지는 않으며 다른 버전은 지원·검증하지
  않습니다.
- 공식 AltServer 1.7.6, build 94 기반
- 주 실행 파일은 universal(`arm64` + `x86_64`) 상태로 유지되며, 주입되는
  helper와 dylib만 arm64입니다.

macOS 27.0 build `26A5353q`에서 테스트했습니다.

## upstream 상태 (2026-09-12)

공식 [Sparkle 업데이트 feed](https://altstore.io/altserver/sparkle-macos.xml)는
2026-09-10에 게시된 AltServer 1.7.6/build 94와 HTTP 503 로그인 수정을
가리킵니다. 이 버전에는 modern AuthKit client 정보와 공식 AltXPC fallback도
포함되어 있습니다. 그러나 [AltStore issue #1751](https://github.com/altstoreio/AltStore/issues/1751)은
여전히 열려 있고 macOS 27에서 1.7.6을 사용해도 `machineID` 오류가 난다는
보고가 있습니다. 따라서 v3.7은 공식 경로를 대체하지 않고 남은 경우에만
보완합니다.

공개된 AltStore Classic 2.2.2의 기기 내 transport는 별도 구성요소입니다.
이 후보에는 수정된 iPhone IPA나 `AltSign-Dynamic`이 없으며, 이후 기기 내
갱신 오류에는 공식 AltStore 2.3 또는 그 이후 업데이트가 필요할 수 있습니다.
앞의 내용은 릴리스와 issue에 대한 사실이고, 마지막 문장은 기기 내 경로를
완전히 해결했다는 주장이 아닌 호환성 범위입니다.

관련 upstream 문맥: [PR #1770](https://github.com/altstoreio/AltStore/pull/1770)은
실험 단계의 미병합 macOS 26+ anisette fallback입니다. 2026-09-12 현재
[PR #1790](https://github.com/altstoreio/AltStore/pull/1790)은 closed and
unmerged(닫힌 상태·미병합)입니다. [commit `c558994`](https://github.com/altstoreio/AltStore/commit/c558994501bac639780a853ffb54065cc703b770)는
PR head의 문맥일 뿐 upstream 의존성이 아닙니다. 공식 1.7.6 Sparkle 릴리스가
HTTP 503 로그인 수정을 별도로 포함합니다. AltSign PR #54는 별도의 역사적
문맥이며 이 로컬 payload의 구성요소가 아닙니다.

## 로컬 설치

빌드 후 네 개의 출력 파일을 저장소 설치 프로그램이 읽을 수 있는
`scripts/Payload/`에 놓고 저장소 루트에서 실행합니다.

```bash
mkdir -p scripts/Payload
cp out/v1.0.8/* scripts/Payload/
# non-root 검증만 수행합니다. dry-run에는 sudo를 붙이지 마세요.
ALTSERVER_INSTALL_DRY_RUN=1 ./scripts/Install.command
# 실제 설치는 root 전용이며 유효한 non-root SUDO_USER가 필요합니다.
sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Install.command
```

설치 프로그램은 먼저 ZIP을 임시 디렉터리에 추출하고 ZIP, manifest,
metadata, checksum, bundle metadata, architecture, symlink, executable mode와
재귀 서명을 검증한 뒤 injected dylib에 exactly one valid nonzero `LC_UUID`가
있는지 확인합니다. 이 검사는 dry-run 성공 및 `/Applications` 또는
Application Support에 쓰기 전에 수행됩니다. 임시 추출·검증 쓰기는 정상적인
단계입니다.
AltStore가 없다면 공식 **Install AltStore…** 절차를 사용하고, 이미
설치되어 있으면 iPhone의 AltStore에서 **Refresh All**을 누릅니다. 별도
custom IPA는 포함되거나 필요하지 않습니다.

### macOS가 `Install.command` 실행을 차단하는 경우

이 비공식 후보 빌드는 Apple의 공증을 받지 않았기 때문에 Gatekeeper가
스크립트 실행을 차단할 수 있습니다. `scripts/Install.command` 실행을 먼저 한 번
시도한 뒤 다음 순서로 진행하세요.

1. **시스템 설정**을 엽니다.
2. **개인정보 보호 및 보안**을 선택하고 아래의 **보안** 항목으로 이동합니다.
3. `Install.command`가 차단되었다는 메시지 옆의 **그래도 열기**를 누릅니다.
4. 다시 **열기**를 누르고, 요청하면 Mac 로그인 암호를 입력합니다.

**그래도 열기** 버튼은 실행을 시도한 뒤 약 1시간 동안 표시됩니다. 이
절차는 해당 스크립트에만 실행 예외를 추가합니다. Gatekeeper나 SIP를
시스템 전체에서 비활성화하지 마세요. 자세한 내용은
[Apple 공식 안내](https://support.apple.com/ko-kr/guide/mac-help/mh40616/mac)를
참고하세요.

iPhone에 AltStore가 이미 설치되어 있다면 **AltStore를 다시 설치할 필요가
없습니다**. Mac에 수정된 AltServer를 설치한 뒤 AltStore의 **My Apps**에서
**Refresh All**을 누르거나 필요한 앱만 개별적으로 갱신하면 됩니다.
AltStore가 사라졌거나 실행되지 않을 때만 재설치하세요.

설치 프로그램은 교체 전에 현재 공식 AltServer를 검증하고
`~/Library/Application Support/AltServer-macOS27-Fix/Backups/` 아래에 다음
형태의 백업 레코드를 원자적으로 게시합니다.

```text
Backups/AltServer-<UTC>.<pid>.<rand>.backup/{AltServer.app,metadata}
```

`metadata`에는 공식 build와 실행 파일 hash가 기록됩니다.
`Restore.command`는 검증된 최신 새 레코드를 선택하며, 다음처럼
검증된 경로를 인자로 받을 수도 있습니다. 기존 레거시 형식인
`AltServer-<UTC>.<pid>.<rand>.app`와 인접한 `.metadata`도 검증합니다.

```bash
sudo ALTSERVER_INSTALL_DRY_RUN=0 ./scripts/Restore.command \
  "$HOME/Library/Application Support/AltServer-macOS27-Fix/Backups/AltServer-<UTC>.<pid>.<rand>.backup"
```

복원 후에도 백업은 보존됩니다. 설치·복원은 정확한 실행 파일 경로가
`/Applications/AltServer.app/Contents/MacOS/AltServer`인 프로세스만 찾아
`TERM`을 보낸 뒤 종료를 기다리고, 같은 경로가 남아 있을 때만 `KILL`을
보냅니다. `/Applications`나 Application Support를 바꾸지 않고 검증하는
dry-run은 non-root로 `ALTSERVER_INSTALL_DRY_RUN=1 ./scripts/Install.command`
또는 `Restore.command`에 대해 실행합니다. 실제 Install/Restore는 non-root
실행을 거부합니다. Install은 유효한 non-root `SUDO_USER`의 canonical home과
그 사용자의 canonical backup root를 사용합니다. 실제(root) 트랜잭션의
backup-root override와 안전하지 않거나 canonical이 아닌 경로는 fail closed
됩니다. 유일한 override 예외는 non-root dry-run 검증에서만 사용하는
canonical private `0700`, owner-owned `$HOME/.altserver-install-*/Backups`
fixture입니다. 지원하지 않는 target/path override도 fail closed 됩니다. 두
트랜잭션은 shared root lock과 descriptor-bound identity 검사를 사용합니다.

## Apple 계정 2단계 인증

앱을 설치하거나 갱신하는 동안 신뢰하는 Apple 기기에 **Apple 계정 로그인
요청** 알림이 나타날 수 있습니다. AltStore에서 작업을 시작한 직후에
알림이 나타났다면 다음 순서로 진행하세요.

1. 알림에 표시된 Apple 계정이 본인의 계정인지 확인합니다.
2. **허용**을 누릅니다.
3. 표시된 6자리 인증 코드를 AltStore 또는 AltServer가 표시한 입력창에만
   입력합니다.

이는 수정 패치가 새로 추가한 로그인이 아니라 AltServer의 정상적인 Apple
계정 인증 절차입니다. 이 호환성 helper는 6자리 인증 코드를 전달받지
않으며 anisette V3 서버에도 전송하지 않습니다.

본인이 설치나 갱신을 시작하지 않았다면 **허용 안 함**을 누르세요. 인증
코드, 코드가 표시된 화면 캡처, anisette 헤더를 GitHub 이슈, 채팅 또는
지원 요청에 올리거나 타인에게 공유하지 마세요. Apple 알림에 표시되는
위치는 IP 기반의 대략적인 위치이므로 실제 위치와 다를 수 있습니다.

## 작동 방식

공식 AltServer 1.7.6(build 94)은 HTTP 503/modern AuthKit 처리와 공식
AltXPC fallback을 포함합니다. 하지만 macOS 27에서는 여전히 비공개
`AOSKit` 호출이 오류 `-45070`과 빈 딕셔너리를 반환하여 AltServer가
`X-Apple-MD-M`(`machineID`) 값을 가져오지 못할 수 있습니다. 이 상태는
issue #1751에 기록되어 있으며, 로컬 helper와 dylib는 이 남은 경우만
보완합니다.

이 프로젝트는 다음과 같이 동작합니다.

1. AltServer 앱 번들 내부에서 작은 arm64 호환성 라이브러리를 불러옵니다.
2. 먼저 공식 `AOSUtilities.retrieveOTPHeadersForDSID:` 구현을 호출합니다.
   공식 alias(`X-Apple-MD-M`/`X-Apple-MD`) 또는 접두사 alias
   (`X-Apple-I-MD-M`/`X-Apple-I-MD`) 중 하나의 완전하고 일관되며 비어
   있지 않은 쌍이면 통과시키고 두 형식으로 canonicalize합니다.
3. 공식 응답이 non-dictionary이거나 missing/empty, partial/incomplete,
   conflicting alias일 때만 공개 anisette V3 Foundation helper를 실행하고,
   반환 헤더를 같은 alias로 canonicalize합니다.
4. `ALTAnisetteData` description 메서드는 정확한 Objective-C ABI를 확인한
   뒤에만 hook하며, 관련 없는 인자와 nonlegacy description은 보존합니다.

helper는 자체 provisioning에서 upstream GSA lookup endpoint
`https://gsa.apple.com/grandslam/GsService2/lookup`과
`User-Agent: akd/1.0 CFNetwork/808.1.4`를 사용합니다. patched dylib에는
GSA network/User-Agent/AltSign hook이 없으며 공식 GSA/GrandSlam 인증 경로를
hook하거나 변조하지 않습니다. helper는 불완전한 공식 AOSKit 응답만
보완합니다.

AltServer의 나머지 코드 서명, 앱 설치, 기기 통신 로직은 변경하지 않습니다.

자세한 구현 내용은 [TECHNICAL_DETAILS.md](TECHNICAL_DETAILS.md)를
참고하세요.

## 개인정보 보호

이 호환성 helper는 Apple 계정 이메일, 암호, 세션 쿠키, 2단계 인증 코드를
anisette 서버에 전송하지 **않습니다**. 다만 AltStore와 AltServer는 정상적인
계정 인증 및 앱 서명 과정에서 Apple 서버와 통신합니다.

다음 서버에 연결합니다.

- helper의 Apple provisioning lookup: `https://gsa.apple.com/grandslam/GsService2/lookup`
- V3 `provisioning_session` 및 `get_headers` 경로: `https://ani.sidestore.zip`

개인화된 V3 기기 identity는 다음 위치에 저장됩니다.

```text
~/Library/Application Support/AltServer/RemoteAnisetteUser.json
```

이 파일은 권한 모드 `0600`으로 생성되며 릴리스 압축 파일에는 포함되지
않습니다. 다른 사람과 공유하지 마세요.

공개 anisette 서버를 사용하기 전에 [SECURITY.md](SECURITY.md)를
읽어보세요.

위 helper GSA lookup 요청 외에 patched dylib가 공식 GrandSlam 인증 교환을
수정하지 않는다는 경계를 확인하세요.

## 소스에서 빌드

필요한 환경:

- Apple Silicon Mac
- macOS 27 Command Line Tools (네이티브 arm64, Rosetta 제외)
- `/Applications/AltServer.app` 공식 1.7.6 앱(build 94)

```bash
chmod +x scripts/build_release.sh
mkdir -p out
./scripts/build_release.sh /Applications/AltServer.app ./out/v1.0.8
```

이 빌드 전에 존재하던 `out/v1.0.8`은 현재 구현 기준으로 stale입니다.
현재 스크립트가 성공적으로 끝날 때까지 사용하지 말고, 새로 생성되어 검증된
네 파일만 설치에 사용하세요.

스크립트는 주입 전에 공식 bundle ID, 버전/build, universal 주 실행 파일,
Developer ID 서명, Gatekeeper 평가, 공증 ticket, 그리고 고정된 v3.7 소스
SHA `cc5736fe799fd058eb5faeff530be670c9a46e0dbb2610b1879fb9b936d08af8`를
검증합니다. `out/v1.0.8`에는 정확히 네 개의 일반 파일만 남고 ZIP은 임시
디렉터리에서 검증합니다. 결과물은 의도적으로 ad-hoc 서명되며 Developer ID
서명이나 공증 상태를 유지하지 않습니다. 정확한 검사와 산출물은
[BUILDING.md](BUILDING.md)를 참고하세요. 모든 source/script pin과 dirty
source attestation 규칙도 해당 문서에 있습니다.

deterministic UUID와 ZIP 검사는 launch 무결성 확인일 뿐이며, `machineID`
fallback 판단이나 공식 GSA/GrandSlam 인증 경로를 변경하지 않습니다.

공식 입력 provenance pin은 TeamIdentifier `6XVY5G3U44`, 주 실행 파일
SHA-256
`d1e4188b67adbd120af597ffa11708a18cb139db9919baa5be806a129a3cf819`, 공식
archive SHA-256
`ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`입니다.
주입 전 입력은 Developer ID 서명, 재귀 strict 검증, Gatekeeper 평가 및
공증 ticket 검증을 모두 통과해야 합니다.

## 검증 항목

준비된 v1.0.8/v3.7 후보는 `out/v1.0.8`의 네 파일과 ZIP의 임시 디렉터리
추출본을 기준으로 다음 항목을 검증합니다.

- 앱 번들 전체의 재귀적 코드 서명 검증
- 새로운 V3 identity를 사용하는 최초 provisioning
- 동일하게 개인화된 V3 identity 재사용
- 원본 AltServer 복원
- 수정된 AltServer 재설치
- 결정적 v3.7 payload ZIP, executable manifest, metadata 및 checksum
- IPA, dynamic AltSign, provisioning profile 및 개인 build path가 없는지 확인
- 로컬 사용자 이름, 개인 인증서, identity 파일이 배포본에 없는지 확인

## 제한 사항

- 비공식이며 Apple 공증을 받지 않은 릴리스 후보입니다.
- helper와 주입 dylib는 `arm64`만 지원하며 universal 주 실행 파일은
  유지됩니다. Rosetta 실행은 거부됩니다.
- AltServer를 업데이트하면 이 호환 빌드가 덮어쓰일 수 있습니다.
- macOS beta 업데이트로 비공개 프레임워크의 동작이 다시 바뀔 수 있습니다.
- 설정된 anisette V3 서버의 가용성에 영향을 받습니다.
- 공식 AltServer 1.7.6은 보고된 HTTP 503 경로를 수정하지만 issue #1751은
  macOS 27 `machineID` 경로가 1.7.6에서도 실패할 수 있음을 보여 줍니다.
- Apple 또는 설정된 anisette V3 서버가 HTML `503`, `apptokens` 장애 또는
  다른 HTTP 401/503 응답을 반환할 수 있습니다.
- 이 후보에는 수정 iPhone IPA나 dynamic AltSign이 없습니다. 공개
  AltStore 2.2.2의 기기 내 transport는 별도이며, 향후 갱신 오류에는 공식
  2.3 또는 이후 업데이트가 필요할 수 있습니다.
- 로컬 패치는 macOS 27 AOSKit `machineID` 누락만 보완하며 Apple, anisette
  또는 기기 내 서비스 장애가 해결된다고 보장하지 않습니다.

## 크레딧

- [AltStore](https://github.com/altstoreio/AltStore)
- 프로토콜 참고:
  [SideStore RemoteAnisette](https://github.com/SideStore/RemoteAnisette)
- 프로토콜 참고:
  [anisette-v3-server](https://github.com/Dadoum/anisette-v3-server)

이 저장소에는 RemoteAnisette의 소스 파일을 재배포하지 않습니다.

## 라이선스

이 프로젝트와 수정된 AltServer 배포본은
[GNU Affero General Public License v3.0](LICENSE)에 따라 제공됩니다.

이 저장소는 AltStore, SideStore 또는 Apple과 제휴 관계가 없으며 이들의
승인을 받은 프로젝트가 아닙니다.
