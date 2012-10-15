unit mmcse_project_ApplicationClass;

interface

uses
  SysUtils,
  Forms,

  ExceptionTracer,

  CustomLogManager,
  PlainLogManager,
  CustomLogEntity,
  DefaultLogEntity,
  CustomLogWriter,
  ConsoleLogWriter,

  mmcse_common,
  mmcse_MainWindow,
  mmcse_PipeConnector,
  M2100Switcher;

type
  TMMCSEApplication = class
  public
    constructor Create;
  protected
    fLog: TCustomLog;
    fLogManager: TCustomLogManager;
    fMainForm: TEmulatorMainForm;
    fPipeConnector: TEmulationPipeConnector;
    fSwitcher: TM2100Switcher;
    procedure InitializeLog;
    procedure ActualRun;
    procedure SafeRun;
    procedure InitializeMainForm;
    procedure UserConnect(aSender: TObject);
    procedure OnConnectedHandler(aSender: TObject);
    procedure FinalizeLog;
  public
    property Log: TCustomLog read fLog;
    property LogManager: TCustomLogManager read fLogManager;
    property MainForm: TEmulatorMainForm read fMainForm;
    property PipeConnector: TEmulationPipeConnector read fPipeConnector;
    property Switcher: TM2100Switcher read fSwitcher;
    procedure Run;
    destructor Destroy; override;
  end;

const
  DefaultPipeName = '\\.\pipe\nVisionMCS';
  

implementation

constructor TMMCSEApplication.Create;
begin
  inherited Create;
end;

procedure TMMCSEApplication.InitializeLog;
var
  consoleLogWriter: TCustomLogWriter;
begin
  fLogManager := TPlainLogManager.Create;
  consoleLogWriter := TConsoleLogWriter.Create;
  LogManager.AddWriter(consoleLogWriter);
  GlobalLogManager := LogManager;
  fLog := TLog.Create(LogManager, 'Application');
end;

procedure TMMCSEApplication.InitializeMainForm;
begin
  Application.CreateForm(TEmulatorMainForm, fMainForm);
  MainForm.DoubleBuffered := true;
  MainForm.ControlPanel.ConnectButton.OnClick := UserConnect; 
end;

procedure TMMCSEApplication.ActualRun;
begin
  InitializeLog;
  Log.Write('-->', 'Now initializing application...');
  Application.Initialize;
  Application.MainFormOnTaskBar := true;
  InitializeMainForm;
  Log.Write('>>>', 'Now running application...');
  Application.Run;
  Log.Write('|||', 'Now finalizing application...');
  FreeAndNil(fMainForm);
  FreeAndNil(fPipeConnector);
  FinalizeLog;
end;

procedure TMMCSEApplication.SafeRun;
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

procedure TMMCSEApplication.UserConnect(aSender: TObject);
begin
  if PipeConnector <> nil then
    FreeAndNil(fPipeConnector);
  if fPipeConnector = nil then
  begin
    fPipeConnector := TEmulationPipeConnector.Create;
    PipeConnector.Log := TLog.Create(GlobalLogManager, 'PipeConnector');
    PipeConnector.PipeName := DefaultPipeName;
    PipeConnector.OnConnected := OnConnectedHandler;
    PipeConnector.Startup;
  end;
end;

procedure TMMCSEApplication.OnConnectedHandler(aSender: TObject);
begin
  fSwitcher := TM2100Switcher.Create;
  Switcher.OnSendResponse := nil;
end;

procedure TMMCSEApplication.FinalizeLog;
begin
  Log.Write('Now finalizing log...');
  FreeAndNil(fLog);
  GlobalLogManager := nil;
  FreeAndNil(fLogManager);
end;

procedure TMMCSEApplication.Run;
begin
  SafeRun;
end;

destructor TMMCSEApplication.Destroy;
begin
  inherited Destroy;
end;

end.
