unit MessageBiDirectionalPipeUnit;

interface

uses
  Windows,
  Classes,
  SysUtils,

  EmptyLogEntity,

  UWindowsPipes,
  UWindowsOverlappedEvent;

const
  T2MPIPE_BUFFER_SIZE = 4096;

type
  TM2PipeReadRetry = class
  public
    constructor Create(const aPipe: THandle);
  private
    fLog: TEmptyLog;
    fPipe: THandle;
    fEvent: TWindowsOverlappedEvent;
    fBuffer: array[0..T2MPIPE_BUFFER_SIZE] of byte;
    procedure SetLog(const aLog: TEmptyLog);
  public
    property Log: TEmptyLog read fLog write SetLog;
    property Pipe: THandle read fPipe;
    property Event: TWindowsOverlappedEvent read fEvent;
    function Read(const aTime: DWORD): TStream;
    destructor Destroy; override;
  end;

  TM2PipeConnectRetry = class
  public
    constructor Create(const aPipe: THandle);
  private
    fPipe: THandle;
    fEvent: TWindowsOverlappedEvent;
  public
    property Pipe: THandle read fPipe;
    property Event: TWindowsOverlappedEvent read fEvent;
    function Connect(const aTime: DWORD): boolean;
    destructor Destroy; override;
  end;

type
  T2MPipe = class(TCommonPipe)
  public
    constructor Create(const aName: string);
  protected
    class function GetPipeMode: DWORD; inline;
    function IsDataAvailable: boolean;
    procedure CreateWindowsPipe;
  public
    property PipeMode: DWORD read GetPipeMode;
    property DataAvailable: boolean read IsDataAvailable;
    function Connect: TM2PipeConnectRetry;
    function ReadMessage: TM2PipeReadRetry;
    function ReadMessageIfAny: TStream;
    procedure SendMessage(const aStream: TStream);
    destructor Destroy; override;
  end;

const
  T2MPIPE_MAX_PIPE_INSTANCE_COUNT = 3;


implementation

constructor TM2PipeReadRetry.Create(const aPipe: THandle);
begin
  inherited Create;
  fLog := TEmptyLog.Create;
  fPipe := aPipe;
end;

procedure TM2PipeReadRetry.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(fLog, aLog);
end;

function TM2PipeReadRetry.Read(const aTime: DWORD): TStream;
var
  readResult: boolean;
  waitResult: boolean;
  lastError: DWORD;
  NumberOfBytesRead: DWORD;
begin
  result := nil;
  readResult := false;
  waitResult := false;
  if Event = nil then
  begin
    fEvent := TWindowsOverlappedEvent.Create;
    readResult := ReadFile(
      Pipe,
      fBuffer,
      T2MPIPE_BUFFER_SIZE,
      NumberOfBytesRead,
      event.Overlapped
    );
    if not readResult then // still pending
    begin
      lastError := GetLastError;
      if lastError <> ERROR_IO_PENDING then // not read && not pending == failure
        raise ECannotReadPipe.Create('Could not read');
    end;
  end;
  if not readResult then
    waitResult := Event.Wait(aTime);
  if waitResult then
    GetOverlappedResult(Pipe, event.Overlapped^, NumberOfBytesRead, false);  
  if (waitResult or readResult) and (NumberOfBytesRead > 0) then
  begin
    result := TMemoryStream.Create;
    result.Write(fBuffer, NumberOfBytesRead);
    FreeAndNil(fEvent);
  end;
end;

destructor TM2PipeReadRetry.Destroy;
begin
  FreeAndNil(fEvent);
  FreeAndNil(fLog);
  inherited Destroy;
end;


constructor TM2PipeConnectRetry.Create(const aPipe: THandle);
begin
  inherited Create;
  fPipe := aPipe;
end;

function TM2PipeConnectRetry.Connect(const aTime: DWORD): boolean;
var
  lastError: DWORD;
  connectNamedPipeResult: BOOL;
begin
  result := false;
  if fEvent = nil then
  begin
    fEvent := TWindowsOverlappedEvent.Create;
    connectNamedPipeResult := ConnectNamedPipe(Pipe, event.Overlapped);
    if not connectNamedPipeResult then // pending or failed
    begin
      lastError := GetLastError;
      if not ((lastError = ERROR_IO_PENDING) or (lastError = ERROR_PIPE_CONNECTED)) then // failed
        raise ECannotConnectPipe.Create('Error code is ' + IntToStr(lastError));
      if (lastError = ERROR_PIPE_CONNECTED) then // already connected before Connect... call
        result := true;
    end;
  end;
  if not result then
    result := event.Wait(aTime);
end;

destructor TM2PipeConnectRetry.Destroy;
begin
  FreeAndNil(fEvent);
  inherited Destroy;
end;


constructor T2MPipe.Create(const aName: string);
begin
  inherited Create(aName);
  CreateWindowsPipe;
end;

class function T2MPipe.GetPipeMode: DWORD;
begin
  result := PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or PIPE_WAIT;
end;

function T2MPipe.IsDataAvailable: boolean;
var
  totalAvailable: DWORD;
  messageAvailable: DWORD;
begin
  if not PipeOpened then
  begin
    result := false;
    exit;
  end;
  PeekNamedPipe(Pipe, nil, T2MPIPE_MAX_PIPE_INSTANCE_COUNT,
    nil, @totalAvailable, @messageAvailable);
  result := totalAvailable <> 0;
end;

procedure T2MPipe.CreateWindowsPipe;
begin
  fPipe := CreateNamedPipeA(
    PAnsiChar(Name),
    PIPE_ACCESS_DUPLEX or FILE_FLAG_OVERLAPPED,
    GetPipeMode,
    T2MPIPE_MAX_PIPE_INSTANCE_COUNT,
    T2MPIPE_BUFFER_SIZE, T2MPIPE_BUFFER_SIZE,
    NMPWAIT_USE_DEFAULT_WAIT,
    PSecurityAttributes(nil)
  );
  if Pipe = INVALID_HANDLE_VALUE then
    raise ECannotCreatePipe.Create('Invalid handle returned');
end;

function T2MPipe.Connect: TM2PipeConnectRetry;
begin
  AssertPipeOpened;
  result := TM2PipeConnectRetry.Create(Pipe);
end;

function T2MPipe.ReadMessage: TM2PipeReadRetry;
begin
  AssertPipeOpened;
  result := TM2PipeReadRetry.Create(Pipe);
end;

function T2MPipe.ReadMessageIfAny: TStream;
begin
  result := nil;
  if DataAvailable then
    //result := ReadMessage;
end;

procedure T2MPipe.SendMessage(const aStream: TStream);
var
  writeResult: boolean;
  buffer: array[0..T2MPIPE_BUFFER_SIZE] of byte;
  size: DWORD;
  resultSize: DWORD;
begin
  AssertPipeOpened;
  size := aStream.Size;
  aStream.ReadBuffer(buffer, size);
  writeResult := WriteFile(Pipe, buffer, size, resultSize, nil);
  if not writeResult then
    raise ECannotWritePipe.Create('Can not write pipe: ' + IntToStr(Pipe));
end;

destructor T2MPipe.Destroy;
begin
  inherited Destroy; 
end;

end.
