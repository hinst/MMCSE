unit M2Pipe;

interface

uses
  Windows,
  Classes,
  SysUtils,

  WindowsPipes;

type
  T2MPipe = class(TCommonPipe)
  public
    constructor Create(const aName: string);
  protected
    fConnected: boolean;
    class function GetPipeMode: DWORD; inline;
    function IsDataAvailable: boolean;
    procedure CreateWindowsPipe;
  public
    property Connected: boolean read fConnected;
    property PipeMode: DWORD read GetPipeMode;
    property DataAvailable: boolean read IsDataAvailable;

    function WaitForClient(const aTime: DWORD): boolean;
    function ReadMessage(const aTime: DWORD): TStream;
    function ReadMessageIfAny: TStream;
    procedure SendMessage(const aStream: TStream);
    destructor Destroy; override;
  end;

const
  T2MPIPE_BUFFER_SIZE = 4096;
  T2MPIPE_MAX_PIPE_INSTANCE_COUNT = 3;


implementation

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
  if (not PipeOpened) or (not Connected) then
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

function T2MPipe.WaitForClient(const aTime: DWORD): boolean;
var
  event: TWindowsOverlappedEvent;
  lastError: DWORD;
  connectResult: BOOL;
begin
  AssertPipeOpened;
  event := TWindowsOverlappedEvent.Create;
  try
    connectResult := ConnectNamedPipe(Pipe, event.Overlapped);
    if false = connectResult then
    begin
      lastError := GetLastError;
      if (lastError <> ERROR_IO_PENDING) and (lastError <> ERROR_PIPE_CONNECTED) then
        raise ECannotConnectPipe.Create('Error code is ' + IntToStr(lastError));
      result := event.Wait(aTime);
    end;
  finally
    event.Free;
  end;
  fConnected := result;
end;

function T2MPipe.ReadMessage(const aTime: DWORD): TStream;
var
  waitResult: boolean;
  event: TWindowsOverlappedEvent;
  buffer: array[0..T2MPIPE_BUFFER_SIZE] of byte;
  size: DWORD;
begin
  result := nil;
  AssertPipeOpened;
  event := TWindowsOverlappedEvent.Create;
  try
    ReadFile(Pipe, buffer, T2MPIPE_BUFFER_SIZE, size, event.Overlapped);
    waitResult := event.Wait(aTime);
  finally
    event.Free;
  end;
  if not waitResult then
    raise ECannotReadPipe.Create('');
  result := TMemoryStream.Create;
  result.Write(buffer, size);
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
  if PipeOpened then
    CloseHandle(Pipe);
  inherited Destroy; 
end;

end.
