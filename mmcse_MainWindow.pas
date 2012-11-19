unit mmcse_MainWindow;


interface

uses
  Types,
  SysUtils,
  Classes,

  Controls,
  Forms,
  Menus,

  UAdditionalTypes,
  UAdditionalExceptions,
  UVCL,

  EmptyLogEntity,
  DefaultLogEntity,
  LogMemoryStorage,
  VCLLogViewPanel,

  mmcse_common,
  mmcse_ControlPanel;


type
  TEmulatorMainForm = class(TForm)
  public
    constructor Create(aOwner: TComponent); override;
    procedure Startup;
  protected
    fLog: TEmptyLog;
    FLogMemory: TLogMemoryStorage;
    fLogPanel: TLogViewPanel;
    fControlPanel: TControlPanel;
    procedure SetLog(const aLog: TEmptyLog);
    procedure AdjustInitialPosition;
    procedure OnMouseWheelHandler(Sender: TObject; aShift: TShiftState; aWheelDelta: Integer;
      aMousePos: TPoint; var aHandled: Boolean);
    procedure DestroyThis;
  public
    property Log: TEmptyLog read fLog write SetLog;
      // set this before Startup
    property LogMemory: TLogMemoryStorage read FLogMemory write FLogMemory;
    property LogPanel: TLogViewPanel read fLogPanel;
    property ControlPanel: TControlPanel read fControlPanel;
    procedure DisposeContent;
    destructor Destroy; override;
  end;


implementation

constructor TEmulatorMainForm.Create(aOwner: TComponent);
begin
  inherited CreateNew(aOwner);
end;

procedure TEmulatorMainForm.Startup;
begin
  AdjustInitialPosition;
  fLog := TLog.Create(GlobalLogManager, 'EmulatorMainForm');
  {$REGION Log panel}
  AssertAssigned(LogMemory, 'LogMemory', TVariableType.Prop);
  fLogPanel := TLogViewPanel.Create(self);
  LogPanel.Parent := self;
  LogPanel.Align := alClient;
  LogPanel.LogMemory := LogMemory;
  LogPanel.Startup;
  {$ENDREGION}
  {$REGION Control panel}
  fControlPanel := TControlPanel.Create(self);
  ControlPanel.Align := alBottom;
  ControlPanel.Parent := self;
  {$ENDREGION}
  OnMouseWheel := OnMouseWheelHandler;
end;

procedure TEmulatorMainForm.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(fLog, aLog);
end;

procedure TEmulatorMainForm.OnMouseWheelHandler(Sender: TObject; aShift: TShiftState;
  aWheelDelta: Integer; aMousePos: TPoint; var aHandled: Boolean);
begin
  if LogPanel <> nil then
    if IsMouseOverControl(LogPanel) then
      LogPanel.ReceiveMouseWheel(aShift, aWheelDelta, aMousePos);
end;

procedure TEmulatorMainForm.AdjustInitialPosition;
begin
  Width := Screen.DesktopWidth div 3 * 2;
  Height := Screen.DesktopHeight div 3 * 2;
  Position := poDesktopCenter;
end;

procedure TEmulatorMainForm.DestroyThis;
begin
  DisposeContent;
  FreeAndNil(fLog);
end;

procedure TEmulatorMainForm.DisposeContent;
begin
  if LogPanel <> nil then
    FreeAndNil(fLogPanel);
end;

destructor TEmulatorMainForm.Destroy;
begin
  DestroyThis;
  inherited Destroy;
end;

end.
