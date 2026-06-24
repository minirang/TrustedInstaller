<#
[!] LEGAL DISCLAIMER & WARNING (법적 면책 조항 및 경고)

[ KR ] 본 스크립트 파일의 사용에 관한 엄중 경고
본 스크립트는 Windows 운영체제의 내부 보안 아키텍처 및 권한 메커니즘을 테스트하고 분석하기 위해 작성된 교육 및 관리 목적의 도구입니다. 본 도구를 실행하는 모든 사용자는 다음 사항을 반드시 인지하고 준수해야 합니다.

악용 금지 엄명
본 스크립트는 시스템 최고 권한인 TrustedInstaller 토큰을 복제하여 프로세스를 제어합니다. 인가되지 않은 타인의 시스템에 무단 적용하거나, 악성 행위의 수단으로 활용하는 것을 엄격히 금지합니다.

기술적 위험성 및 환경 격리 요구
본 권한은 운영체제 커널 및 핵심 구성 요소를 영구적으로 변조하거나 파괴할 수 있는 위력을 가집니다. 운영 환경(Production Environment)에서의 무분별한 실행을 절대 불허하며, 반드시 완전히 격리된 가상 환경(VM, Sandbox) 내부에서만 시스템 수리, 취미, 연구 등의 악의적이지 않은 목적으로 구동해야 합니다.

법적 책임의 귀속
본 스크립트를 실행한 시점 이후 발생하는 모든 시스템 장애, 데이터 유실, 오작동 및 법적 분쟁에 대한 모든 책임은 실행 및 활용을 결정한 사용자 본인에게 귀속됩니다. 제작자는 어떠한 직접적·간접적 손해에 대해서도 책임을 지지 않습니다.

[ EN ] WARNING & LIABILITY NOTICE REGARDING THE USE OF THIS SCRIPT
This script is an educational and administrative tool designed to test and analyze the internal security architecture and privilege mechanisms of the Windows operating system. Any user who executes this tool must fully acknowledge and comply with the following terms:

Prohibition of Malicious Use
This script controls processes by replicating the TrustedInstaller token, which grants the highest system-level privileges. It is strictly prohibited to apply this script to unauthorized third-party systems without permission or to utilize it as a means for malicious activities.

Technical Risks and Environmental Isolation Requirements
These privileges possess the capacity to permanently alter or damage the OS kernel and its core components. Execution in production environments is absolutely forbidden. This script must only be run inside a fully isolated virtual environment (VM, Sandbox) for non-malicious purposes such as system repair, personal hobbies, or technical research.

Attribution of Legal Liability
Any and all responsibilities for system failures, data loss, malfunctions, and legal disputes arising after the execution of this script shall rest entirely with the user who decided to execute and utilize it. The creator assumes no liability for any direct or indirect damages.

"본 코드를 보관하고 실행하는 것은 위 조항에 전적으로 동의함을 의미합니다."
"Storing and executing this code implies full agreement with the above terms and conditions."
#>



$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass"
    if ($PSCommandPath) {
        $arguments += " -File `"$PSCommandPath`""
    } else {
        $arguments += " -Command `"$($MyInvocation.Line)`""
    }
    Start-Process powershell -ArgumentList $arguments -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force

$code = @"
using System;
using System.Runtime.InteropServices;

public class TI {
    private const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
    private const uint TOKEN_QUERY = 0x0008;
    private const uint TOKEN_DUPLICATE = 0x0002;
    private const uint PROCESS_QUERY_INFORMATION = 0x0400;
    private const uint SE_PRIVILEGE_ENABLED = 2;
    private const uint LOGON_WITH_PROFILE = 1;

    [StructLayout(LayoutKind.Sequential)]
    public struct STARTUPINFO {
        public Int32 cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public Int32 dwX;
        public Int32 dwY;
        public Int32 dwXSize;
        public Int32 dwYSize;
        public Int32 dwXCountChars;
        public Int32 dwYCountChars;
        public Int32 dwFillAttribute;
        public Int32 dwFlags;
        public Int16 wShowWindow;
        public Int16 cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION {
        public IntPtr hProcess;
        public IntPtr hThread;
        public Int32 dwProcessId;
        public Int32 dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct LUID_AND_ATTRIBUTES {
        public Int64 Luid;
        public UInt32 Attributes;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct TOKEN_PRIVILEGES {
        public UInt32 PrivilegeCount;
        public LUID_AND_ATTRIBUTES Privileges;
    }

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool OpenProcessToken(IntPtr ProcessHandle, UInt32 DesiredAccess, out IntPtr TokenHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetCurrentProcess();

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out Int64 lpLuid);

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, UInt32 BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(UInt32 processAccess, bool bInheritHandle, int processId);

    [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool DuplicateTokenEx(IntPtr hExistingToken, uint dwDesiredAccess, IntPtr lpTokenAttributes, int ImpersonationLevel, int TokenType, out IntPtr phNewToken);

    [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CreateProcessWithTokenW(IntPtr hToken, uint dwLogonFlags, string lpApplicationName, string lpCommandLine, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    public static void Run() {
        IntPtr hToken = IntPtr.Zero;
        IntPtr hProcess = IntPtr.Zero;
        IntPtr hTiToken = IntPtr.Zero;
        IntPtr hNewToken = IntPtr.Zero;
        PROCESS_INFORMATION pi = default;

        try {
            OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out hToken);
            TOKEN_PRIVILEGES tp;
            tp.PrivilegeCount = 1;
            LookupPrivilegeValue(null, "SeDebugPrivilege", out tp.Privileges.Luid);
            tp.Privileges.Attributes = SE_PRIVILEGE_ENABLED;
            AdjustTokenPrivileges(hToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            CloseHandle(hToken);
            hToken = IntPtr.Zero;

            using (var sc = new System.ServiceProcess.ServiceController("TrustedInstaller")) {
                if (sc.Status != System.ServiceProcess.ServiceControllerStatus.Running) {
                    sc.Start();
                    sc.WaitForStatus(System.ServiceProcess.ServiceControllerStatus.Running, TimeSpan.FromSeconds(10));
                }
            }

            int tiPid = 0;
            var processes = System.Diagnostics.Process.GetProcessesByName("TrustedInstaller");
            try {
                foreach (var p in processes) {
                    tiPid = p.Id;
                    break;
                }
            }
            finally {
                foreach (var p in processes) {
                    p.Dispose();
                }
            }

            hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, false, tiPid);
            OpenProcessToken(hProcess, TOKEN_DUPLICATE, out hTiToken);

            DuplicateTokenEx(hTiToken, 0x00020000 | 0x0001 | 0x0002 | 0x0004 | 0x0008 | 0x0010 | 0x0020 | 0x0040 | 0x0080 | 0x0100, IntPtr.Zero, 2, 1, out hNewToken);

            STARTUPINFO si = new STARTUPINFO();
            si.cb = Marshal.SizeOf(si);
						si.lpDesktop = @"winsta0\default";
            CreateProcessWithTokenW(hNewToken, LOGON_WITH_PROFILE, null, "cmd.exe", 0, IntPtr.Zero, null, ref si, out pi);
        }
        finally {
            if (pi.hThread != IntPtr.Zero) CloseHandle(pi.hThread);
            if (pi.hProcess != IntPtr.Zero) CloseHandle(pi.hProcess);
            if (hNewToken != IntPtr.Zero) CloseHandle(hNewToken);
            if (hTiToken != IntPtr.Zero) CloseHandle(hTiToken);
            if (hProcess != IntPtr.Zero) CloseHandle(hProcess);
            if (hToken != IntPtr.Zero) CloseHandle(hToken);
        }
    }
}
"@

if (-not ([System.Management.Automation.PSTypeName]'TI').Type) {
    Add-Type -TypeDefinition $code -ReferencedAssemblies "System.ServiceProcess"
}
[TI]::Run()
