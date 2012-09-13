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
    class function GetPipeMode: DWORD; inline;
    function IsDataAvailable: boolean;
    procedure Initialize;
  public
    property PipeMode: DWORD read GetPipeMode;
    property DataAvailable: boolean read IsDataAvailable;
    procedure WaitForClient;
    function Read: TMemoryStream;

    function RequestReceiveMessage: TStream;
  end;

const
  T2MPIPE_BUFFER_SIZE = 4096;
  T2MPIPE_MAX_PIPE_INSTANCE_COUNT = 3;


implementation

constructor T2MPipe.Create(const aName: string);
begin
  inherited Create(aName);
  Initialize;
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

procedure T2MPipe.Initialize;
begin
  fPipe := CreateNamedPipeA(PAnsiChar(Name),
    PIPE_ACCESS_DUPLEX,
    GetPipeMode,
    T2MPIPE_MAX_PIPE_INSTANCE_COUNT,
    T2MPIPE_BUFFER_SIZE, T2MPIPE_BUFFER_SIZE,
    NMPWAIT_USE_DEFAULT_WAIT,
    PSecurityAttributes(nil)
  );
  if Pipe = INVALID_HANDLE_VALUE then
    raise ECannotCreatePipe.Create('');
end;

procedure T2MPipe.WaitForClient;
var
  waitResult: BOOL;
begin
  AssertPipeOpened;
  waitResult := ConnectNamedPipe(Pipe, nil);
  if not waitResult then
    raise EConnectionFailure.Create('');
end;

function T2MPipe.Read: TMemoryStream;
var
  readResult: boolean;
  buffer: array[0..T2MPIPE_BUFFER_SIZE] of byte;
  size: DWORD;
begin
  AssertPipeOpened;
  readResult := ReadFile(Pipe, buffer, T2MPIPE_BUFFER_SIZE, size, nil);
  if not readResult then
    raise ECannotReadPipe.Create('');
  result := TMemoryStream.Create;
  result.Write(buffer, size);
end;

function T2MPipe.RequestReceiveMessage: TStream;
begin
  result := nil;
  if DataAvailable then
    result := Read;
end;

end.
