unit AltExt;

interface

//uses windows;

const
  fmCreate = $FFFF;
  soFromBeginning = 0;
  soFromCurrent = 1;
  soFromEnd = 2;
  VK_RBUTTON = 2;
  VK_SHIFT = 16;
  VK_CONTROL = 17;
  VK_MENU = 18;
  SW_HIDE = 0;
  SW_MAXIMIZE = 3;
  SW_MINIMIZE = 6;
  SW_NORMAL = 1;
  SW_RESTORE = 9;
  SW_SHOW = 5;
  kernel32 ='kernel32.dll';
  user32='user32.dll';

type
  PChar = ^char;
  PWideChar = ^widechar;
  PPWideChar = ^PWideChar;
  PLongint = ^longint;
  PLongWord = ^longword;
  PUnicodeChar = ^widechar;
  ArrStr = array of UnicodeString;
  ArrStrS = array of ShortString;
  PIDs = array of longword;

  PHandle_data = ^THandle_data;
  THandle_data = record
    process_id: longword;
    best_handle: longword;
  end;

  TKeyboardState = array[0..255] of byte;

  TSHELLEXECUTEINFOW = record
    cbSize: longword;
    fMask: longword;
    wnd: longword;
    lpVerb: PWideChar;
    lpFile: PWideChar;
    lpParameters: PWideChar;
    lpDirectory: PWideChar;
    nShow: longint;
    hInstApp: longword;
    lpIDList: pointer;
    lpClass: Pwidechar;
    hkeyClass: longword;
    dwHotKey: longword;
    DUMMYUNIONNAME: record
      case longint of
        0: (hIcon: longword);
        1: (hMonitor: longword);
    end;
    hProcess: longword;
  end;
  LPSHELLEXECUTEINFOW = ^TSHELLEXECUTEINFOW;

  ENUMWINDOWSPROC = function(_para1: longword; _para2: longint): longbool; stdcall;

  PROCESSENTRY32 = record
    dwSize: longword;
    cntUsage: longword;
    th32ProcessID: longword;
    th32DefaultHeapID: longword;
    th32ModuleID: longword;
    cntThreads: longword;
    th32ParentProcessID: longword;
    pcPriClassBase: longint;
    dwFlags: longword;
    szExeFile: array [0..259] of char;
  end;

  OSVERSIONINFOA = record
    dwOSVersionInfoSize: longword;
    dwMajorVersion: longword;
    dwMinorVersion: longword;
    dwBuildNumber: longword;
    dwPlatformId: longword;
    szCSDVersion: array[0..127] of char;
  end;

  OVERLAPPED = record
    Internal: longword;
    InternalHigh: longword;
    Offset: longword;
    OffsetHigh: longword;
    hEvent: longword;
  end;
  POVERLAPPED = ^OVERLAPPED;

  SECURITY_ATTRIBUTES = record
    nLength: longword;
    lpSecurityDescriptor: pointer;
    bInheritHandle: longbool;
  end;
  LPSECURITY_ATTRIBUTES = ^SECURITY_ATTRIBUTES;
  PSECURITYATTRIBUTES = ^SECURITY_ATTRIBUTES;

  FILETIME = record
    dwLowDateTime: longword;
    dwHighDateTime: longword;
  end;

  WIN32_FIND_DATAW = record
    dwFileAttributes: longword;
    ftCreationTime: FILETIME;
    ftLastAccessTime: FILETIME;
    ftLastWriteTime: FILETIME;
    nFileSizeHigh: longword;
    nFileSizeLow: longword;
    dwReserved0: longword;
    dwReserved1: longword;
    cFileName: array[0..259] of widechar;
    cAlternateFileName: array[0..13] of widechar;
  end;

function AllowSetForegroundWindow(dwProcessId: longint): longbool; stdcall; external user32 Name 'AllowSetForegroundWindow';
function CloseHandle(hObject: longword): longbool; stdcall; external kernel32 Name 'CloseHandle';
function CreateFileW(lpFileName: Pwidechar; dwDesiredAccess, dwShareMode: longword; lpSecurityAttributes: LPSECURITY_ATTRIBUTES; dwCreationDisposition: longword; dwFlagsAndAttributes: longword; hTemplateFile: longword): longword; stdcall; external kernel32 Name 'CreateFileW';
function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: longword): longword; stdcall; external kernel32 Name 'CreateToolhelp32Snapshot';
function DeleteFile(lpFileName: Pwidechar): boolean; stdcall; external kernel32 Name 'DeleteFileW';
function EnumWindows(lpEnumFunc: ENUMWINDOWSPROC; lParam: longint): longbool; stdcall; external user32 Name 'EnumWindows';
function ReadFile(hFile: longword; var Buffer; nNumberOfBytesToRead: longword; var lpNumberOfBytesRead: longword; lpOverlapped: POverlapped): longbool; stdcall; external kernel32 Name 'ReadFile';
function SetFilePointer(hFile: longword; lDistanceToMove: longint; lpDistanceToMoveHigh: Pointer; dwMoveMethod: longword): longword; stdcall; external kernel32 Name 'SetFilePointer';
function FileTimeToDosDateTime(const lpFileTime: FileTime; var lpFatDate, lpFatTime: word): longbool; stdcall; external kernel32 Name 'FileTimeToDosDateTime';
function FileTimeToLocalFileTime(const lpFileTime: FileTime; var lpLocalFileTime: FileTime): longbool; stdcall; external kernel32 Name 'FileTimeToLocalFileTime';
function FindClose(hFindFile: longword): longbool; stdcall; external kernel32 Name 'FindClose';
function FindFirstFileW(lpFileName: Pwidechar; var lpFindFileData: WIN32_FIND_DATAW): longword; stdcall; external kernel32 Name 'FindFirstFileW';
function FindNextFileW(hFindFile: longword; var lpFindFileData: WIN32_FIND_DATAW): longbool; stdcall; external kernel32 Name 'FindNextFileW';
function FindResourceA(hModule: longword; lpName, lpType: Pchar): longword; stdcall; external kernel32 name 'FindResourceA';
function GetCommandLineW: PWideChar; stdcall; external kernel32 Name 'GetCommandLineW';
function GetEnvironmentVariable(lpName: Pwidechar; lpBuffer: Pwidechar; nSize: longword): longword; stdcall; external kernel32 Name 'GetEnvironmentVariableW';
function GetExitCodeProcess(hProcess: longword; var lpExitCode: longword): longbool; stdcall; external kernel32 Name 'GetExitCodeProcess';
function GetFileAttributesW(lpFileName: Pwidechar): longword; stdcall; external kernel32 Name 'GetFileAttributesW';
function GetForegroundWindow: longint; stdcall; external user32 Name 'GetForegroundWindow';
function GetKeyboardState(var KeyState: TKeyboardState): longbool; stdcall; external user32 Name 'GetKeyboardState';
function GetModuleFileNameExW(hProcess: longword; hModule: longword; lpFilename: PWideChar; nSize: longword): longword; stdcall; external 'psapi.dll' Name 'GetModuleFileNameExW';
function GetProcessId(hProcess: longword): longword; stdcall; external kernel32 Name 'GetProcessId';
function GetUserDefaultLCID: longword; stdcall; external kernel32 Name 'GetUserDefaultLCID';
function GetVersionExA(var lpVersionInformation: OSVersionInfoA): longbool; stdcall; external kernel32 Name 'GetVersionExA';
function GetWindow(hWnd: longword; uCmd: longword): longword; stdcall; external user32 Name 'GetWindow';
function GetWindowThreadProcessId(hWnd: longword; lpdwProcessId: PLongWord): longword; stdcall; external user32 Name 'GetWindowThreadProcessId';
function IsWindowVisible(hWnd: longword): longbool; stdcall; external user32 Name 'IsWindowVisible';
function LoadResource(hModule: longword; hResInfo: longword): longword; stdcall; external kernel32 Name 'LoadResource';
function LockResource(hResData: longword): Pointer; stdcall; external kernel32 Name 'LockResource';
function MessageBoxEx(hWnd: longword; lpText: PWideChar; lpCaption: PWidechar; uType: longword; wLanguageId: word): longint; stdcall; external user32 Name 'MessageBoxExW';
function OpenProcess(dwDesiredAccess: longword; bInheritHandle: longbool; dwProcessId: longword): longword; stdcall; external kernel32 Name 'OpenProcess';
function PathCanonicalize(lpszDst: PWideChar; lpszSrc: PWideChar): longbool; stdcall; external 'shlwapi.dll' Name 'PathCanonicalizeW';
function Process32First(hSnapshot: longword; var lppe: PROCESSENTRY32): longbool; stdcall; external kernel32 Name 'Process32First';
function Process32Next(hSnapshot: longword; var lppe: PROCESSENTRY32): longbool; stdcall; external kernel32 Name 'Process32Next';
function SendMessage(hWnd: longword; Msg: longword; wParam: longint; lParam: longint): longint; stdcall; external user32 Name 'SendMessageA';
function SetActiveWindow(hWnd: longword): longword; stdcall; external user32 Name 'SetActiveWindow';
function SetEnvironmentVariable(lpName: Pwidechar; lpValue: Pwidechar): longbool; stdcall; external kernel32 Name 'SetEnvironmentVariableW';
function SetFocus(hWnd: longword): longword; stdcall; external user32 Name 'SetFocus';
function SetForegroundWindow(hWnd: longword): longbool; stdcall; external user32 Name 'SetForegroundWindow';
function ShellExecuteExW(lpExecInfo: LPSHELLEXECUTEINFOW): boolean; stdcall; external 'shell32.dll' Name 'ShellExecuteExW';
function ShowWindow(hWnd: longword; nCmdShow: longint): longbool; stdcall; external user32 Name 'ShowWindow';
procedure BlockInput(fBlockIt: boolean); stdcall; external user32 Name 'BlockInput';
procedure Sleep(dwMilliseconds: longword); stdcall; external kernel32 Name 'Sleep';
function GetCurrentDirectoryW(nBufferLength: longword; lpBuffer: PwideChar): longword; stdcall; external kernel32 name 'GetCurrentDirectoryW';
function WriteFile(hFile: LongWord; const Buffer; nNumberOfBytesToWrite: LongWord; var lpNumberOfBytesWritten: LongWord; lpOverlapped: POverlapped): longbool; stdcall; external kernel32 name 'WriteFile';
//function CreateDirectory(lpPathName: Pwidechar; lpSecurityAttributes: PSecurityAttributes): longbool; stdcall; external kernel32 name 'CreateDirectoryW';
//function RemoveDirectory(lpPathName: Pwidechar): longbool; stdcall; external kernel32 name 'RemoveDirectoryW';
//function GetShortPathNameW(lpszLongPath: Pwidechar; lpszShortPath:Pwidechar; cchBuffer:LongWord):LongWord; stdcall; external kernel32 name 'GetShortPathNameW';
//function GetShortPathNameA(lpszLongPath: Pchar; lpszShortPath:Pchar; cchBuffer:LongWord):LongWord; stdcall; external kernel32 name 'GetShortPathNameA';

implementation

end.
