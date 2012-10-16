unit mmcse_PipeConnector;

interface

uses
  SysUtils,
  Classes,

  UCustomThread,
  UAdditionalExceptions,
  ExceptionTracer,
  UStreamUtilities,

  CustomLogEntity,
  EmptyLogEntity,

  M2Pipe;

type
  TEmulationPipeConnector = class
  public
    constructor Create;
  public const
    DefaultWaitForConnectionInterval = 30 * 1000; // thirty seconds
    DefaultShutdownResponsiveness = 1000;
  public type
    THandleIncomingMessageMethod = procedure(const aStream: TStream) of object;  
  protected
    fLog: TEmptyLog;
    fPipeName: string;
    fPipe: T2MPipe;
    fThread: TCustomThread;
    fOnConnected: TNotifyEvent;
    fOnIncomingMessage: THandleIncomingMessageMethod;
    procedure SetLog(const aLog: TEmptyLog);
    procedure Routine(const aThread: TCustomThread);
    function ConnectRoutine(const aThread: TCustomThread): boolean;
    procedure ReceiveRoutine(const aThread: TCustomThread);
  public
    property Log: TEmptyLog read fLog write SetLog;
      // assign before Startup
    property PipeName: string read fPipeName write fPipeName;
    property Pipe: T2MPipe read fPipe;
    property Thread: TCustomThread read fThread;
    property OnConnected: TNotifyEvent read fOnConnected write fOnConnected;
    property OnIncomingMessage: THandleIncomingMessageMethod 
      read fOnIncomingMessage write fOnIncomingMessage;
    procedure Startup;
    procedure SendMessage(const aStream: TStream);
    destructor Destroy; override;
  end;


implementation

constructor TEmulationPipeConnector.Create;
begin
  inherited Create;
  Log := nil;
end;

procedure TEmulationPipeConnector.Routine(const aThread: TCustomThread);
var
  result: boolean;
begin
  result := ConnectRoutine(aThread);
  if not result then
    exit;
  ReceiveRoutine(aThread);
end;

function TEmulationPipeConnector.ConnectRoutine(const aThread: TCustomThread): boolean;
var
  timeSpent: integer;
  logText: string;
  connect: TM2PipeConnectRetry;
begin
  result := false;
  Log.Write('Now connecting pipe "' + Pipe.Name + '"...');
  try
    connect := nil;
    try
      timeSpent := 0;
      connect := Pipe.Connect;
      while (timeSpent <= DefaultWaitForConnectionInterval) and (not aThread.Stop) 
        and (not result)
      do
      begin
        result := connect.Connect(DefaultShutdownResponsiveness);
        timeSpent := timeSpent + DefaultShutdownResponsiveness;
      end;
    finally
      connect.Free;
    end;
  except
    on e: Exception do
    begin
      Log.Write('ERROR', 'Connect: unsuccessful.' + sLineBreak + GetExceptionInfo(e));
      AssertSuppressable(e);
      exit;
    end;
  end;
  logText := 'Wait for connection: result: ' + BoolToStr(result, true);
  logText := 
    logText + sLineBreak + 'Have been waiting for: ' + FormatFloat('0.000', timeSpent / 1000) + '.';
  if timeSpent >= DefaultWaitForConnectionInterval then
    logText := logText + ' Timed out.';
  Log.Write(logText);
  if result then
    if @OnConnected <> nil then
      OnConnected(self);
end;

procedure TEmulationPipeConnector.ReceiveRoutine(const aThread: TCustomThread);
var
  incomingMessage: TStream;
  reader: TM2PipeReadRetry;
begin
  reader := Pipe.ReadMessage;
  while false = aThread.Stop do
  begin
    incomingMessage := nil;
    try
      incomingMessage := reader.Read(DefaultShutdownResponsiveness);
    except
      on e: Exception do
      begin
        Log.Write('ERROR', 'Read pipe: unsuccessful.' + sLineBreak
          + GetExceptionInfo(e));
        AssertSuppressable(e);
      end;
    end;
    if incomingMessage <> nil then
      if @OnIncomingMessage <> nil then
      begin
        StreamRewind(incomingMessage);
        OnIncomingMessage(incomingMessage);
      end;
  end;
  reader.Free;
end;

procedure TEmulationPipeConnector.SendMessage(const aStream: TStream);
begin
  Pipe.SendMessage(aStream);
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
