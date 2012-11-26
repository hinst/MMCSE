unit ControlPanelUnit;

interface

uses
  Windows,
  Types,
  Classes,
  Controls,
  StdCtrls,
  ExtCtrls,
  Buttons,
  Menus,
  Forms,

  UAdditionalTypes,
  UAdditionalExceptions,

  SwitcherFactoryUnit;

type
  TControlPanel = class(TFlowPanel)
  public
    constructor Create(aOwner: TComponent); override;
  protected
    FMenuButton: TSpeedButton;
    FMenu: TPopupMenu;
    FConnectMenuItem: TMenuItem;
    FSwitcherMenuItem: TMenuItem;
    FDisconnectMenuItem: TMenuItem;
    FControlsCreated: boolean;
    procedure SetParent(aParent: TWinControl); override;
    procedure SetOnUserConnect(const aValue: TNotifyEvent);
    procedure SetOnUserDisconnect(const aEvent: TNotifyEvent);
    procedure CreateControls;
    procedure CreateMenuButton;
    procedure CreateMenu;
    function CreateSwitcherMenu: TMenuItem;
    procedure AttachSwitcherClassesMenu(const aMenuItem: TMenuItem);
    procedure CreateControlsIfNotCreated;
    procedure OnMenuButtonClickHandler(aSender: TObject);
  public
    property MenuButton: TSpeedButton read FMenuButton;
    property Menu: TPopupMenu read FMenu;
    property ConnectMenuItem: TMenuItem read FConnectMenuItem;
    property SwitcherMenuItem: TMenuItem read FSwitcherMenuItem;
    property DisconnectMenuItem: TMenuItem read FDisconnectMenuItem;
    property ControlsCreated: boolean read FControlsCreated;
    property OnUserConnect: TNotifyEvent write SetOnUserConnect;
    property OnUserDisconnect: TNotifyEvent write SetOnUserDisconnect;
  end;


implementation

constructor TControlPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FControlsCreated := false;
end;

procedure TControlPanel.SetOnUserConnect(const aValue: TNotifyEvent);
begin
  AssertAssigned(ConnectMenuItem, 'ConnectMenuItem', TVariableType.Prop);
  ConnectMenuItem.OnClick := aValue;
end;

procedure TControlPanel.SetOnUserDisconnect(const aEvent: TNotifyEvent);
begin
  AssertAssigned(DisconnectMenuItem, 'DisconnectMenuItem', TVariableType.Prop);
  DisconnectMenuItem.OnClick := aEvent;
end;

procedure TControlPanel.SetParent(aParent: TWinControl);
begin
  inherited SetParent(aParent);
  if aParent = nil then
    exit;  
  CreateControlsIfNotCreated;
end;

procedure TControlPanel.CreateControls;
begin
  CreateMenuButton;
  CreateMenu;
end;

procedure TControlPanel.CreateMenuButton;
begin
  FMenuButton := TSpeedButton.Create(self);
  MenuButton.Caption := 'Menu';
  MenuButton.Parent := self;
  MenuButton.Width := 100;
  MenuButton.AlignWithMargins := true;
  ClientHeight :=
    MenuButton.Height
     + BevelWidth
     + Padding.Top + Padding.Bottom
     + MenuButton.Margins.Top + MenuButton.Margins.Bottom;
  MenuButton.OnClick := OnMenuButtonClickHandler;
end;

procedure TControlPanel.CreateMenu;
var
  closeMenuItem: TMenuItem;
begin
  FMenu := TPopupMenu.Create(self);
  // CONNECT
  FConnectMenuItem := TMenuItem.Create(Menu);
  ConnectMenuItem.Caption := 'Connect';
  Menu.Items.Add(ConnectMenuItem);
  // SWITCHER
  FSwitcherMenuItem := CreateSwitcherMenu;
  Menu.Items.Add(SwitcherMenuItem);
  // DISCONNECT
  FDisconnectMenuItem := TMenuItem.Create(Menu);
  DisconnectMenuItem.Caption := 'Disconnect';
  Menu.Items.Add(DisconnectMenuItem);
  // CLOSE
  closeMenuItem := TMenuItem.Create(Menu);
  closeMenuItem.Caption := 'Close this menu';
  Menu.Items.Add(closeMenuItem);
end;

function TControlPanel.CreateSwitcherMenu: TMenuItem;
begin
  result := TMenuItem.Create(Menu);
  result.Caption := 'Switcher';
  AttachSwitcherClassesMenu(result);
end;

procedure TControlPanel.AttachSwitcherClassesMenu(const aMenuItem: TMenuItem);
var
  i: integer;
  item: TMenuItem;
begin
  for i := 0 to GetGlobalSwitcherClasses.Count - 1 do
  begin
    item := TMenuItem.Create(aMenuItem);
    item.Caption := GetGlobalSwitcherClasses[i].ClassName;
    item.RadioItem := true;
    aMenuItem.Add(item);
  end;
  if aMenuItem.Count > 0 then
    aMenuItem.Items[i].Checked := true;
end;

procedure TControlPanel.CreateControlsIfNotCreated;
begin
  if not ControlsCreated then
  begin
    CreateControls;
    FControlsCreated := true;
  end;
end;

procedure TControlPanel.OnMenuButtonClickHandler(aSender: TObject);
begin
  if Menu <> nil then
  begin
    if not IsWindowVisible(Menu.WindowHandle) then
      Menu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

end.
