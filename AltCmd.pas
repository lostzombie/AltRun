unit AltCmd;
interface

uses
  AltStream,
  AltSys,
  AltExt;
function GetAllParams(var ParamCount: longint; var ParamStr: ArrStr): boolean;
procedure WorkAllParams(var ParamCount: longint; var ParamStr: ArrStr);
function hp(ParamCount: longint; ParamStr: ArrStr; const S1, S2: UnicodeString): boolean;
function gp(ParamCount: longint; ParamStr: ArrStr; const C: UnicodeString; const S: UnicodeString): UnicodeString;
procedure CommandLineToArgv(CmdLine: UnicodeString; var ParamCount: longint; var ParamStr: ArrStr);

implementation

function ReadStreamLine(Stream: TStream; var Line: UnicodeString): boolean;
var
  RawLine: string;
  ch: char;
begin
  Result := False;
  RawLine := '';
  ch := #0;
  while (Stream.Read(ch, 1) = 1) and (ch <> #13) do
  begin
    Result := True;
    RawLine := RawLine + ch;
  end;
  Line := RawLine;
  if ch = #13 then
  begin
    Result := True;
    if (Stream.Read(ch, 1) = 1) and (ch <> #10) then
      Stream.Seek(-1, soCurrent);
  end;
end;

procedure CommandLineToArgv(CmdLine: UnicodeString; var ParamCount: longint; var ParamStr: ArrStr);
var
  TmpStr, tmpstr2, tmpstr3: ArrStr;
  i, j, k: longint;
begin
  tmpStr := split(cmdline, ' ');
  i := 0;
  j := 0;
  while (i < length(tmpstr)) and (j < length(tmpstr)) do
  begin
    setlength(tmpstr2, j + 1);
    TmpStr2[j] := TmpStr[i];
    if (Pos(dq, TmpStr2[j]) > 0) and (CharCount(dq, TmpStr2[j]) <> 2) then
    begin
      if i + 1 <= Length(TmpStr) - 1 then
        if Pos(dq, TmpStr[i + 1]) = 0 then
          for k := i + 1 to length(tmpstr) - 1 do
          begin
            if Pos(dq, TmpStr[k]) = 0 then
            begin
              TmpStr2[j] := TmpStr2[j] + ' ' + TmpStr[k];
              Inc(i);
            end
            else break;
          end;
      Inc(i);
      if i <= Length(TmpStr) - 1 then TmpStr2[j] := TmpStr2[j] + ' ' + TmpStr[i];
    end;
    Inc(i);
    Inc(j);
  end;
  i := 0;
  j := 0;
  while (i < length(tmpstr2)) and (j < length(tmpstr2)) do
  begin
    setlength(tmpstr3, j + 1);
    TmpStr3[j] := TmpStr2[i];
    if (Pos(sq, TmpStr3[j]) > 0) and (CharCount(sq, TmpStr3[j]) <> 2) then
    begin
      if i + 1 <= Length(TmpStr2) - 1 then
        if Pos(sq, TmpStr2[i + 1]) = 0 then
          for k := i + 1 to length(tmpstr2) - 1 do
          begin
            if Pos(sq, TmpStr2[k]) = 0 then
            begin
              TmpStr3[j] := TmpStr3[j] + ' ' + TmpStr2[k];
              Inc(i);
            end
            else break;
          end;
      Inc(i);
      if i <= Length(TmpStr2) - 1 then TmpStr3[j] := TmpStr3[j] + ' ' + TmpStr2[i];
    end;
    Inc(i);
    Inc(j);
  end;
  for i := 0 to Length(TmpStr3) - 1 do
  begin
    if CharCount(sq, TmpStr3[i]) = 2 then
      if (TmpStr3[i][1] = sq) and (TmpStr3[i][Length(TmpStr3[i])] = sq) then TmpStr3[i] := Copy(TmpStr3[i], 2, Length(TmpStr3[i]) - 2);
    if Pos(sq, TmpStr3[i]) > 0 then TmpStr3[i] := StringReplace(TmpStr3[i], sq, '', [rfReplaceAll]);
    if CharCount(dq, TmpStr3[i]) = 2 then
      if (TmpStr3[i][1] = dq) and (TmpStr3[i][Length(TmpStr3[i])] = dq) then TmpStr3[i] := Copy(TmpStr3[i], 2, Length(TmpStr3[i]) - 2);
  end;
  i := 0;
  while ((TmpStr3[i][1] <> hyp) and (i < Length(TmpStr3) - 1)) do Inc(i);
  if (i > 1) and (i < Length(TmpStr3) - 1) then
  begin
    SetLength(ParamStr, Length(TmpStr3) - i + 1);
    ParamStr[0]:='';
    for j := 0 to i-1 do if ParamStr[0]='' then ParamStr[0] := ParamStr[0] + TmpStr3[j] else ParamStr[0] := ParamStr[0] + ' ' + TmpStr3[j];
    for j := i to Length(TmpStr3) - 1 do ParamStr[j - i + 1] := TmpStr3[j];
  end
  else
    ParamStr := TmpStr3;
  ParamCount := Length(ParamStr);
end;

function GetParamsFrom(Mode: string; Name: UnicodeString; Param0, o: UnicodeString; var ParamCount: longint; var ParamStr: ArrStr): boolean;
var
  i, j: longint;
  FileCfg: TFileStream;
  ResCfg: TResourceStream;
  Tmp: UnicodeString;
  TmpStr: ArrStr;
  ReadOK: boolean;
begin
  Result := False;
  if Mode = 'File' then FileCfg := TFileStream.Create(Name, 0);
  if Mode = 'Res' then ResCfg := TResourceStream.Create(HInstance, Name, PChar(10));
  i := 0;
  ReadOK := False;
  repeat
    Tmp := '';
    if Mode = 'File' then ReadOK := ReadStreamLine(FileCfg, Tmp);
    if Mode = 'Res' then ReadOK := ReadStreamLine(ResCfg, Tmp);
    if ReadOK then
    begin
      SetLength(TmpStr, i + 1);
      TmpStr[i] := Tmp;
    end;
    Inc(i);
  until not ReadOK;
  if Mode = 'File' then FileCfg.Free;
  if Mode = 'Res' then ResCfg.Free;
  Tmp := Param0;
  if Length(TmpStr) > 0 then
  begin
    for j := 0 to Length(TmpStr) - 1 do Tmp := Tmp + ' ' + TmpStr[j];
    CommandLineToArgv(Tmp, ParamCount, ParamStr);
    Result := True;
  end;
  if o <> '' then
  begin
    ParamCount := ParamCount + 2;
    SetLength(ParamStr, ParamCount);
    ParamStr[ParamCount - 2] := '-o';
    //if (CharCount(dots, o) = 1)and(Pos(dots, o) = 2)and(Pos(space, o) > 0)and(Pos(dq, o) = 0) then o:= dq+o+dq;
    ParamStr[ParamCount - 1] := o;
  end;
end;

function GetAllParams(var ParamCount: longint; var ParamStr: ArrStr): boolean;
var
  CmdLineW: PWideChar;
  i: longint;
  CfgName, o: UnicodeString;
begin
  Result := False;
  o := '';
  new(CmdLineW);
  CmdLineW := GetCommandLineW;
  {$IFDEF DBG}
  Writeln;
  Writeln('Command Line');
  Writeln;
  writeln(string(CmdLineW));
  {$ENDIF}
  CommandLineToArgv(UnicodeString(CmdLineW), ParamCount, ParamStr);
  if not hp(ParamCount, ParamStr, 'g', 'cfg') then
  begin
    if hp(ParamCount, ParamStr, 'r', 'run') or
      hp(ParamCount, ParamStr, 'rb', 'right-button') or
      hp(ParamCount, ParamStr, 'c', ctrl) or
      hp(ParamCount, ParamStr, 'a', alt) or
      hp(ParamCount, ParamStr, 's', shift) or
      hp(ParamCount, ParamStr, 'ca', ctrl + hyp + alt) or
      hp(ParamCount, ParamStr, 'cs', ctrl + hyp + shift) or
      hp(ParamCount, ParamStr, 'as', alt + hyp + shift) or
      hp(ParamCount, ParamStr, 'cas', ctrl + hyp + alt + hyp + shift) then Result := True
    else
    begin
      if ParamCount > 1 then
      begin
        if pos(space,Paramstr[1])>0 then o := dq+ParamStr[1]+dq else o:=Paramstr[1];
        for i := 2 to ParamCount - 1 do  if pos(space,Paramstr[i])>0 then o := o + ' ' +dq+ ParamStr[i]+dq else o := o + ' ' + ParamStr[i];
      end;
     // if length(o)>0 then o:=sq+o+sq;
      CfgName := GetCurrentDir + ExtractFileName(ParamStr[0]);
      SetLength(CfgName, Length(CfgName) - 3);
      CfgName := CfgName + 'cfg';
      if not (Exists(CfgName)) then
      begin
        CfgName := ParamStr[0];
        SetLength(CfgName, Length(CfgName) - 3);
        CfgName := CfgName + 'cfg';
      end;
      if Exists(CfgName) then
      begin
        if GetParamsFrom('File', CfgName, ParamStr[0], o, ParamCount, ParamStr) then Result := True;
      end;
    end;
  end
  else
  begin
    CfgName := gp(ParamCount, ParamStr, 'g', 'cfg');
    if (Pos(dots, CfgName) = 0) then CfgName := RelToAbs(CfgName, GetCurrentDir);
    if not Exists(CfgName) then
    begin
      CfgName := gp(ParamCount, ParamStr, 'g', 'cfg');
      if (Pos(dots, CfgName) = 0) then CfgName := RelToAbs(CfgName, ExtractFilePath(ParamStr[0]));
    end;
    if Exists(CfgName) then
    begin
      if GetParamsFrom('File', CfgName, ParamStr[0], o, ParamCount, ParamStr) then Result := True;
    end;
  end;
  if not Result then if GetParamsFrom('Res', 'CONFIG', ParamStr[0], o, ParamCount, ParamStr) then Result := True;
end;

procedure WorkAllParams(var ParamCount: longint; var ParamStr: ArrStr);
var TmpCount: longint;
  TmpStr: ArrStr;
  i, j, k, offset: longint;
  tmp, val: UnicodeString;
  tmpsplit: ArrStr;
begin
  TmpCount := 1;
  SetLength(TmpStr, TmpCount);
  TmpStr[0] := ParamStr[0];
  j := 0;
  if ParamCount > 1 then
  begin
    for i := 1 to ParamCount - 1 do
    begin
      offset := 0;
     { if Pos('--res-names', ParamStr[i]) <> 0 then

      begin
        offset := 0;
        tmp := gp(ParamCount, ParamStr, 'rn', res + '-names');
        if Pos(separator, tmp) <> 0 then
        begin
          tmpsplit := split(tmp, separator);
          offset := length(tmpsplit);
          for k := 0 to Length(tmpsplit) - 1 do
          begin
            Inc(j);
            SetLength(TmpStr, j + 1);
            TmpStr[j] := '--res' + IntToStr(k) + eq + tmpsplit[k];
          end;
          SetLength(tmpsplit, 0);
        end
        else
        begin
          offset := 1;
          Inc(j);
          SetLength(TmpStr, j + 1);
          TmpStr[j] := '--res0=' + tmp;
        end;
        tmp := '';
      end;
      if ParamStr[i - 1] = '-rn' then
      begin
        tmp := ParamStr[i];
        Dec(j);
        if Pos(separator, tmp) <> 0 then
        begin
          tmpsplit := split(tmp, separator);
          offset := length(tmpsplit) * 2;
          for k := 0 to Length(tmpsplit) - 1 do
          begin
            Inc(j);
            SetLength(TmpStr, j + 1);
            TmpStr[j] := '-r' + IntToStr(k);
            Inc(j);
            SetLength(TmpStr, j + 1);
            TmpStr[j] := tmpsplit[k];
          end;
          SetLength(tmpsplit, 0);
        end
        else
        begin
          offset := 2;
          Inc(j);
          SetLength(TmpStr, j + 1);
          TmpStr[j] := '-r0';
          Inc(j);
          SetLength(TmpStr, j + 1);
          TmpStr[j] := tmp;
        end;
      end;  }
      tmp := '';
      if Length(ParamStr[i])>0 then
      if ((ParamStr[i][1] = hyp) and (ParamStr[i][2] = hyp)) then
        if Pos(separator, ParamStr[i]) <> 0 then
          if Pos(eq, ParamStr[i]) = 0 then
          begin
            tmp := StringReplace(ParamStr[i], hyp + hyp, '', []);
            tmpsplit := split(tmp, separator);
            offset := length(tmpsplit);
            for k := 0 to Length(tmpsplit) - 1 do
            begin
              Inc(j);
              SetLength(TmpStr, j + 1);
              TmpStr[j] := hyp + hyp + tmpsplit[k];
            end;
            SetLength(tmpsplit, 0);
          end
          else
          if Pos(separator, ParamStr[i]) < Pos(eq, ParamStr[i]) then
          begin
            val := '';
            tmp := ExtractBetween(ParamStr[i], hyp + hyp, eq);
            val := StringReplace(ParamStr[i], hyp + hyp + tmp + eq, '', []);
            tmpsplit := split(tmp, separator);
            offset := length(tmpsplit);
            for k := 0 to Length(tmpsplit) - 1 do
            begin
              Inc(j);
              SetLength(TmpStr, j + 1);
              TmpStr[j] := hyp + hyp + tmpsplit[k] + eq + val;
            end;
            SetLength(tmpsplit, 0);
          end;
      tmp := '';
            if Length(ParamStr[i])>0 then
      if ((ParamStr[i][1] = hyp) and (ParamStr[i][2] <> hyp)) then
        if Pos(separator, ParamStr[i]) <> 0 then
        begin
          tmp := StringReplace(ParamStr[i], hyp, '', []);
          tmpsplit := split(tmp, separator);
          offset := length(tmpsplit);
          val := '';
          if i < Length(ParamStr) - 1 then
            if ParamStr[i + 1][1] <> hyp then val := ParamStr[i + 1];
          if val <> '' then offset := length(tmpsplit) * 2 else offset := length(tmpsplit);
          for k := 0 to Length(tmpsplit) - 1 do
          begin
            Inc(j);
            SetLength(TmpStr, j + 1);
            TmpStr[j] := hyp + tmpsplit[k];
            if val <> '' then
            begin
              Inc(j);
              SetLength(TmpStr, j + 1);
              TmpStr[j] := val;
            end;
          end;
          SetLength(tmpsplit, 0);
          if val <> '' then Dec(j);
          tmp := '';
        end;
      if offset = 0 then
      begin
        Inc(j);
        SetLength(TmpStr, j + 1);
        TmpStr[j] := ParamStr[i];
      end;
    end;
  end;
  ParamCount := Length(TmpStr);
  ParamStr := TmpStr;
end;

function GetParamAtIndex(ParamCount: longint; ParamStr: ArrStr; AIndex: integer; IsLong: boolean): UnicodeString;
var
  P: integer;
  O: UnicodeString;
begin
  Result := '';
  if (AIndex = 0) then Exit;
  if IsLong then
  begin
    O := ParamStr[AIndex];
    P := Pos(eq, O);
    if (P = 0) then P := Length(O);
    Delete(O, 1, P);
    Result := O;
  end
  else
  begin
    {!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}
    if ((AIndex + 1) < ParamCount) then {if (Copy(ParamStr[AIndex + 1], 1, 1) <> hyp) then} Result := ParamStr[AIndex + 1];
  end;
end;

function FindParamIndex(ParamCount: longint; ParamStr: ArrStr; const S: UnicodeString; var Longopt: boolean; StartAt: integer = 0): integer;
var
  SO, O: UnicodeString;
  I, P: integer;
begin
  SO := S;
  Result := 0;
  I := StartAt;
  if (I = 0) then I := ParamCount - 1;
  while (Result = 0) and (I >= 0) do
  begin
    O := ParamStr[i];
    if (Length(O) > 1) and (O[1] = hyp) then
    begin
      Delete(O, 1, 1);
      LongOpt := (Length(O) > 0) and (O[1] = hyp);
      if LongOpt then
      begin
        Delete(O, 1, 1);
        P := Pos(eq, O);
        if (P <> 0) then O := Copy(O, 1, P - 1);
      end;
      if (O = SO) then Result := i;
    end;
    Dec(i);
  end;
end;

function hp(ParamCount: longint; ParamStr: ArrStr; const S1, S2: UnicodeString): boolean;
var
  B: boolean;
begin
  Result := False;
  if FindParamIndex(ParamCount, ParamStr, S1, B) <> 0 or FindParamIndex(ParamCount, ParamStr, S2, B) then Result := True;
end;

function gp(ParamCount: longint; ParamStr: ArrStr; const C: UnicodeString; const S: UnicodeString): UnicodeString;
var
  B: boolean;
  I: integer;
begin
  Result := '';
  I := FindParamIndex(ParamCount, ParamStr, C, B);
  if (I = 0) then I := FindParamIndex(ParamCount, ParamStr, S, B);
  if I <> 0 then Result := GetParamAtIndex(ParamCount, ParamStr, I, B);
  if Result='""' then Result:=''
  else
  if Result <> '' then if (((Result[1] = dq) and (Result[Length(Result)] = dq)) and (CharCount(dq, Result) = 2)) then Result := Copy(Result, 2, Length(Result) - 2);
end;

end.
