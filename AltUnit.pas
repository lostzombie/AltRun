unit AltUnit;

interface

uses
  //  AltStream,
  AltSys,
  //SySUtils,
  //windows,
  AltCmd,
  AltExt;

function FindMainWindow(process_id: longword): longword;
function WorkAltVars(altstring: UnicodeString; c: longint; s: ArrStr; Mode: word): UnicodeString;
procedure WorkVars(c: longint; s: ArrStr; const sp, lp: UnicodeString);
//procedure DelRes(c: longint; s: ArrStr;var create:boolean);
//function ExistsRes(c: longint; s: ArrStr;var create:boolean): boolean;
function NoChildPresent(ProcessId: longword; var childs: PIDS): boolean;
function HasProcess(target: UnicodeString; mode: longword; Name: boolean; basepath: unicodestring): boolean;
//function GetShortPath(const LongPath: UnicodeString): UnicodeString;
//function GetShortName(var p : String) : boolean;
//function QuotingParams(params: UnicodeString): UnicodeString;

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

{procedure ExtractRes(Res, OutFile: UnicodeString);
var
  S: TResourceStream;
  F: TFileStream;
begin
  S := TResourceStream.Create(HInstance, Res, PChar(10));
  try
    F := TFileStream.Create(OutFile, fmCreate);
    try
      F.CopyFrom(S, S.Size);
    finally
      F.Free;
    end;
  finally
    S.Free;
  end;
end;

function ExtractPath(c: longint; s: ArrStr;var create:boolean): Unicodestring;
var path: UnicodeString = '';
begin
  Result := '';
  if hp(c, s, 'rt', res + '-temp') then Result := GetEnvVar('TEMP') + PathDelim;
  if hp(c, s, 'rp', res + '-path') then
  begin
   path := gp(c, s, 'rp', res + '-path');
   path := WorkAltVars(path, c, s, 1,create);
   if Length(path)>0 then if path[Length(path)-1]<>PathDelim then path:=path+PathDelim;
    Result := path;
  if Pos(dots,Result)=0 then Result:=RelToAbs(Result,ExtractFilePath(s[0]))+PathDelim;
  end;
  if Result = '' then Result := GetCurrentDir;
  if not Exists(Result) then
  begin
    CreateDir(Result);
    create:=true;
  end;
end;

function ExistsRes(c: longint; s: ArrStr; var create:boolean): boolean;
var
  path: unicodestring;

  i: word;
begin
  Result := False;
  path := ExtractPath(c, s,create);
  for i := 0 to 9 do if hp(c, s, 'r' + IntToStr(i), res + IntToStr(i)) then if Exists(path + gp(c, s, 'r' + IntToStr(i), res + IntToStr(i))) then Result := True;
end;

procedure DelRes(c: longint; s: ArrStr; var create:boolean);
var
  path: unicodestring;
  i: word;
begin
  path := ExtractPath(c, s,create);
  for i := 0 to 9 do if Exists(path + gp(c, s, 'r' + IntToStr(i), res + IntToStr(i))) then DeleteFile(PWideChar(path + gp(c, s, 'r' + IntToStr(i), res + IntToStr(i))));
  if create then RemoveDir(path);
end;    }

{function ReplaceResVars(const altstring, sv, lv, Value: UnicodeString; c: longint; s: ArrStr; mode: word;var create:boolean): UnicodeString;
var
  tmp, variable, localvalue: UnicodeString;
  vars: ArrStr;
  i, j, r: longint;
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
        begin
          r := 0;
          for j := 0 to 9 do if (('r' + IntToStr(j) = sv) or (res + IntToStr(j) = lv)) then Inc(r);
          if r = 0 then localvalue := localvalue + Value + separator
          else if mode = 1 then localvalue := tmp_separator + localvalue + Value + tmp_separator else localvalue := {tmp_separator +} localvalue + Value;
        end
        else localvalue := localvalue + dots + vars[i] + dots;
      if ((r > 0) and (localvalue[length(localvalue) - 1] = separator)) then setlength(localvalue, Length(localvalue) - 1);
      if ((r > 0) and (localvalue[length(localvalue) - 1] = tmp_separator)) then setlength(localvalue, Length(localvalue) - 1);
      SetLength(vars, 0);
    end
    else
    if ((variable = sv) or (variable = lv)) then localvalue := Value else localvalue := dots + variable + dots;
    for j := 0 to 9 do if ((('r' + IntToStr(j) = sv) or (res + IntToStr(j) = lv)) and (gp(c, s, 'r' + IntToStr(j), res + IntToStr(j)) <> '')) then ExtractRes('RES' + IntToStr(j), ExtractPath(c, s, create) + gp(c, s, 'r' + IntToStr(j), res + IntToStr(j)));
    if Pos(dots, localvalue) <> 0 then tmp := StringReplace(tmp, dots + variable + dots, '', [rfReplaceAll, rfIgnoreCase])
    else tmp := StringReplace(tmp, dots + variable + dots, Value, [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, dots + variable + dots, localvalue, [rfReplaceAll, rfIgnoreCase]);
    variable := ExtractBetween(tmp, dots, dots);
  end;
end;        }

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
  {for j := 0 to 9 do
    if hp(c,s,'r' + IntToStr(j), res + IntToStr(j)) then
    // if (Result=':r' + IntToStr(j)+':')or(Result=':'+res + IntToStr(j)+':') then
  begin
     path:='';

   if hp(c, s, 'rt', res + '-temp') then path := GetEnvVar('TEMP') + PathDelim;
  if hp(c, s, 'rp', res + '-path') then
  begin
   path := gp(c, s, 'rp', res + '-path');
   if Length(path)>0 then if path[Length(path)-1]<>PathDelim then path:=path+PathDelim;
   if Pos(dots,path)=0 then path:=RelToAbs(Result,ExtractFilePath(s[0]))+PathDelim;
  end;

    Result := StringReplace(Result, ':r' + IntToStr(j)+':', path+gp(c, s, 'r' + IntToStr(j), res + IntToStr(j)), []);
    Result := StringReplace(Result, ':'+res + IntToStr(j)+':', path+gp(c, s, 'r' + IntToStr(j), res + IntToStr(j)), []);
  end;
  for j := 0 to 9 do Result := ReplaceResVars(Result, 'r' + IntToStr(j), res + IntToStr(j), gp(c, s, 'r' + IntToStr(j), res + IntToStr(j)), c, s, mode,create);  }
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
{if pos(tmp_separator, Result) <> 0 then
    begin
      tmp := split(Result, tmp_separator);
      Result := ExtractPath(c, s, create) + tmp[0];
    end;      }
    if ((Pos(dots, Result) <> 2){and(Pos(PathDelim,Result)<>0)} and (not ((Pos('*', Result) <> 0) or (Pos('?', Result) <> 0)))) then
    begin
      t := RelToAbs(Result, GetCurrentDir);
      if not Exists(t) then
        t := RelToAbs(Result, ExtractFilePath(s[0]));
      if Exists(t) then
        Result := t;
    end;
    if (Pos(dots, Result) <> 2){and(Pos(PathDelim,Result)<>0)} then
    begin
      t := RelToAbs(Result, GetCurrentDir);
      if ((Pos('*', Result) <> 0) or (Pos('?', Result) <> 0)) then
        t := AltFind(t);
      {if not Exists(t) then
        t := RelToAbs(Result, ExtractFilePath(s[0]));
      if ((Pos('*', Result) <> 0) or (Pos('?', Result) <> 0)) then
        t := AltFind(t);
      if Exists(t) then   }
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

{function QuotingParams(params: UnicodeString): UnicodeString;
var x,y:unicodestring;
begin
  if Length(params) > 3 then
  begin
    if CharCount(dots, params) > 0 then
    begin
      if (CharCount(sp, params) = 0) and (CharCount(dots, params) = 1) then
        Result := params;
      if (CharCount(sp, params) > 0) and (CharCount(dots, params) = 1)and((params[1]<>dq)and(params[Length(params)]<>dq)) then
        Result := dq + params + dq;
      if (CharCount(sp, params) > 0) and (CharCount(dots, params) > 1) then
      begin

       while (CharCount(dots, params) > 1) do
        begin
        //  writeln('pos1:',pos(dots,params)-1);
        //  writeln('pos2:',pos2(dots,params)-2);
          x:=copy(params,pos(dots,params)-1,pos2(dots,params)-2);
          if length(x)>3 then if (CharCount(sp, x) > 0) and (CharCount(dots, x) = 1)and((x[1]<>dq)and(x[Length(x)]<>dq)) then x := dq + x + dq;
         // writeln('x: (',x,')');
          delete(params,pos(dots,params)-1,pos2(dots,params)-1);
         // writeln('p: (',params,')');
          y:=y+sp+x;
         // writeln('y: (',y,')');

        end;
        x:=copy(params,pos(dots,params)-1,length(params));
        if length(x)>3 then if (CharCount(sp, x) > 0) and (CharCount(dots, x) = 1)and((x[1]<>dq)and(x[Length(x)]<>dq)) then x := dq + x + dq;
         // writeln('x: (',x,')');
          delete(params,pos(dots,params)-1,pos2(dots,params)-1);
         // writeln('p: (',params,')');
          y:=y+sp+x;
         // writeln('y: (',y,')');
       if length(y)>3 then if y[1]=sp then y:=copy(y,2,length(y));
       result:=y;
      end;
    end
    else
      Result := params;
  end
  else
    Result := params;
end; }

{function GetShortPath(const LongPath: UnicodeString): UnicodeString;
{var
  Len: LongWord;
  x,y:ansistring;
begin
  x:=ansistring(LongPath);
  Len := GetShortPathNameA(@x[1], nil, 0);
  SetLength(y, Len);
  Len := GetShortPathNameA(@x[1], @y[1], Len);
  SetLength(y, Len);
  Result:=UnicodeString(y); }
var
  aTmp: array[0..255] of Char;
  x,y:ansistring;
begin
  x:=ansistring(LongPath);
 if GetShortPathNameA(@x[1], @aTmp[0], Sizeof(aTmp)) = 0 then begin
      y:= x;
   end
   else begin
      y:= StrPas (aTmp);
   end;
   Result:=UnicodeString(y);
end;     }

{function GetShortName(var p : String) : boolean;
var
  buffer   : array[0..255] of char;
  ret : longint;
begin
  {we can't mess with p, because we have to return it if call is
      unsuccesfully.}

  if Length(p)>0 then                   {copy p to array of char}
   move(p[1],buffer[0],length(p));
  buffer[length(p)]:=chr(0);

  {Should return value load loaddoserror?}

  ret:=GetShortPathNameA(@buffer,@buffer,255);
  if (Ret > 0) and (Ret <= 255) then
   begin
    Move (Buffer, P [1], Ret);
    byte (P [0]) := Ret;
    GetShortName := true;
   end
  else
   GetShortName := false;
end;        }

end.
