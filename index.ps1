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
