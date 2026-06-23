
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass"
    if ($MyInvocation.PsCommandPath) {
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
        IntPtr hToken;
        OpenProcessToken(GetCurrentProcess(), 0x0020, out hToken);
        TOKEN_PRIVILEGES tp;
        tp.PrivilegeCount = 1;
        LookupPrivilegeValue(null, "SeDebugPrivilege", out tp.Privileges.Luid);
        tp.Privileges.Attributes = 2;
        AdjustTokenPrivileges(hToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        CloseHandle(hToken);

        var sc = new System.ServiceProcess.ServiceController("TrustedInstaller");
        if (sc.Status != System.ServiceProcess.ServiceControllerStatus.Running) {
            sc.Start();
            sc.WaitForStatus(System.ServiceProcess.ServiceControllerStatus.Running, TimeSpan.FromSeconds(10));
        }

        int tiPid = 0;
        foreach (var p in System.Diagnostics.Process.GetProcessesByName("TrustedInstaller")) {
            tiPid = p.Id;
            break;
        }

        IntPtr hProcess = OpenProcess(0x0400, false, tiPid);
        IntPtr hTiToken;
        OpenProcessToken(hProcess, 0x0002, out hTiToken);

        IntPtr hNewToken;
        DuplicateTokenEx(hTiToken, 0x00020000 | 0x0001 | 0x0002 | 0x0004 | 0x0008 | 0x0010 | 0x0020 | 0x0040 | 0x0080 | 0x0100, IntPtr.Zero, 2, 1, out hNewToken);

        STARTUPINFO si = new STARTUPINFO();
        si.cb = Marshal.SizeOf(si);
        PROCESS_INFORMATION pi;
        CreateProcessWithTokenW(hNewToken, 1, null, "cmd.exe", 0, IntPtr.Zero, null, ref si, out pi);

        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        CloseHandle(hNewToken);
        CloseHandle(hTiToken);
        CloseHandle(hProcess);
    }
}
"@

Add-Type -TypeDefinition $code -ReferencedAssemblies "System.ServiceProcess"
[TI]::Run()