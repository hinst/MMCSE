program mmcse_project;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  WindowsPipes,
  M2Pipe,

  CustomLogManager,
  PlainLogManager,
  CustomLogEntity,
  DefaultLogEntity,
  CustomLogWriter,
  ConsoleLogWriter,
  
  StreamVisualizer,
  M2100MessageDecoder,
  M2100PipeThreader,
  ExceptionTracer,
  mmcse_common,
  M2100Command,
  M2100Message,
  M2100Switcher;

type
  TApplication = class
  public
    constructor Create;
  private
    fLog: TCustomLog;
    fLogManager: TCustomLogManager;
    fThread: TM2100PipeThread;
    procedure InitializeLog;
    procedure ActualRun;
    procedure SafeRun;
  public
    property Log: TCustomLog read fLog;
    property LogManager: TCustomLogManager read fLogManager;
    property Thread: TM2100PipeThread read fThread;
    procedure Run;
    destructor Destroy; override;
  end;

procedure WriteLine(const aText: PChar); safecall;
begin
  WriteLN(string(aText));
end;

procedure TApplication.ActualRun;
begin
  fThread := TM2100PipeThread.Create;
  Thread.Log := TLog.Create(LogManager, 'PT');
  Thread.Resume;
  Thread.WaitFor;
end;

constructor TApplication.Create;
begin
  inherited Create;
  InitializeLog;
end;

procedure TApplication.InitializeLog;
var
  consoleLogWriter: TCustomLogWriter;
begin
  fLogManager := TPlainLogManager.Create;
  GlobalLogManager := LogManager;
  fLog := TLog.Create(LogManager, 'APP');
  consoleLogWriter := TConsoleLogWriter.Create;
  LogManager.AddWriter(consoleLogWriter);
end;

procedure TApplication.Run;
begin
  Log.Write('Now running application...');
  SafeRun;
  Log.Write('Now ending application...');
end;

procedure TApplication.SafeRun;
begin
  try
    ActualRun;
  except
    on e: Exception do
    begin
      WriteLN('Exception: ' + e.ClassName);
      WriteLN('Exc.messg: "' + e.Message + '"');
    end;
  end;
end;

destructor TApplication.Destroy;
begin
  GlobalLogManager := nil;
  inherited;
end;

var
  application: TApplication;

begin
  application := TApplication.Create;
  application.Run;
  application.Free;
end.
