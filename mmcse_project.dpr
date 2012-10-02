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
  Forms,
  ExceptionTracer,
  UCustomThread,
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
  M2100Switcher,
  M2100MessageEncoder,
  mmcse_MainWindow,
  mmcse_PipeConnector in 'mmcse_PipeConnector.pas';

type
  TApplication = class
  public
    constructor Create;
  protected
    fLog: TCustomLog;
    fLogManager: TCustomLogManager;
    fMainForm: TEmulatorMainForm;
    fInitializeThread: TCustomThread;
    fSwitcher: TM2100Switcher;
    procedure InitializeLog;
    procedure ActualRun;
    procedure SafeRun;
    procedure InitializeSwitcher;
    procedure FinalizeLog;
  public
    property Log: TCustomLog read fLog;
    property LogManager: TCustomLogManager read fLogManager;
    property MainForm: TEmulatorMainForm read fMainForm;
    property InitializeThread: TCustomThread read fInitializeThread;
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
  consoleLogWriter := TConsoleLogWriter.Create;
  LogManager.AddWriter(consoleLogWriter);
  GlobalLogManager := LogManager;
  fLog := TLog.Create(LogManager, 'APP');
end;

procedure TApplication.InitializeSwitcher;
begin
  Log.Write('Now initializing switcher...');
  fSwitcher := TM2100Switcher.Create;
  {fPipe := T2MPipe.Create('\\.\pipe\nVisionMCS');
  Switcher.ReceiveMessage := Pipe.RequestReceiveMessage;
  Switcher.SendResponse := Pipe.SendResponse;
  Switcher.Log := TLog.Create(LogManager, 'Switcher');
  }
end;

{
procedure TApplication.InitializeSwitcher;
}

procedure TApplication.ActualRun;
var
  mainForm: TEmulatorMainForm;
begin
  InitializeLog;
  Log.Write('-->', 'Now initializing application...');
  Application.Initialize;
  Application.CreateForm(TEmulatorMainForm, mainForm);
  Log.Write('>>>', 'Now running application...');
  Application.Run;
  Log.Write('|||', 'Now finalizing application...');
  mainForm.Free;
  FinalizeLog;
  {
  InitializeSwitcher;
  Switcher.Thread.Resume;
  Pipe.WaitForClient;
  Switcher.Thread.WaitFor;
  }
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

procedure TApplication.FinalizeLog;
begin
  Log.Write('Now finalizing log...');
  FreeAndNil(fLog);
  GlobalLogManager := nil;
  FreeAndNil(fLogManager);
end;

procedure TApplication.Run;
begin
  SafeRun;
end;

destructor TApplication.Destroy;
begin
  inherited;
end;

var
  application: TApplication;

begin
  try
    application := TApplication.Create;
    application.Run;
    application.Free;
  except
    on e: Exception do
    begin
      WriteLN('GLOBAL EXCEPTION');
      WriteLN(GetExceptionInfo(e));
    end;
  end;
end.






