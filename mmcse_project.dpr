program mmcse_project;

{$APPTYPE CONSOLE}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  SysUtils,
  Classes,

  CustomLogManager,
  PlainLogManager,
  CustomLogEntity,
  DefaultLogEntity,
  CustomLogWriter,
  ConsoleLogWriter,
  
  M2Pipe,
  M2100MessageDecoder,
  M2100PipeThreader,
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
    fPipe: T2MPipe;
    fSwitcher: TM2100Switcher;
    procedure InitializeLog;
    procedure InitializeSwitcher;
    procedure ActualRun;
    procedure SafeRun;
  public
    property Log: TCustomLog read fLog;
    property LogManager: TCustomLogManager read fLogManager;
    property Pipe: T2MPipe read fPipe;
    property Switcher: TM2100Switcher read fSwitcher;
    procedure Run;
    destructor Destroy; override;
  end;

procedure WriteLine(const aText: PChar); safecall;
begin
  WriteLN(string(aText));
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

procedure TApplication.InitializeSwitcher;
begin
  Log.Write('Now initializing switcher...');
  fSwitcher := TM2100Switcher.Create;
  fPipe := T2MPipe.Create('\\.\pipe\nVisionMCS');
  Switcher.ReceiveMessage := Pipe.RequestReceiveMessage;
  Switcher.Log := TLog.Create(LogManager, 'Switcher');
end;

procedure TApplication.ActualRun;
begin
  InitializeSwitcher;
  Switcher.Thread.Resume;
  Pipe.WaitForClient;
  Switcher.Thread.WaitFor;
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

procedure TApplication.Run;
begin
  Log.Write('Now running application...');
  SafeRun;
  Log.Write('Now ending application...');
end;

destructor TApplication.Destroy;
begin
  Log.Write('Now destroying application...');
  FreeAndNil(fSwitcher);
  FreeAndNil(fPipe);
  FreeAndNil(fLog);
  FreeAndNil(GlobalLogManager);
  inherited;
end;

var
  application: TApplication;

begin
  application := TApplication.Create;
  application.Run;
  application.Free;
end.
