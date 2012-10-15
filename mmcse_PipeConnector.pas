unit mmcse_PipeConnector;

interface

uses
  SysUtils,
  Classes,

  UCustomThread,
  UAdditionalExceptions,
  ExceptionTracer,

  CustomLogEntity,
  EmptyLogEntity,

  M2Pipe;

type
  TEmulationPipeConnector = class
  public
    constructor Create;
  public const
    DefaultWaitInterval = 10; //s
  protected
    fLog: TEmptyLog;
    fPipeName: string;
    fPipe: T2MPipe;
    fThread: TCustomThread;
    fOnConnected: TNotifyEvent;
    procedure SetLog(const aLog: TEmptyLog);
    procedure Routine(const aThread: TCustomThread);
    function ConnectRoutine(const aThread: TCustomThread): boolean;
    function ReceiveRoutine(const aThread: TCustomThread): boolean;
  public
    property Log: TEmptyLog read fLog write SetLog;
      // assign before Startup
    property PipeName: string read fPipeName write fPipeName;
    property Pipe: T2MPipe read fPipe;
    property Thread: TCustomThread read fThread;
    property OnConnected: TNotifyEvent read fOnConnected write fOnConnected;
    procedure Startup;
    destructor Destroy; override;
  end;


implementation

constructor TEmulationPipeConnector.Create;
begin
  inherited Create;
  Log := nil;
end;

function TEmulationPipeConnector.ReceiveRoutine(const aThread: TCustomThread): boolean;
begin

end;

procedure TEmulationPipeConnector.Routine(const aThread: TCustomThread);
var
  result: boolean;
begin
  result := ConnectRoutine(aThread);
  if not result then
    exit;
end;

function TEmulationPipeConnector.ConnectRoutine(const aThread: TCustomThread): boolean;
var
  waitForClientResult: boolean;
  timeSpent: integer;
begin
  waitForClientResult := false;
  Log.Write('Now waiting for client...');
  try
    timeSpent := 0;
    while (timeSpent < DefaultWaitInterval) and (not aThread.Stop) do
      waitForClientResult := Pipe.WaitForClient(1000);
  except
    on e: Exception do
    begin
      Log.Write('ERROR', 'Unsuccessful.' + sLineBreak + GetExceptionInfo(e));
      AssertSuppressable(e);
    end;
  end;
  Log.Write('Wait for client: result: ' + BoolToStr(waitForClientResult, true));
  if waitForClientResult then
    if Assigned(OnConnected) then
      OnConnected(self);
end;

procedure TEmulationPipeConnector.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(fLog, aLog);
end;

procedure TEmulationPipeConnector.Startup;
begin
  Log.Write('Now creating pipe "' + PipeName + '"...');
  fPipe := T2MPipe.Create(PipeName);
  
  Log.Write('Now starting up wait-for-conneciton thread; pipe "' + PipeName + '"...');
  fThread := TCustomThread.Create;
  Thread.OnExecute := Routine;
  Thread.Resume;
end;

destructor TEmulationPipeConnector.Destroy;
begin
  if Thread <> nil then
  begin
    Thread.Stop := true;
    Thread.WaitFor;
    FreeAndNil(fThread);
  end;
  if Pipe <> nil then
    FreeAndNil(fPipe);
  if Log <> nil then
    FreeAndNil(fLog);
  inherited Destroy;
end;

end.
