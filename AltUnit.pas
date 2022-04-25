unit AltUnit;

interface

uses
  AltSys,
  AltCmd,
  AltExt;

function FindMainWindow(process_id: longword): longword;
function WorkAltVars(altstring: UnicodeString; c: longint; s: ArrStr; Mode: word): UnicodeString;
procedure WorkVars(c: longint; s: ArrStr; const sp, lp: UnicodeString);
function NoChildPresent(ProcessId: longword; var childs: PIDS): boolean;
function HasProcess(target: UnicodeString; mode: longword; Name: boolean; basepath: unicodestring): boolean;

implementation

function IsMainWindow(handle: longword): boolean;
begin
  Result := (GetWindow(handle, 4) = 0) and IsWindowVisible(handle);
end;

function EnumWindowsCallback(handle: longword; Param: longint): longbool; stdcall;
var
  Data: PHandle_data;
  process_id: longword;
begin
  Data := PHandle_data(Param);
  process_id := 0;
  GetWindowThreadProcessId(handle, @process_id);
  if (Data^.process_id <> process_id) or (not IsMainWindow(handle)) then
    exit(True);
  Data^.best_handle := handle;
  exit(False);
end;

function FindMainWindow(process_id: longword): longword;
var
  Data: THandle_data;
begin
  Data.process_id := process_id;
  Data.best_handle := 0;
  EnumWindows(@EnumWindowsCallback, longint(@Data));
  Result := Data.best_handle;
end;

function ReplaceEnv(env: UnicodeString): UnicodeString;
var
  x, y, envx: UnicodeString;
begin
  y := '';
  x := env;
  Result := x;
  y := ExtractBetween(x, percent + percent + percent, percent + percent + percent);
  while y <> '' do
  begin
    envx := GetEnvVar(y);
    if envx = '' then
      envx := percent + percent + percent + y + percent + percent + percent;
    x := StringReplace(x, percent + percent + percent + y + percent + percent + percent, y, [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, percent + percent + percent + y + percent + percent + percent, envx, [rfReplaceAll, rfIgnoreCase]);
    y := ExtractBetween(x, percent + percent + percent, percent + percent + percent);
  end;
  y := ExtractBetween(x, percent + percent + percent, percent + percent + percent);
  while y <> '' do
  begin
    envx := GetEnvVar(y);
    if envx = '' then
      envx := percent + percent + y + percent + percent;
    x := StringReplace(x, percent + percent + y + percent + percent, y, [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, percent + percent + y + percent + percent, envx, [rfReplaceAll, rfIgnoreCase]);
    y := ExtractBetween(x, percent + percent, percent + percent);
  end;
  y := ExtractBetween(x, percent, percent);
  while y <> '' do
  begin
    envx := GetEnvVar(y);
    if envx = '' then
      envx := percent + y + percent;
    x := StringReplace(x, percent + y + percent, y, [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, percent + y + percent, envx, [rfReplaceAll, rfIgnoreCase]);
    y := ExtractBetween(x, percent, percent);
  end;
end;

function ReplaceAltVars(const altstring, sv, lv, Value: UnicodeString): UnicodeString;
var
  tmp, variable, localvalue: UnicodeString;
  vars: ArrStr;
  i: longint;
begin
  variable := '';
  tmp := altstring;
  Result := tmp;
  variable := ExtractBetween(altstring, dots, dots);
  while (variable <> '') or (Pos(variable, separator) <> 0) do
  begin
    localvalue := '';
    if Pos(separator, variable) <> 0 then
    begin
      vars := split(variable, separator);
      for i := 0 to length(vars) - 1 do
        if ((vars[i] = sv) or (vars[i] = lv)) then
          localvalue := localvalue + Value + separator
        else
          localvalue := localvalue + dots + vars[i] + dots;
      SetLength(vars, 0);
    end
    else
    if ((variable = sv) or (variable = lv)) then
      localvalue := Value
    else
      localvalue := dots + variable + dots;
    if Pos(dots, localvalue) <> 0 then
      tmp := StringReplace(tmp, dots + variable + dots, '', [rfReplaceAll, rfIgnoreCase])
    else
      tmp := StringReplace(tmp, dots + variable + dots, Value, [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, dots + variable + dots, localvalue, [rfReplaceAll, rfIgnoreCase]);
    variable := ExtractBetween(tmp, dots, dots);
  end;
  Result := StringReplace(Result, dots + sv + dots, Value, [rfReplaceAll]);
  Result := StringReplace(Result, dots + lv + dots, Value, [rfReplaceAll]);
end;

function WorkAltVars(altstring: UnicodeString; c: longint; s: ArrStr; Mode: word): UnicodeString;
var
  b, cmd, t: UnicodeString;
  j: integer;
begin

  if GetEnvVar(pf86) <> '' then
  begin
    b := gp(c, s, '64', 'x64');
    if b = '' then
      b := '64';
    if hp(c, s, '64', 'x64') and (gp(c, s, '64', 'x64') = '') then
      b := '';
    cmd := cmd64;
  end
  else
  begin
    b := gp(c, s, '32', 'x86');
    if b = '' then
      b := '32';
    if hp(c, s, '32', 'x32') and (gp(c, s, '32', 'x32') = '') then
      b := '';
    cmd := cmd32;
  end;
  Result := altstring;
  Result := ReplaceAltVars(Result, 'i', 'nil', '');
  Result := ReplaceAltVars(Result, 'e', 'space', ' ');
  Result := ReplaceAltVars(Result, 'q', 'quote', chr(39));
  Result := ReplaceAltVars(Result, 's', 'quotes', '"');
  Result := ReplaceAltVars(Result, 'o', 'open', gp(c, s, 'o', 'open'));
  Result := ReplaceAltVars(Result, 'b', 'bitness', b);
  Result := ReplaceAltVars(Result, 'a', 'altrun', s[0]);
  Result := ReplaceAltVars(Result, 'n', 'name', Copy(ExtractFileName(s[0]), 1, Length(ExtractFileName(s[0])) - 4));
  Result := ReplaceAltVars(Result, 'c', 'cmd', cmd);
  Result := ReplaceAltVars(Result, 'c32', 'cmd32', cmd32);
  Result := ReplaceAltVars(Result, 'c64', 'cmd64', cmd64);
  Result := ReplaceAltVars(Result, 'ad', 'altdir', ExtractFilePath(s[0]));
  Result := ReplaceAltVars(Result, 'd', 'dir', Getcurrentdir);
  Result := ReplaceAltVars(Result, 'f', 'folder', ExtractFileName(Copy(Getcurrentdir, 1, Length(Getcurrentdir) - 1)));
  Result := ReplaceAltVars(Result, 'p', 'percent', percent);
  Result := ReplaceAltVars(Result, 't', 'dots', dots);
  Result := ReplaceAltVars(Result, 'v', 'var', gp(c, s, 'v', 'var'));
  for j := 1 to 9 do
    Result := ReplaceAltVars(Result, 'v' + IntToStr(j), 'var' + IntToStr(j), gp(c, s, 'v' + IntToStr(j), 'var' + IntToStr(j)));
  for j := 0 to 255 do
    Result := ReplaceAltVars(Result, IntToStr(j), 'chr' + IntToStr(j), chr(j));
  Result := ReplaceEnv(Result);
  if mode = 1 then
  begin
    if ((Pos(dots, Result) <> 2) and (not ((Pos('*', Result) <> 0) or (Pos('?', Result) <> 0)))) then
    begin
      t := RelToAbs(Result, GetCurrentDir);
      if not Exists(t) then
        t := RelToAbs(Result, ExtractFilePath(s[0]));
      if Exists(t) then
        Result := t;
    end;
    if (Pos(dots, Result) <> 2) then
    begin
      t := RelToAbs(Result, GetCurrentDir);
      if ((Pos('*', Result) <> 0) or (Pos('?', Result) <> 0)) then
        t := AltFind(t);
        Result := t;
    end
    else
      Result := AltFind(Result);
  end;

end;

procedure WorkVars(c: longint; s: ArrStr; const sp, lp: UnicodeString);
const
  vr = 'er';
  vrr = 'envar';
  vl = 'el';
  val = 'enval';
var
  Value: UnicodeString;
  i: word;
begin
  if hp(c, s, vr, vrr) then
    if hp(c, s, vl, val) then
    begin
      Value := gp(c, s, vl, val);
      Value := WorkAltVars(Value, c, s, 1);
      SetEnvironmentVariable(PWideChar(WideString(gp(c, s, vr, vrr))), PWideChar(WideString(Value)));
    end;
  for i := 2 to 9 do
    if hp(c, s, vr + IntToStr(i), vrr + IntToStr(i)) then
      if hp(c, s, vl + IntToStr(i), val + IntToStr(i)) then
      begin
        Value := gp(c, s, vl + IntToStr(i), val + IntToStr(i));
        Value := WorkAltVars(Value, c, s, 1);
        SetEnvironmentVariable(PWideChar(WideString(gp(c, s, vr + IntToStr(i), vrr + IntToStr(i)))), PWideChar(WideString(Value)));
      end;
  if hp(c, s, sp + vr, lp + hyp + vrr) then
    if hp(c, s, sp + vl, lp + hyp + val) then
    begin
      Value := gp(c, s, sp + vl, lp + hyp + val);
      Value := WorkAltVars(Value, c, s, 1);
      SetEnvironmentVariable(PWideChar(WideString(gp(c, s, sp + vr, lp + hyp + vrr))), PWideChar(WideString(Value)));
    end;
  for i := 2 to 9 do
    if hp(c, s, sp + vr + IntToStr(i), lp + hyp + vrr + IntToStr(i)) then
      if hp(c, s, sp + vl + IntToStr(i), lp + hyp + val + IntToStr(i)) then
      begin
        Value := gp(c, s, sp + vl + IntToStr(i), lp + hyp + val + IntToStr(i));
        Value := WorkAltVars(Value, c, s, 1);
        SetEnvironmentVariable(PWideChar(WideString(gp(c, s, sp + vr + IntToStr(i), lp + hyp + vrr + IntToStr(i)))), PWideChar(WideString(Value)));
      end;
end;

function IntIn(i: longword; a: array of longword): boolean;
var
  b: longword;
begin
  Result := False;
  for b in a do
  begin
    Result := i = b;
    if Result then
      Break;
  end;
end;

function NoChildPresent(ProcessId: longword; var childs: PIDS): boolean;
var
  hSnapShot: longword;
  ProcInfo: ProcessEntry32;
begin
  Result := True;
  hSnapShot := CreateToolHelp32Snapshot($00000002, 0);
  if (hSnapShot <> longword(-1)) then
    try
      ProcInfo.dwSize := SizeOf(ProcInfo);
      if (Process32First(hSnapshot, ProcInfo)) then
        repeat
          if ProcInfo.th32ParentProcessID = ProcessId then
          begin
            if length(childs) = 0 then
            begin
              SetLength(childs, 1);
              childs[0] := ProcInfo.th32ParentProcessID;
            end
            else
            if not (IntIn(ProcInfo.th32ParentProcessID, childs)) then
            begin
              SetLength(childs, length(childs) + 1);
              childs[length(childs) - 1] := ProcInfo.th32ParentProcessID;
            end;
            if IntIn(ProcInfo.th32ParentProcessID, childs) then
              Result := False;
          end;
        until not Process32Next(hSnapShot, ProcInfo);
    finally
      CloseHandle(hSnapShot);
    end;
end;

function AltOSVersion: longword;
var
  Version: OSVersionInfoA;
begin
  Version.dwOSVersionInfoSize := SizeOf(Version);
  if GetVersionExA(Version) then
    Result := Version.dwMajorVersion;
end;

function HasProcess(target: UnicodeString; mode: longword; Name: boolean; basepath: unicodestring): boolean;
var
  hSnapShot: longword;
  ProcInfo: ProcessEntry32;
  HProcess: longword;
  Len, Count: longword;
  Image, Ltarget: UnicodeString;
begin
  Result := False;
  Count := 0;
  Ltarget := LowerCase(target);
  if Pos(PathDelim, Ltarget) = 0 then
    Ltarget := LowerCase(RelToAbs(target, basepath));
  if Name then
    Ltarget := LowerCase(ExtractFileName(Ltarget));
  hSnapShot := CreateToolHelp32Snapshot($00000002, 0);
  if (hSnapShot <> longword(-1)) then
    try
      ProcInfo.dwSize := SizeOf(ProcInfo);
      if (Process32First(hSnapshot, ProcInfo)) then
        repeat
          if AltOSVersion > 5 then
            HProcess := OpenProcess($1000 or $0010, False, ProcInfo.th32ProcessID)
          else
            HProcess := OpenProcess($000F0000 or $00100000 or $FFF, False, ProcInfo.th32ProcessID);
          if HProcess <> 0 then
          begin
            SetLength(Image, 260);
            Len := 261;
            if Name then
              Image := LowerCase(UnicodeString(ProcInfo.szExeFile))
            else
            if GetModuleFileNameExW(HProcess, 0, Pwidechar(Image), Len) > 0 then
            begin
              SetLength(Image, Len);
              Image := LowerCase(UnicodeString(PWidechar(Image)));
            end;
            if Ltarget = Image then
              Inc(Count);
          end;
          CloseHandle(HProcess);
        until not Process32Next(hSnapShot, ProcInfo);
    finally
      CloseHandle(hSnapShot);
    end;
  if (mode = 0) and (Count > 1) then
    Result := True;
  if (mode = 1) and (Count > 0) then
    Result := True;
end;

end.
