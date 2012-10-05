unit mmcse_PipeConnector;

interface

uses
  SysUtils,
  Classes,

  UCustomThread,

  CustomLogEntity,
  EmptyLogEntity,

  M2Pipe;

type
  TEmulationPipeConnector = class
  public
    constructor Create;
  protected
    fLog: TCustomLog;
    fThread: TCustomThread;
    fPipe: T2MPipe;
    procedure SetLog(const aLog: TCustomLog);
    procedure Routine(const aThread: TCustomThread);
  public
    property Log: TCustomLog read fLog write SetLog;
    property Thread: TCustomThread read fThread;
    property Pipe: T2MPipe read fPipe;
    procedure Startup(const aPipeName: string);
    destructor Destroy; override;
  end;


implementation

constructor TEmulationPipeConnector.Create;
begin
  inherited Create;
  Log := nil;
end;

procedure TEmulationPipeConnector.Routine(const aThread: TCustomThread);
begin
  Log.Write('Now starting emulator pipe connector thread...');
  Pipe.WaitForClient(10000);
end;

procedure TEmulationPipeConnector.SetLog(const aLog: TCustomLog);
begin
  FreeAndNil(fLog);
  if aLog = nil then
    fLog := TEmptyLog.Create
  else
    fLog := aLog;
end;

procedure TEmulationPipeConnector.Startup(const aPipeName: string);
begin
  Log.Write('Now creating pipe "' + aPipeName + '"...');
  fPipe := T2MPipe.Create(aPipeName);
  Log.Write('Now starting up pipe "' + aPipeName + '"...');
  Pipe.Startup;
  Log.Write('Now starting up wait-for-conneciton thread; pipe "' + aPipeName + '"...');
    
  fThread := TCustomThread.Create;
  Thread.OnExecute := Routine;
  Thread.Resume;
end;

destructor TEmulationPipeConnector.Destroy;
begin
  if Assigned(Thread) then
  begin
    Thread.WaitFor;
    Thread.Free;
  end;
  inherited Destroy;
end;

end.
