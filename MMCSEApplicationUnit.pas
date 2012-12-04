unit MMCSEApplicationUnit;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Forms,

  UAdditionalTypes,
  UAdditionalExceptions,
  UExceptionTracer,
  UVCL,

  CustomLogManager,
  PlainLogManager,
  CustomLogEntity,
  DefaultLogEntity,
  CustomLogWriter,
  ConsoleLogWriter,
  FileLogWriter,
  ULogFileModels,
  LogMemoryStorage,

  CommonUnit,
  MMCSEMainWindowUnit,
  SwitcherDebugPipeConnectorUnit,

  {$REGION Switchers}
  CustomSwitcherUnit,
  CustomSwitcherFactoryUnit,
  M2100Switcher
  {$ENDREGION}
  ;

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
    FSwitcher: TCustomSwitcher;
    function GetIsConnected: boolean;
    function GetUserSwitcherClass: TCustomSwitcherClass;
    procedure InitializeLog;
    procedure ActualRun;
    procedure SafeRun;
    procedure InitializeMainForm;
    procedure UserConnect(aSender: TObject);
    function CreateUserSwitcher: TCustomSwitcher;
    procedure StartupUserDesiredSwitcher;
    function SafeStartupUserDesiredSwitcher: boolean;
    function SafeConnectSwitcher: boolean;
    function CreateStartupUserSwitcher: TCustomSwitcher;
    procedure ConnectSwitcher;
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
    property Connected: boolean read GetIsConnected;
    property Switcher: TCustomSwitcher read FSwitcher;
    property UserSwitcherClass: TCustomSwitcherClass read GetUserSwitcherClass;
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

function TMMCSEApplication.CreateUserSwitcher: TCustomSwitcher;
var
  switcherClass: TCustomSwitcherClass;
begin
  switcherClass := GetUserSwitcherClass;
  AssertAssigned(switcherClass, 'switcherClass', TVariableType.Local);
  result := switcherClass.Create;
end;

function TMMCSEApplication.GetIsConnected: boolean;
begin
  result := PipeConnector <> nil;
end;

function TMMCSEApplication.GetUserSwitcherClass: TCustomSwitcherClass;
begin
  AssertAssigned(self, 'self', TVariableType.Argument);
  AssertAssigned(MainForm, 'MainForm', TVariableType.Prop);
  AssertAssigned(MainForm.ControlPanel, 'MainForm.ControlPanel', TVariableType.Prop);
  result := MainForm.ControlPanel.UserSwitcherClass;
end;

procedure TMMCSEApplication.InitializeLog;
var
  consoleLogWriter: TCustomLogWriter;
begin
  FLogManager := TPlainLogManager.Create;

  FLogMemory := TLogMemoryStorage.Create;
  LogManager.AddWriter(LogMemory);

  consoleLogWriter := TConsoleLogWriter.Create;
  LogManager.AddWriter(consoleLogWriter);

  GlobalLogManager := LogManager;
  FLog := TLog.Create(LogManager, 'Application');

  TLogFileModels.ApplyLocal10Model(GlobalLogManager);
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
    //< user should not initiate any actions during finalization routine
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
var
  result: boolean;
begin
  UserDisconnect(aSender);
  result := SafeStartupUserDesiredSwitcher;
  if not result then
    exit;
  result := SafeConnectSwitcher;
  if not result then
    exit;
end;

  // and remove the old one if does not match desired class
procedure TMMCSEApplication.StartupUserDesiredSwitcher;
begin
  if Switcher <> nil then
    if (Switcher.ClassType <> GetUserSwitcherClass) then
      FreeAndNil(FSwitcher);
  if Switcher = nil then
    FSwitcher := CreateStartupUserSwitcher;
  Log.Write('Switcher created: ' + Switcher.ClassName);
end;

function TMMCSEApplication.SafeStartupUserDesiredSwitcher: boolean;
begin
  result := false;
  try
    StartupUserDesiredSwitcher;
    AssertAssigned(Switcher, 'Switcher', TVariableType.Prop);
    result := true;
  except
    on e: Exception do
    begin
      Log.Write(
        'ERROR',
        'Could not startup switcher:' + sLineBreak
          + GetExceptionInfo(e) + sLineBreak
          + 'Can not continue connection routine.');
      exit;
    end;
  end;
end;

function TMMCSEApplication.SafeConnectSwitcher: boolean;
begin
  result := false;
  try
    ConnectSwitcher;
    result := true;
  except
    on e: Exception do
    begin
      Log.Write('ERROR', 'Could not connect switcher:' + sLineBreak + GetExceptionInfo(e));
      exit;
    end;
  end;
end;

function TMMCSEApplication.CreateStartupUserSwitcher: TCustomSwitcher;
begin
  result := CreateUserSwitcher;
  AssertAssigned(result, 'result', TVariableType.Local);
  result.Log := TLog.Create(GlobalLogManager, 'Switcher');
    //< assign switcher log
  result.Startup;
    //< startup switcher
end;

procedure TMMCSEApplication.ConnectSwitcher;
begin
  AssertAssigned(Switcher, 'Switcher', TVariableType.Prop);
  Log.Write('Now connecting switcher...');
  if PipeConnector <> nil then
    raise Exception.Create('PipeConnector assigned: already connected, have to disconnect first');
  FPipeConnector := TEmulationPipeConnector.Create;
  PipeConnector.Log := TLog.Create(GlobalLogManager, 'PipeConnector');
  PipeConnector.PipeName := DefaultPipeName;
  PipeConnector.OnConnected := OnConnectedHandler;
  PipeConnector.OnIncomingMessage := Switcher.ProcessMessage;
  Switcher.SendMessageMethod := PipeConnector.SendMessageMethod;
  PipeConnector.Startup;
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
  if
    (Switcher <> nil)
    and MethodsEqual(TMethod(Switcher.SendMessageMethod), TMethod(PipeConnector.SendMessageMethod))
  then
    Switcher.SendMessageMethod := nil;
  PipeConnector.OnIncomingMessage := nil; //< unnecessary
  FreeAndNil(FPipeConnector);
end;

procedure TMMCSEApplication.UserDisconnect(aSender: TObject);
begin
  if not Connected then
    Log.Write('Cannot disconnect: not connected.')
  else
  begin
    try
      Disconnect;
      Log.Write('Disconnected.');
    except
      on e: Exception do
      begin
        Log.Write(
          'ERROR', 'User command: disconnect. Could not disconnect: exception occured:'
          + sLineBreak + GetExceptionInfo(e));
        AssertSuppressable(e);
      end;
    end;
  end;
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
