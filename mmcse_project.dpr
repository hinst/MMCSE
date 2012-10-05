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
  CustomLogManager,
  PlainLogManager,
  CustomLogEntity,
  DefaultLogEntity,
  CustomLogWriter,
  ConsoleLogWriter,
  mmcse_common in 'mmcse_common.pas',
  mmcse_MainWindow in 'mmcse_MainWindow.pas',
  M2100Switcher in 'M2100Switcher.pas';

type
  TApplication = class
  public
    constructor Create;
  protected
    fLog: TCustomLog;
    fLogManager: TCustomLogManager;
    fMainForm: TEmulatorMainForm;
    procedure InitializeLog;
    procedure ActualRun;
    procedure SafeRun;
    procedure InitializeSwitcher;
    procedure FinalizeLog;
  public
    property Log: TCustomLog read fLog;
    property LogManager: TCustomLogManager read fLogManager;
    property MainForm: TEmulatorMainForm read fMainForm;
    procedure Run;
    destructor Destroy; override;
  end;

const
  DefaultPipeName = '\\.\pipe\nVisionMCS';

procedure WriteLine(const aText: PChar); safecall;
begin
  WriteLN(string(aText));
end;

constructor TApplication.Create;
begin
  inherited Create;
end;

procedure TApplication.InitializeLog;
var
  consoleLogWriter: TCustomLogWriter;
begin
  fLogManager := TPlainLogManager.Create;
  consoleLogWriter := TConsoleLogWriter.Create;
  LogManager.AddWriter(consoleLogWriter);
  GlobalLogManager := LogManager;
  fLog := TLog.Create(LogManager, 'Application');
end;

procedure TApplication.InitializeSwitcher;
begin
end;

procedure TApplication.ActualRun;
begin
  InitializeLog;
  Log.Write('-->', 'Now initializing application...');
  Application.Initialize;
  Application.MainFormOnTaskBar := true;
  Application.CreateForm(TEmulatorMainForm, fMainForm);
  Log.Write('>>>', 'Now running application...');
  Log.Write('ffffffffffffffffffffffffffffff fffffffffffffffffffffffffffffffffffffffffffffff  ffffffffffffffffffffffffffffffffffff fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ffffffffffffffffff'
   + 'fffffffffffffffffffffffffffffffffffffffffffff  ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ffffffffffffffffffffffffffff' + sLineBreak
   + 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaa');
   
  Application.Run;
  Log.Write('|||', 'Now finalizing application...');
  FreeAndNil(fMainForm);
  FinalizeLog;
end;

procedure TApplication.SafeRun;
begin
  try
    ActualRun;
  except
    on e: Exception do
    begin
      if IsConsole then
      begin
        WriteLN('Exception occured: Application.ActualRun');
        WriteLN(GetExceptionInfo(e));
      end;
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
  inherited Destroy;
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
      if IsConsole then
      begin
        WriteLN('GLOBAL EXCEPTION');
        WriteLN(GetExceptionInfo(e));
      end;
    end;
  end;
end.






