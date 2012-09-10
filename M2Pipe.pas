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
    procedure Initialize;
  public
    property PipeMode: DWORD read GetPipeMode;
    procedure WaitForClient;
    function Read: TMemoryStream;
  end;

const
  T2MPIPE_BUFFER_SIZE = 4096;


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

procedure T2MPipe.Initialize;
begin
  fPipe := CreateNamedPipeA(PAnsiChar(Name),
    PIPE_ACCESS_DUPLEX,
    GetPipeMode,
    3,
    T2MPIPE_BUFFER_SIZE, T2MPIPE_BUFFER_SIZE,
    NMPWAIT_USE_DEFAULT_WAIT,
    PSecurityAttributes(nil)
  );
  if Pipe = INVALID_HANDLE_VALUE then
    raise ECannotCreatePipe.Create('');
end;

procedure T2MPipe.WaitForClient;
var
  waitResult: boolean;
begin
  AssertPipeCreated;
  waitResult := ConnectNamedPipe(Pipe, nil);
  if not waitResult then
    raise EConnectionFailure.Create('');
end;

function T2MPipe.Read: TMemoryStream;
var
  buffer: array[0..T2MPIPE_BUFFER_SIZE] of byte;
  size: DWORD;
  readResult: boolean;
begin
  AssertPipeCreated;
  readResult := ReadFile(Pipe, buffer, T2MPIPE_BUFFER_SIZE, size, nil);
  if not readResult then
    raise ECannotReadPipe.Create('');
  result := TMemoryStream.Create;
  result.Write(buffer, size);
end;

end.
