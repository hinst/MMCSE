unit M2100PipeThreader;

interface

uses
  SysUtils,
  Classes,

  NoLogEntityWrapper,
  LogEntityFace,

  ExceptionTracer,
  StreamVisualizer,

  M2Pipe,
  M2100Message,
  M2100MessageDecoder;

type
  TM2100PipeThread = class(TThread)
  public
    constructor Create; reintroduce;
  protected
    fLog: ILogEntity;
    procedure PerformExecution;
    procedure Execute; override;
  public
    property Log: ILogEntity read fLog write fLog;
  end;

implementation

constructor TM2100PipeThread.Create;
begin
  inherited Create(true);
  fLog := TNoLog.Create;
end;

procedure TM2100PipeThread.Execute;
begin
  try
    PerformExecution;
  except
    on e: Exception do
    begin
      WriteLN('TM2100PipeThread.Execute exception');
      Log.Write('ERROR', 'An error occured while executing M-2100 pipe thread...');
      Log.Write(GetExceptionInfo(e));
    end;
  end;
  WriteLN('TM2100PipeThread: execution end.');
end;

procedure TM2100PipeThread.PerformExecution;
var
  pipe: T2MPipe;
  memoryStream: TMemoryStream;
  m: TM2100Message;
begin
  Log.Write('Now creating pipe...');
  pipe := T2MPipe.Create('\\.\pipe\nVisionMCS');
  Log.Write('Now waiting for client...');
  pipe.WaitForClient;
  repeat
    memoryStream := pipe.Read;
    Rewind(memoryStream);
    WriteLN('Stream received: ' + ToText(memoryStream));
    Rewind(memoryStream);
    m := TM2100MessageDecoder.Decode(memoryStream);
    Log.Write('Message decoded: ' + m.ToText);
    m.Free;
    memoryStream.Free;
  until false;
  pipe.Free;
end;

end.
