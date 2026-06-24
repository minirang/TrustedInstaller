# TrustedInstaller

Powershell script running command prompt with TrustedInstaller privileges.

---

<details>
<summary><b>[!] LEGAL DISCLAIMER & WARNING (법적 면책 조항 및 경고) - 펼치기/접기</b></summary>
<br>
[ KR ] 본 스크립트 파일의 사용에 관한 엄중 경고
<br>  
본 스크립트는 Windows 운영체제의 내부 보안 아키텍처 및 권한 메커니즘을 테스트하고 분석하기 위해 작성된 교육 및 관리 목적의 도구입니다. 본 도구를 실행하는 모든 사용자는 다음 사항을 반드시 인지하고 준수해야 합니다.

### 악용 금지 엄명
본 스크립트는 시스템 최고 권한인 TrustedInstaller 토큰을 복제하여 프로세스를 제어합니다. 인가되지 않은 타인의 시스템에 무단 적용하거나, 악성 행위의 수단으로 활용하는 것을 엄격히 금지합니다.

### 기술적 위험성 및 환경 격리 요구
본 권한은 운영체제 커널 및 핵심 구성 요소를 영구적으로 변조하거나 파괴할 수 있는 위력을 가집니다. 운영 환경(Production Environment)에서의 무분별한 실행을 절대 불허하며, 반드시 완전히 격리된 가상 환경(VM, Sandbox) 내부에서만 시스템 수리, 취미, 연구 등의 악의적이지 않은 목적으로 구동해야 합니다.

### 법적 책임의 귀속
본 스크립트를 실행한 시점 이후 발생하는 모든 시스템 장애, 데이터 유실, 오작동 및 법적 분쟁에 대한 모든 책임은 실행 및 활용을 결정한 사용자 본인에게 귀속됩니다. 제작자는 어떠한 직접적·간접적 손해에 대해서도 책임을 지지 않습니다.

---

[ EN ] WARNING & LIABILITY NOTICE REGARDING THE USE OF THIS SCRIPT<br>  
This script is an educational and administrative tool designed to test and analyze the internal security architecture and privilege mechanisms of the Windows operating system. Any user who executes this tool must fully acknowledge and comply with the following terms:

### Prohibition of Malicious Use
This script controls processes by replicating the TrustedInstaller token, which grants the highest system-level privileges. It is strictly prohibited to apply this script to unauthorized third-party systems without permission or to utilize it as a means for malicious activities.

### Technical Risks and Environmental Isolation Requirements
These privileges possess the capacity to permanently alter or damage the OS kernel and its core components. Execution in production environments is absolutely forbidden. This script must only be run inside a fully isolated virtual environment (VM, Sandbox) for non-malicious purposes such as system repair, personal hobbies, or technical research.

### Attribution of Legal Liability
Any and all responsibilities for system failures, data loss, malfunctions, and legal disputes arising after the execution of this script shall rest entirely with the user who decided to execute and utilize it. The creator assumes no liability for any direct or indirect damages.

---

"본 코드를 보관하고 실행하는 것은 위 조항에 전적으로 동의함을 의미합니다."  
"Storing and executing this code implies full agreement with the above terms and conditions."

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
