unit mmcse_MainWindow;


interface

uses
  Types,
  SysUtils,
  Classes,

  Controls,
  Forms,
  Menus,

  EmptyLogEntity,
  DefaultLogEntity,
  VCLLogPanel,

  mmcse_common,
  mmcse_ControlPanel;


type
  TEmulatorMainForm = class(TForm)
  public
    constructor Create(aOwner: TComponent); override;
  protected
    fLog: TEmptyLog;
    fLogPanel: TLogViewPanel;
    fControlPanel: TControlPanel;
    procedure SetLog(const aLog: TEmptyLog);
    procedure CreateThis;
    procedure AdjustInitialPosition;
    procedure OnMouseWheelHandler(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint; var Handled: Boolean);
    procedure OnUserAutoScrollHandler(aSender: TObject);
    procedure DestroyThis;
  public
    property Log: TEmptyLog read fLog write SetLog;
    property LogPanel: TLogViewPanel read fLogPanel;
    property ControlPanel: TControlPanel read fControlPanel;
    procedure DisposeContent;
    destructor Destroy; override;
  end;


implementation

constructor TEmulatorMainForm.Create(aOwner: TComponent);
begin
  inherited CreateNew(aOwner);
  CreateThis;
end;

procedure TEmulatorMainForm.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(fLog, aLog);
end;

procedure TEmulatorMainForm.CreateThis;
begin
  AdjustInitialPosition;
  fLog := TLog.Create(GlobalLogManager, 'EmulatorMainForm');
  {$REGION Log panel}
  fLogPanel := TLogViewPanel.Create(self);
  LogPanel.Log := TLog.Create(GlobalLogManager, 'LogDisplay');
  LogPanel.Writer.Log := TLog.Create(GlobalLogManager, 'LogDisplayWriter');
  LogPanel.AttachTo(GlobalLogManager);
  LogPanel.Align := alClient;
  LogPanel.Parent := self;
  {$ENDREGION}
  {$REGION Control panel}
  fControlPanel := TControlPanel.Create(self);
  ControlPanel.Align := alBottom;
  ControlPanel.Parent := self;
  ControlPanel.OnUserAutoScroll := OnUserAutoScrollHandler; 
  ControlPanel.AutoScrollMenuItem.Checked := LogPanel.AutoScroll;
  {$ENDREGION}
  OnMouseWheel := OnMouseWheelHandler;
end;

procedure TEmulatorMainForm.OnMouseWheelHandler(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if LogPanel <> nil then
    LogPanel.UserScroll(WheelDelta);
end;

procedure TEmulatorMainForm.AdjustInitialPosition;
begin
  Width := Screen.DesktopWidth div 3 * 2;
  Height := Screen.DesktopHeight div 3 * 2;
  Position := poDesktopCenter;
end;

procedure TEmulatorMainForm.OnUserAutoScrollHandler(aSender: TObject);
var
  item: TMenuItem;
begin
  if aSender is TMenuItem then
  begin
    item := aSender as TMenuItem;
    LogPanel.AutoScroll := not LogPanel.AutoScroll;
    item.Checked := LogPanel.AutoScroll;
  end;
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
