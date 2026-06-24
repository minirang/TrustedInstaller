# TrustedInstaller

Powershell script running command prompt with TrustedInstaller privileges.

---

<details>
<summary><b>[!] LEGAL DISCLAIMER & WARNING (법적 면책 조항 및 경고) - 펼치기/접기</b></summary>

### [KR]

본 스크립트는 Windows 운영체제의 내부 보안 아키텍처 및 권한 메커니즘을 테스트하고 분석하기 위한 교육 및 관리 목적의 도구입니다.

#### 악용 금지
본 스크립트는 `TrustedInstaller`의 시스템 권한을 사용하여 프로세스를 실행합니다. 허가받지 않은 시스템에서의 사용이나 악의적인 목적으로의 활용은 엄격히 금지됩니다.

#### 기술적 위험성
이 권한은 운영체제의 핵심 구성 요소를 변경하거나 시스템을 손상시킬 수 있습니다. 운영(Production) 환경에서의 실행은 권장되지 않으며, 가급적 완전히 격리된 가상 환경(VM, Sandbox)에서 시스템 관리, 복구, 연구 등 정당한 목적으로만 사용해야 합니다.

#### 책임의 한계
본 스크립트의 실행으로 인해 발생하는 시스템 장애, 데이터 손실, 오작동 또는 기타 모든 결과에 대한 책임은 전적으로 실행한 사용자에게 있습니다. 제작자는 이에 따른 직접적 또는 간접적 손해에 대해 책임을 지지 않습니다.

---

### [EN]

This script is an educational and administrative tool intended to test and analyze the internal security architecture and privilege mechanisms of the Windows operating system.

#### Prohibition of Misuse
This script launches processes using the `TrustedInstaller` security context. Any unauthorized use on third-party systems or use for malicious purposes is strictly prohibited.

#### Technical Risks
These privileges can modify critical operating system components and may cause irreversible system damage. Running this script in production environments is not recommended. It should preferably be used only within a fully isolated virtual environment (VM or Sandbox) for legitimate purposes such as system administration, recovery, or security research.

#### Limitation of Liability
The user assumes full responsibility for any system failure, data loss, malfunction, or other consequences resulting from the execution of this script. The author shall not be liable for any direct or indirect damages arising from its use.

</details>

---

<details>
<summary><b>Code Explanation - 펼치기/접기</b></summary>

이 스크립트는 시스템 파일 권한을 영구적으로 변경하지 않고, 메모리 상에서 `TrustedInstaller` 서비스의 보안 토큰을 위임(Impersonation)받아 새 프로세스를 실행합니다.

### 1. PowerShell Wrapper Layer
* **Administrator Privilege Check**: 현재 세션이 관리자 계정인지 확인하고, 아닐 경우 UAC(사용자 계정 컨트롤) 승인을 자동으로 요청하여 다시 시작합니다.
* **Execution Policy**: 해당 PowerShell 세션 범위 안에서만 스크립트 실행 규칙을 일시적으로 완화합니다.
* **Add-Type Compilation**: 메모리 내에 동일한 타입이 존재하지 않는 경우에만 내장 컴파일러를 통해 인라인 C# 코드를 안전하게 로드합니다.

### 2. C# Core Logic Layer (Win32 API Interaction)
* **Privilege Elevation (`AdjustTokenPrivileges`)**: 시스템 프로세스의 토큰 정보를 참조하기 위해 현재 프로세스에 디버그 특권(`SeDebugPrivilege`)을 활성화합니다.
* **Service Control (`ServiceController`)**: 백그라운드에서 `TrustedInstaller` 서비스의 가동 여부를 검사하고, 실행 상태가 아니라면 활성화하여 대기합니다.
* **Process Discovery & Handle Management**:
  * 구동 중인 `TrustedInstaller` 프로세스를 안전하게 탐색하고, 작업 후 배열 내 프로세스 개체들을 즉시 `Dispose()` 처리하여 자원 누수를 방지합니다.
  * 대상 프로세스로부터 정보 조회 권한 핸들을 안전하게 엽니다.
* **Token Duplication (`DuplicateTokenEx`)**: 확보한 프로세스 핸들 내부의 기본 토큰 정보를 복제하여 임의 프로세스 생성이 가능한 최고 수준의 가용 자원 토큰을 획득합니다.
* **Process Creation with Token (`CreateProcessWithTokenW`)**: 
  * 복제 가공된 시스템 보안 토큰을 직접 할당하여 `cmd.exe` 프로세스를 초기화합니다.
  * 최신 UAC 정책 하에서 GUI 창이 백그라운드(Session 0)로 숨는 문제를 방지하기 위해 데스크톱 기본 윈도우 환경인 `winsta0\default` 환경을 구조체 상에 고정 명시합니다.
* **Resource Cleanup (`try-finally`)**: 가동 중 내부 API 오류나 예외 상태가 발생하더라도 열려있는 모든 OS 포인터 자원(`IntPtr`)을 실시간 추적하여 `CloseHandle`을 통해 완전히 회수합니다.
</details>
