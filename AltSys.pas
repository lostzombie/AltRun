unit AltSys;

interface

uses
  AltExt;
type
  TReplaceFlags = set of (rfReplaceAll, rfIgnoreCase);

  LongRec = packed record
    case integer of
      0: (Lo, Hi: word);
      1: (Words: array [0..1] of word);
      2: (Bytes: array [0..3] of byte);
  end;

  TUnicodeSearchRec = record
    Time: integer;
    Size: int64;
    Attr: integer;
    Name: unicodestring;
    ExcludeAttr: integer;
    FindHandle: longword;
    FindData: WIN32_FIND_DATAW;
  end;

const
  space = ' ';
  PathDelim = '\';
  dots = ':';
  separator = ';';

  tmp_separator = '/';
  dq = '"';
  sq = chr(39);
  //res = 'res';
  hyp = '-';
  und = '_';
  eq = '=';
  percent = '%';
  pf86 = 'PROGRAMFILES(X86)';
  ctrl = 'ctrl';
  alt = 'alt';
  shift = 'shift';
  cmd64 = '%windir%\Sysnative\cmd.exe';
  cmd32 = '%windir%\system32\cmd.exe';
  waits_long: array[0..26] of UnicodeString = ('before', 'ctrl-before', 'alt-before', 'shift-before', 'ctrl-alt-before', 'ctrl-shift-before', 'alt-shift-before', 'ctr-alt-shift-before', 'right-button-before', 'exist', 'ctrl-exist', 'alt-exist', 'shift-exist', 'ctrl-alt-exist', 'ctrl-shift-exist', 'alt-shift-exist', 'ctr-alt-shift-exist', 'right-button-exist', 'else', 'ctrl-else', 'alt-else', 'shift-else', 'ctrl-alt-else', 'ctrl-shift-else', 'alt-shift-else', 'ctr-alt-shift-else', 'right-button-else');
  waits_short: array[0..26] of UnicodeString = ('b', 'cb', 'ab', 'sb', 'cab', 'csb', 'asb', 'casb', 'rbtb', 'x', 'cx', 'ax', 'sx', 'cax', 'csx', 'asx', 'casx', 'rbtx', 'e', 'ce', 'ae', 'se', 'cae', 'cse', 'ase', 'case', 'rbte');

function GetEnvVar(Name: Unicodestring): Unicodestring;
function StringReplace(const S, OldPattern, NewPattern: unicodestring; Flags: TReplaceFlags): unicodestring;
function UpperCase(const S: unicodestring): unicodestring;
function LowerCase(const S: unicodestring): unicodestring;
function ExtractFilePath(const FileName: unicodestring): unicodestring; overload;
function ExtractFileName(const FileName: unicodestring): unicodestring; overload;
function Exists(const Name: unicodestring): boolean;
function IntToStr(Value: integer): Unicodestring;
function StrToInt(Value: Unicodestring): integer;
function GetCurrentDir: unicodestring;
function RelToAbs(const RelPath, BasePath: unicodestring): unicodestring;
function AltFind(f: UnicodeString): UnicodeString;
function Split(const S, separator: UnicodeString): ArrStr;
function ExtractBetween(const Value, A, B: UnicodeString): UnicodeString;
function StrIn(const AText: UnicodeString; const AValues: array of UnicodeString): boolean;
function CharCount(const C: char; S: UnicodeString): longint;
function pos2(const C: char; S: UnicodeString): longint;
//function CreateDir(const Dir: unicodestring): boolean;
//function RemoveDir(const Dir: unicodestring): boolean;

implementation

function GetEnvVar(Name: Unicodestring): Unicodestring;
var
  buf: array[0..4094] of widechar;
begin
  Result := '';
  if (GetEnvironmentVariable(pwidechar(WideString(Name)), @buf, sizeof(buf)) <> 0) then Result := string(buf);
end;

function StringReplace(const S, OldPattern, NewPattern: unicodestring; Flags: TReplaceFlags): unicodestring;
var
  SearchStr, Patt, NewStr: unicodestring;
  Offset: integer;
begin
  if rfIgnoreCase in Flags then
  begin
    SearchStr := UpperCase(S);
    Patt := UpperCase(OldPattern);
  end
  else
  begin
    SearchStr := S;
    Patt := OldPattern;
  end;
  NewStr := S;
  Result := '';
  while SearchStr <> '' do
  begin
    Offset := Pos(Patt, SearchStr);
    if Offset = 0 then
    begin
      Result := Result + NewStr;
      break;
    end;
    Result := Result + Copy(NewStr, 1, Offset - 1) + NewPattern;
    NewStr := Copy(NewStr, Offset + length(OldPattern), MaxInt);
    if not (rfReplaceAll in Flags) then
    begin
      Result := Result + NewStr;
      break;
    end;
    SearchStr := Copy(SearchStr, Offset + length(Patt), MaxInt);
  end;
end;

function UpperCase(const s: UnicodeString): UnicodeString;
begin
  Result := widestringmanager.UpperUnicodeStringProc(s);
end;

function LowerCase(const s: UnicodeString): UnicodeString;
begin
  Result := widestringmanager.LowerUnicodeStringProc(s);
end;

function IntToStr(Value: integer): Unicodestring;
begin
  Str(Value, Result);
end;

function StrToInt(Value: Unicodestring): integer;
var error: integer;
begin
  Val(Value, Result, error);
end;

function LastDelimiter(const Delimiters, S: unicodestring): integer; overload;
begin
  Result := Length(S);
  while Result > 0 do
    if (S[Result] <> #0) and (Pos(S[Result], Delimiters) = 0) then
      Dec(Result) else
      break;
end;

function ExtractFilePath(const FileName: unicodestring): unicodestring; overload;
var i: integer;
begin
  i := LastDelimiter(unicodestring(PathDelim + dots), FileName);
  Result := Copy(FileName, 1, i);
end;

function ExtractFileName(const FileName: unicodestring): unicodestring; overload;
var i: integer;
begin
  i := LastDelimiter(unicodestring(PathDelim + dots), FileName);
  Result := Copy(FileName, i + 1, $7fffffff);
end;

function Exists(const Name: unicodestring): boolean;
var code: integer;
  path: unicodestring;
begin
  path := Name;
  if Pos('..', path) <> 0 then path := RelToAbs(Name, GetCurrentDir);
  if Pos(dots, path) = 0 then path := GetCurrentDir + Name else path := Name;
  code := GetFileAttributesW(@(path[1]));
  Result := code <> -1;
end;

function GetCurrentDir: unicodestring;
var
  Dir: unicodestring;
  Len: longword;
begin
  Len := GetCurrentDirectoryW(0, nil);
  SetLength(Dir, Len - 1); // -1 because len is #0 inclusive
  GetCurrentDirectoryW(Len, PWideChar(Dir));
  Result := unicodestring(dir + pathdelim);
end;

function FFNF_WW(lpFileName: PUnicodeChar; hFindFile: longword; var lpFindFileData: WIN32_FIND_DATAW; var OutFileName: unicodestring; var ResFunc: longword; var LastOSError: longword): boolean;
begin
  Result := False;
  LastOSError := 0;
  if hFindFile = 0 then
  begin
    ResFunc := FindFirstFileW(lpFileName, lpFindFileData);
    if ResFunc = longword(-1) then  exit;
  end
  else
  begin
    ResFunc := longword(FindNextFileW(hFindFile, lpFindFileData));
    if ResFunc = longword(False) then  exit;
  end;
  OutFileName := unicodestring(lpFindFileData.cFileName);
  Result := True;
end;

function FindFirstNextFile(const sFileName: unicodestring; hFindFile: longword; var lpFindFileData: WIN32_FIND_DATAW; var OutFileName: unicodestring; var LastOSError: longword): longword;
begin
  if not FFNF_WW(@sFileName[1], hFindFile, lpFindFileData, OutFileName, Result, LastOSError) then  exit;
end;

function FindMatchingFile(var F: TUnicodeSearchRec): integer;
var LocalFileTime: FileTime;
var FileName: unicodestring;
var LastOSError: longword;
begin
  with F do
  begin
    while (FindData.dwFileAttributes and ExcludeAttr) <> 0 do
    begin
      if FindFirstNextFile('', FindHandle, FindData, FileName, LastOSError) = 0 then exit;
      Name := FileName;
    end;
    FileTimeToLocalFileTime(FindData.ftLastWriteTime, LocalFileTime);
    FileTimeToDosDateTime(LocalFileTime, LongRec(Time).Hi, LongRec(Time).Lo);
    Size := int64(int64(FindData.nFileSizeHigh) shl 32) + int64(FindData.nFileSizeLow);
    Attr := FindData.dwFileAttributes;
  end;
  Result := 0;
end;

function FindFirst(const Path: unicodestring; Attr: integer; var F: TUnicodeSearchRec): integer; overload;
const faSpecial = $00000002 or $00000004 or $00000008 or $00000010;
var FileName: unicodestring;
  LastOSError: longword;
begin
  F.ExcludeAttr := not Attr and faSpecial;
  F.FindHandle := FindFirstNextFile
    (Path, 0, F.FindData, FileName, LastOSError);
  if F.FindHandle <> longword(-1) then
  begin
    F.Name := FileName;
    Result := FindMatchingFile(F);
    if Result <> 0 then FindClose(F.FindHandle);
  end
  else Result := LastOSError;
end;

function  FindNext(var F: TUnicodeSearchRec): integer; overload;
var FileName: unicodestring;
var LastOSError: longword;
begin
  if FindFirstNextFile('', F.FindHandle, F.FindData, FileName, LastOSError)<>0 then
    begin
      F.Name := FileName;
      result := FindMatchingFile(F);
    end
  else
    result := LastOSError;
end;

function RelToAbs(const RelPath, BasePath: unicodestring): unicodestring;
var
  Dst: array[0..259] of widechar;
begin
  PathCanonicalize(@Dst[0], PWideChar(BasePath + RelPath));
  Result := Dst;
end;

function AltFind(f: UnicodeString): UnicodeString;
var
  x: UnicodeString = '';
  MySearch: TUnicodeSearchRec;
begin
  if Pos('..', x) = 0 then x := RelToAbs(x, GetCurrentDir);
  if Pos(dots, f) = 0 then x := GetCurrentDir + f else x := f;
  FindFirst(x, $0000003F, MySearch);
  x := ExtractFilePath(x) + MySearch.Name;
  if (GetEnvVar(pf86) <> '') and (pos('64',MySearch.Name)=0) then
   begin
     FindNext(MySearch);
     if pos('64',MySearch.Name)<>0 then x := ExtractFilePath(x) + MySearch.Name;
   end;
  if (GetEnvVar(pf86) = '') and (pos('64',MySearch.Name)<>0) then
   begin
     FindNext(MySearch);
     if pos('64',MySearch.Name)=0 then x := ExtractFilePath(x) + MySearch.Name;
   end;
  FindClose(MySearch.FindHandle);
  Result := x;
  if ExtractFilePath(Result) = Result then Result := f;
end;

function Split(const S, separator: UnicodeString): ArrStr;

var
  i: longint;
  T: UnicodeString;
begin
  i := 0;
  T := S;
  while (Length(T) > 1) and (Pos(separator, T) <> 0) do
  begin
    SetLength(Result, i + 1);
    Result[i] := Copy(T, 1, Pos(separator, T) - 1);
    if Result[i] = separator then Result[i] := '';
    T := StringReplace(T, Result[i] + separator, '', []);
    if Result[i] = '' then Dec(i);
    Inc(i);
  end;
  if (Length(T) > 0) then
  begin
    SetLength(Result, i + 1);
    Result[i] := T;
    if Result[i] = separator then SetLength(Result, i);
  end;
end;

function ExtractBetween(const Value, A, B: Unicodestring): Unicodestring;
var
  aPos, bPos: integer;
begin
  Result := '';
  aPos := Pos(A, Value);
  if aPos > 0 then
  begin
    aPos := aPos + Length(A);
    bPos := Pos(B, Value, aPos);
    if bPos > 0 then
    begin
      Result := Copy(Value, aPos, bPos - aPos);
    end;
  end;
end;

function StrIn(const AText: UnicodeString; const AValues: array of UnicodeString): boolean;
var
  i: longint;
begin
  Result := False;
  if (high(AValues) = -1) or (High(AValues) > MaxInt) then
    Exit;
  for i := low(AValues) to High(Avalues) do
    if (avalues[i] = AText) then
      Result := True;
end;

function CharCount(const C: char; S: UnicodeString): longint;
var i: longint;
begin
  Result := 0;
  for i := 1 to Length(S) do if S[i] = C then Inc(Result);
end;

function pos2(const C: char; S: UnicodeString): longint;
var i,count: longint;
begin
  Result := 0;
  count:=0;
  for i := 1 to Length(S) do
    begin
      if S[i] = C then inc(count);
      if count=1 then Result:=i;
    end;
end;

{function CreateDir(const Dir: unicodestring): boolean;
begin
   result := CreateDirectory(@Dir[1], nil);
end;

function RemoveDir(const Dir: unicodestring): boolean;
begin
  result := RemoveDirectory(@Dir[1]);
end;    }

end.
