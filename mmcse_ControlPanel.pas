unit mmcse_ControlPanel;

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
  UAdditionalExceptions;

type
  TControlPanel = class(TFlowPanel)
  public
    constructor Create(aOwner: TComponent); override;
  protected
    fMenuButton: TSpeedButton;
    fMenu: TPopupMenu;
    fConnectMenuItem: TMenuItem;
    fAutoScrollMenuItem: TMenuItem;
    fDisconnectMenuItem: TMenuItem;
    fControlsCreated: boolean;
    procedure SetParent(aParent: TWinControl); override;
    procedure SetOnUserConnect(const aValue: TNotifyEvent);
    procedure SetOnUserAutoScroll(const aEvent: TNotifyEvent);
    procedure SetOnUserDisconnect(const aEvent: TNotifyEvent);
    procedure CreateControls;
    procedure CreateMenuButton;
    procedure CreateMenu;
    procedure CreateControlsIfNotCreated;
    procedure OnMenuButtonClickHandler(aSender: TObject);
  public
    property MenuButton: TSpeedButton read fMenuButton;
    property Menu: TPopupMenu read fMenu;
    property ConnectMenuItem: TMenuItem read fConnectMenuItem;
    property AutoScrollMenuItem: TMenuItem read fAutoScrollMenuItem;
    property DisconnectMenuItem: TMenuItem read fDisconnectMenuItem;
    property ControlsCreated: boolean read fControlsCreated;
    property OnUserConnect: TNotifyEvent write SetOnUserConnect;
    property OnUserAutoScroll: TNotifyEvent write SetOnUserAutoScroll;
    property OnUserDisconnect: TNotifyEvent write SetOnUserDisconnect;
  end;


implementation

constructor TControlPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fControlsCreated := false;
end;

procedure TControlPanel.SetOnUserConnect(const aValue: TNotifyEvent);
begin
  AssertAssigned(ConnectMenuItem, 'ConnectMenuItem', TVariableType.Prop);
  ConnectMenuItem.OnClick := aValue;
end;

procedure TControlPanel.SetOnUserAutoScroll(const aEvent: TNotifyEvent);
begin
  AssertAssigned(AutoScrollMenuItem, 'AutoScrollMenuItem', TVariableType.Prop);
  AutoScrollMenuItem.OnClick := aEvent;
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
  fMenuButton := TSpeedButton.Create(self);
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
  fMenu := TPopupMenu.Create(self);
  // CONNECT
  fConnectMenuItem := TMenuItem.Create(Menu);
  ConnectMenuItem.Caption := 'Connect';
  Menu.Items.Add(ConnectMenuItem);
  // AUTOSCROLL
  fAutoScrollMenuItem := TMenuItem.Create(Menu);
  AutoScrollMenuItem.Caption := 'AutoScroll';
  Menu.Items.Add(AutoScrollMenuItem);
  // DISCONNECT
  fDisconnectMenuItem := TMenuItem.Create(Menu);
  DisconnectMenuItem.Caption := 'Disconnect';
  Menu.Items.Add(DisconnectMenuItem);
  // CLOSE
  closeMenuItem := TMenuItem.Create(Menu);
  closeMenuItem.Caption := 'Close this menu';
  Menu.Items.Add(closeMenuItem);
end;

procedure TControlPanel.CreateControlsIfNotCreated;
begin
  if not ControlsCreated then
  begin
    CreateControls;
    fControlsCreated := true;
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
