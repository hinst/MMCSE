unit mmcse_project_ApplicationClass;

interface

uses
  SysUtils,
  Classes,
  Forms,

  UAdditionalTypes,
  UAdditionalExceptions,
  ExceptionTracer,

  CustomLogManager,
  PlainLogManager,
  CustomLogEntity,
  DefaultLogEntity,
  CustomLogWriter,
  ConsoleLogWriter,
  FileLogWriter,
  LogMemoryStorage,

  mmcse_common,
  mmcse_MainWindow,
  mmcse_PipeConnector,
  M2100Switcher;

type
  TMMCSEApplication = class
  public
    constructor Create;
  protected
    FLog: TCustomLog;
    FLogManager: TCustomLogManager;
    FLogMemory: TLogMemoryStorage;
    FMainForm: TEmulatorMainForm;
    FPipeConnector: TEmulationPipeConnector;
    FSwitcher: TM2100Switcher;
    procedure InitializeLog;
    procedure ActualRun;
    procedure SafeRun;
    procedure InitializeMainForm;
    procedure UserConnect(aSender: TObject);
    procedure OnConnectedHandler(aSender: TObject);
    procedure Disconnect;
    procedure UserDisconnect(aSender: TObject);
    procedure FinalizeLog;
  public
    property Log: TCustomLog read FLog;
    property LogManager: TCustomLogManager read FLogManager;
    property LogMemory: TLogMemoryStorage read FLogMemory;
    property MainForm: TEmulatorMainForm read FMainForm;
    property PipeConnector: TEmulationPipeConnector read FPipeConnector;
    property Switcher: TM2100Switcher read FSwitcher;
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
  fileLogWriter: TFileLogWriter;
begin
  FLogManager := TPlainLogManager.Create;

  consoleLogWriter := TConsoleLogWriter.Create;
  LogManager.AddWriter(consoleLogWriter);

  FLogMemory := TLogMemoryStorage.Create;
  LogManager.AddWriter(LogMemory);

  GlobalLogManager := LogManager;
  FLog := TLog.Create(LogManager, 'Application');
  
  fileLogWriter := TFileLogWriter.Create;
  fileLogWriter.SetDefaultFilePath;
  Log.Write('Log file: "' + fileLogWriter.FilePath + '"');
  LogManager.AddWriter(fileLogWriter);
end;

procedure TMMCSEApplication.InitializeMainForm;
begin
  Application.CreateForm(TEmulatorMainForm, FMainForm);
  MainForm.DoubleBuffered := true;
  MainForm.LogMemory := LogMemory;
  MainForm.Startup;
  MainForm.ControlPanel.OnUserConnect := UserConnect;
  MainForm.ControlPanel.OnUserDisconnect := UserDisconnect;
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
  MainForm.Enabled := false;
    //< user can't initiate any actions during finalization routine
  FreeAndNil(FPipeConnector);
  FreeAndNil(FSwitcher);
  FreeAndNil(FMainForm);
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
  Disconnect;
  if Switcher = nil then
  begin
    Log.Write('Now creating switcher...');
    FSwitcher := TM2100Switcher.Create;
    Switcher.Log := TLog.Create(GlobalLogManager, 'Switcher');
  end;
  if FPipeConnector = nil then
  begin
    Log.Write('Now connecting...');
    FPipeConnector := TEmulationPipeConnector.Create;
    PipeConnector.Log := TLog.Create(GlobalLogManager, 'PipeConnector');
    PipeConnector.PipeName := DefaultPipeName;
    PipeConnector.OnConnected := OnConnectedHandler;
    PipeConnector.OnIncomingMessage := Switcher.ProcessMessage;
    Switcher.OnSendResponse := PipeConnector.SendMessage;
    PipeConnector.Startup;
  end;
end;

procedure TMMCSEApplication.OnConnectedHandler(aSender: TObject);
begin
  // no routine
end;

procedure TMMCSEApplication.Disconnect;
begin
  if PipeConnector = nil then
    exit;
  PipeConnector.StopProcessingThread;
  if (Switcher <> nil) then
    Switcher.OnSendResponse := nil;
  //< It's almost certain that in case Switcher's OnSendResponse property is assigned, ...
  //... it contains a pointer to the current PipeConnector's SendMessage method.
  PipeConnector.OnIncomingMessage := nil; //< unnecessary
  FreeAndNil(FPipeConnector);
end;

procedure TMMCSEApplication.UserDisconnect(aSender: TObject);
begin
  if PipeConnector = nil then
    Log.Write('Cannot disconnect: not connected. (PipeConnector unassigned)')
  else
    Disconnect;
end;

procedure TMMCSEApplication.FinalizeLog;
begin
  Log.Write('Now finalizing log...');
  FreeAndNil(FLog);
  GlobalLogManager := nil;
  FreeAndNil(FLogManager);
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
