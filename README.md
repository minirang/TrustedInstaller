# TrustedInstaller

Powershell script running command prompt with TrustedInstaller privileges.

---

## ⚠️ LEGAL DISCLAIMER & WARNING (법적 면책 조항 및 경고)

[ KR ] 본 스크립트 파일의 사용 및 양도에 관한 엄중 경고
본 스크립트는 Windows 운영체제의 내부 보안 아키텍처 및 권한 메커니즘을 테스트하고 분석하기 위해 작성된 교육 및 관리 목적의 도구입니다. 본 도구의 소유권을 이전받거나 실행하는 모든 사용자는 다음 사항을 반드시 인지하고 준수해야 합니다.

### 악용 금지 엄명
본 스크립트는 시스템 최고 권한인 TrustedInstaller 토큰을 복제하여 프로세스를 제어합니다. 인가되지 않은 타인의 시스템에 무단 적용하거나, 악성 행위의 수단으로 활용하는 것을 엄격히 금지합니다.

### 기술적 위험성 및 환경 격리 요구
본 권한은 운영체제 커널 및 핵심 구성 요소를 영구적으로 변조하거나 파괴할 수 있는 위력을 가집니다. 운영 환경(Production Environment)에서의 무분별한 실행을 절대 불허하며, 반드시 완전히 격리된 가상 환경(VM, Sandbox) 내부에서만 시스템 수리, 취미, 연구 등의 악의적이지 않은 목적으로 구동해야 합니다.

### 법적 책임의 귀속
본 스크립트를 제공받은 시점 이후 발생하는 모든 시스템 장애, 데이터 유실, 오작동 및 법적 분쟁에 대한 모든 책임은 실행 및 활용을 결정한 사용자 본인에게 귀속됩니다. 제작자 및 양도자는 어떠한 직접적·간접적 손해에 대해서도 책임을 지지 않습니다.

---

[ EN ] WARNING & LIABILITY NOTICE REGARDING THE USE AND TRANSFER OF THIS SCRIPT
This script is an educational and administrative tool designed to test and analyze the internal security architecture and privilege mechanisms of the Windows operating system. Any user who takes ownership of or executes this tool must fully acknowledge and comply with the following terms:

### Prohibition of Malicious Use
This script controls processes by replicating the TrustedInstaller token, which grants the highest system-level privileges. It is strictly prohibited to apply this script to unauthorized third-party systems without permission or to utilize it as a means for malicious activities.

### Technical Risks and Environmental Isolation Requirements
These privileges possess the capacity to permanently alter or damage the OS kernel and its core components. Execution in production environments is absolutely forbidden. This script must only be run inside a fully isolated virtual environment (VM, Sandbox) for non-malicious purposes such as system repair, personal hobbies, or technical research.

### Attribution of Legal Liability
Any and all responsibilities for system failures, data loss, malfunctions, and legal disputes arising after the receipt of this script shall rest entirely with the user who decided to execute and utilize it. The creator and transferor assume no liability for any direct or indirect damages.

---

"본 코드를 보관하고 실행하는 것은 위 조항에 전적으로 동의함을 의미합니다."
"Storing and executing this code implies full agreement with the above terms and conditions."
