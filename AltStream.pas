unit AltStream;

interface

uses
  //LLCLOSInt,
  AltExt,
  AltSys;

type
  TSeekOrigin = (soBeginning, soCurrent, soEnd);

type
  TStream = class
  protected
    procedure SetPosition(Value: integer); virtual;
    function GetPosition(): integer; virtual;
    function GetSize(): integer; virtual;
    procedure SetSize(Value: integer); virtual;
  public
    function Read(var Buffer; Count: integer): integer; virtual; abstract;
    procedure ReadBuffer(var Buffer; Count: integer);
    function Write(var Buffer; Count: integer): integer; virtual; abstract;
    function Seek(Offset: integer; Origin: word): integer; overload; virtual; abstract;
    function Seek(Offset: int64; Origin: TSeekOrigin): int64; overload; virtual; abstract;
    procedure Clear;
    procedure LoadFromStream(aStream: TStream); virtual;
    procedure LoadFromFile(const FileName: string);
    function CopyFrom(Source: TStream; Count: integer): integer;
    property Size: integer read GetSize write SetSize;
    property Position: integer read GetPosition write SetPosition;
  end;

  TFileStream = class(TStream)
  private
    fHandle: LongWord;
    fFileName: string;
  protected
    procedure SetSize(Value: integer); override;
  public
    constructor Create(const FileName: string; Mode: word);
    destructor Destroy; override;
    property FileName: string read fFileName;
    function Read(var Buffer; Count: integer): integer; override;
    function  Write(var Buffer; Count: integer): integer; override;
    function Seek(Offset: integer; Origin: word): integer; overload; override;
    function Seek(Offset: int64; Origin: TSeekOrigin): int64; overload; override;
    property Handle: LongWord read fHandle;
  end;

  TResourceStream = class(TStream)
  protected
    fPosition, fSize: integer;
    fMemory: pointer;
    procedure SetPosition(Value: integer); override;
    function GetPosition(): integer; override;
    function GetSize(): integer; override;
    procedure SetSize(Value: integer); override;
  public
    constructor Create(Instance: LongWord; const ResName: string; ResType: PChar);
    function Read(var Buffer; Count: integer): integer; override;
    procedure SetPointer(Buffer: pointer; Count: integer);
    function Seek(Offset: integer; Origin: word): integer; override;
    property Memory: pointer read fMemory;
  end;


implementation

function  FileRead(Handle: LongWord; var Buffer; Count: LongWord): integer;
begin
  if not ReadFile(Handle, Buffer, Count, LongWord(result), nil) then
    result := 0;
end;

function  FileSeek(Handle: LongWord; Offset, Origin: integer): integer;
begin
  result := SetFilePointer(Handle, Offset, nil, Origin);
end;

function  FileWrite(Handle: THandle; const Buffer; Count: cardinal): integer;
begin
  if not WriteFile(Handle, Buffer, Count, cardinal(result), nil) then
    result := 0;
end;

function FileCreate(const FileName: unicodestring): longword;
begin
  Result := CreateFileW(@FileName[1], $80000000 or $40000000, 0, nil, 2, $0000080, 0);
end;

function FileOpen(const FileName: unicodestring; Mode: longword): longword;
const
  AccessMode: array[0..2] of longword = ($80000000, $40000000, $80000000 or $40000000);
  ShareMode: array[0..4] of longword = (0, 0, 1, 2, 1 or 2);
begin
  Result := CreateFileW(@FileName[1], AccessMode[Mode and 3], ShareMode[(Mode and $F0) shr 4], nil, 3, $0000080, 0);
end;

procedure TStream.Clear;
begin
  Position := 0;
  Size := 0;
end;

function TStream.CopyFrom(Source: TStream; Count: integer): integer;
const
  MaxBufSize = $F000 * 4;
var
  BufSize, N: integer;
  Buffer: PChar;
begin
  if Count = 0 then
  begin
    Source.Position := 0;
    Count := Source.Size;
  end;
  Result := Count;
  if Count > MaxBufSize then
    BufSize := MaxBufSize else
    BufSize := Count;
  GetMem(Buffer, BufSize);
  try
    while Count <> 0 do
    begin
      if Count > BufSize then
        N := BufSize else
        N := Count;
      if Source.Read(Buffer^, N) <> N then
        break;
      if Write(Buffer^, N) <> N then
       break;
      Dec(Count, N);
    end;
  finally
    FreeMem(Buffer);
  end;
end;

function TStream.GetPosition(): integer;
begin
  Result := Seek(0, soFromCurrent);
end;

function TStream.GetSize(): integer;
var Pos: integer;
begin
  Pos := Seek(0, soFromCurrent);
  Result := Seek(0, soFromEnd);
  Seek(Pos, soFromBeginning);
end;

procedure TStream.SetPosition(Value: integer);
begin
  Seek(Value, soFromBeginning);
end;

procedure TStream.SetSize(Value: integer);
begin

end;

procedure TStream.LoadFromFile(const FileName: string);
var F: TFileStream;
begin
  F := TFileStream.Create(FileName, $0000 or $0001);
  try
    LoadFromStream(F);
  finally
    F.Free;
  end;
end;

procedure TStream.LoadFromStream(aStream: TStream);
begin
  CopyFrom(aStream, 0);
end;

procedure TStream.ReadBuffer(var Buffer; Count: integer);
begin
  Read(Buffer, Count);
end;

function TFileStream.Read(var Buffer; Count: integer): integer;
begin
  if (fHandle = 0) then
    Result := 0 else
  if not ReadFile(Handle, Buffer, Count, longword(Result), nil) then
    Result := 0;
end;


function TFileStream.Seek(Offset: integer; Origin: word): integer;
begin
  if (fHandle = 0) then
    Result := 0 else
    Result := SetFilePointer(fHandle, Offset, nil, Origin);
end;

function TFileStream.Seek(Offset: int64; Origin: TSeekOrigin): int64;
begin
  if (fHandle = 0) then
    Result := 0 else
    Result := SetFilePointer(fHandle, Offset, nil, Ord(Origin));
end;

procedure TFileStream.SetSize(Value: integer);
begin
  Seek(Value, soFromBeginning);
end;

function TFileStream.Write(var Buffer; Count: integer): integer;
begin
  if (fHandle=0) or (Count<=0) then
    result := 0 else
    result := FileWrite(fHandle, Buffer, Count);
end;

constructor TFileStream.Create(const FileName: string; Mode: word);
begin
  fFileName := FileName;
  if Mode = fmCreate then
    fHandle := FileCreate(FileName) else
    fHandle := FileOpen(FileName, Mode);
  if fHandle = LongWord(-1) then fHandle := 0;
end;

destructor TFileStream.Destroy;
begin
  CloseHandle(fHandle);
  inherited;
end;

function TResourceStream.GetPosition(): integer;
begin
  Result := fPosition;
end;

function TResourceStream.GetSize(): integer;
begin
  Result := fSize;
end;

function TResourceStream.Read(var Buffer; Count: integer): integer;
begin
  if Memory <> nil then
    if (FPosition >= 0) and (Count > 0) then
    begin
      Result := FSize - FPosition;
      if Result > 0 then
      begin
        if Result > Count then Result := Count;
        Move((PAnsiChar(Memory) + FPosition)^, Buffer, Result);
        Inc(FPosition, Result);
        Exit;
      end;
    end;
  Result := 0;
end;

function TResourceStream.Seek(Offset: integer; Origin: word): integer;
begin
  Result := Offset;
  case Origin of
    soFromEnd: Inc(Result, fSize);
    soFromCurrent: Inc(Result, fPosition);
  end;
  if Result <= fSize then
    fPosition := Result else
  begin
    Result := fSize;
    fPosition := fSize;
  end;
end;

procedure TResourceStream.SetPointer(Buffer: pointer; Count: integer);
begin
  fMemory := Buffer;
  fSize := Count;
end;

procedure TResourceStream.SetPosition(Value: integer);
begin
  if Value > fSize then
    Value := fSize;
  fPosition := Value;
end;

procedure TResourceStream.SetSize(Value: integer);
begin
  fSize := Value;
end;

function FindResource(hModule: longword; lpName, lpType: PChar): longword;
var aName,aType: Ansistring;
var lpaName, lpaType: PChar;

begin
  if (longword(lpName) shr 16) <> 0 then
  begin
    aName := AnsiString(lpName);
    lpaName := @aName[1];
  end
  else
    lpaName := PChar(lpName);
  if (longword(lpType) shr 16) <> 0 then
  begin
   aType := AnsiString(lpType);
    lpaType := @aType[1];
  end
  else
    lpaType := PChar(lpType);
  Result := FindResourceA(hModule, lpaName, lpaType);
end;

constructor TResourceStream.Create(Instance: longword; const ResName: string; ResType: PChar);
var HResInfo: longword;
  HGlobal: longword;
  ansiresname:ansistring;
begin
  ansiresname:=ansistring(resname);
  HResInfo := FindResource(Instance, @AnsiResName[1], PChar(ResType));
  if HResInfo = 0 then
    exit;
  HGlobal := LoadResource(HInstance, HResInfo);
  if HGlobal = 0 then
    exit;
  SetPointer(LockResource(HGlobal), SizeOfResource(Instance, HResInfo));
  FPosition := 0;
end;


end.
