# AltServer macOS 27 Anisette Fix

[English](README.md) | [한국어](README.ko.md)

macOS 27에서 다음 오류가 발생할 때 사용하는 비공식 호환성 패치입니다.

```text
AltServer could not retrieve anisette data value "machineID".
```

v1.0.8은 공식 AltServer 1.7.6(build 94)을 기준으로 한 **소스 전용
release**입니다. Mac 쪽 anisette 경로만 보완하며 AltStore나 iPhone
transport를 바꾸지 않습니다.

## 포함 범위

이 저장소에는 소스, build/install/restore script와 문서만 있습니다. 아래
공식 URL에서 사용자가 공식 `AltServer.app`을 직접 받아 로컬에서 빌드해야
합니다.

이 저장소와 GitHub release에는 AltServer binary 또는 app, IPA, 인증서,
provisioning profile, installer package 및 그 밖의 binary release asset이
포함되지 않습니다. 로컬 빌드 결과는 private이며 다운로드 가능한 release
asset이 아닙니다.

## 빠른 시작

1. **요구사항을 확인합니다.** Apple Silicon Mac에서 macOS 27을 네이티브
   (`arm64`)로 실행하고 macOS 27 Command Line Tools를 준비하세요. Rosetta와
   다른 macOS 버전은 지원·검증하지 않습니다.
2. **공식 입력을 다운로드하고 확인합니다.** 공식
   [AltServer 1.7.6 archive](https://cdn.altstore.io/file/altstore/altserver/1_7_6.zip)를
   받고 압축을 풀기 전에 다음 SHA-256을 확인하세요:
   `ea4c47fa25abc0166bd4e9785f96f82488e6606b2e015ff046f8fceee083e6b9`.
   이미 수정된 앱으로 빌드하지 마세요. 정확한 명령은
   [INSTALLATION.ko.md](INSTALLATION.ko.md)에 있습니다.
3. **로컬에서 빌드합니다.** 확인한 공식 앱을 입력으로
   [BUILDING.md](BUILDING.md)의 안내에 따라 패치를 빌드하세요. 결과는 Mac
   안에만 저장되며 이 프로젝트는 완성된 app을 공개하지 않습니다.
4. **Private staging과 검증을 진행합니다.**
   [INSTALLATION.ko.md](INSTALLATION.ko.md)의 설명대로 두 script와 빌드
   출력 네 파일을 private staging 디렉터리에 둡니다. AltServer를 종료한 뒤
   일반 사용자로 `Install.command` dry-run을 먼저 실행하세요:
   `ALTSERVER_INSTALL_DRY_RUN=1 ./Install.command` (`sudo`를 붙이지 않음).
5. **설치합니다.** dry-run이 성공하면 같은 staging 디렉터리에서
   [INSTALLATION.ko.md](INSTALLATION.ko.md)의 안내에 따라 `Install.command`를
   `sudo`로 실행하세요.
6. **AltStore를 갱신합니다.** 로컬에서 빌드한 AltServer를 실행합니다.
   AltStore가 없으면 AltServer의 공식 **Install AltStore…** 절차를 사용하고,
   이미 있으면 iPhone에서 **My Apps > Refresh All**을 선택하세요.

## 복원

`Install.command`는 공식 앱의 검증된 백업을 보관합니다. 원복하려면
AltServer를 종료하고 staging 디렉터리의 `Restore.command`를 사용하세요.
먼저 non-root dry-run을 실행한 뒤 [INSTALLATION.ko.md](INSTALLATION.ko.md)에
있는 `sudo` 복원 명령을 실행합니다. 복원에 성공해도 백업은 남아 있습니다.

## 개인정보와 보안

기본 anisette V3 endpoint인 `https://ani.sidestore.zip`은 공개된 제3자
서비스입니다. Anisette provisioning data는 민감할 수 있으므로 신뢰하는
서비스만 사용하고, 실행 전에 [SECURITY.md](SECURITY.md)를 읽으세요.

기존 identity file의 소유권이나 권한이 안전하지 않으면 거부될 수 있습니다.
검토하거나 격리한 뒤 필요하면 provisioning을 다시 실행하세요. Apple 계정
자격 증명·코드, anisette data, identity file, device ID 또는 가공하지 않은
로그는 공유하지 마세요.

## 제한과 상태

Maintainer는 테스트한 macOS 27 / iOS 27 환경에서 install, sideload 및
refresh 성공을 확인했습니다. 그래도 이 프로젝트는 비공식이며 로컬에서
빌드한 app은 공증(notarized)되지 않습니다. macOS 또는 AltServer 업데이트가
이 workaround를 덮어쓰거나 작동하지 않게 만들 수 있고, 패치는 Mac 쪽
`machineID` 오류만 다룹니다. AltStore, SideStore 또는 Apple과 제휴·승인을
받지 않았습니다.

## 자세한 문서

- [INSTALLATION.ko.md](INSTALLATION.ko.md) — 설치·복원 안내
- [BUILDING.md](BUILDING.md) — 로컬 빌드와 검증
- [SECURITY.md](SECURITY.md) — 개인정보와 threat model
- [TECHNICAL_DETAILS.md](TECHNICAL_DETAILS.md) — 구현 경계
- [UPSTREAM_SOURCE.md](UPSTREAM_SOURCE.md) — 공식 입력 provenance
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) — 의존성 고지
- [CHANGELOG.md](CHANGELOG.md) — release 기록
- [LICENSE](LICENSE) — 이 source에 적용되는 GNU AGPL v3.0
