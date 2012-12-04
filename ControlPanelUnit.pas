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

  MMCSEMenuGroups,
  CustomSwitcherUnit,
  CustomSwitcherFactoryUnit;

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
    function GetUserSwitcherClass: TCustomSwitcherClass;
    procedure CreateControls;
    procedure CreateMenuButton;
    procedure CreateMenu;
    function CreateSwitcherMenu: TMenuItem;
    procedure AttachSwitcherClassesMenu(const aMenuItem: TMenuItem);
    procedure HandleSwitcherMenuItemClick(aSender: TObject);
    procedure CreateControlsIfNotCreated;
    procedure OnMenuButtonClickHandler(aSender: TObject);
  public
    property MenuButton: TSpeedButton read FMenuButton;
    property Menu: TPopupMenu read FMenu;
    property ConnectMenuItem: TMenuItem read FConnectMenuItem;
    property SwitcherMenuItem: TMenuItem read FSwitcherMenuItem;
    property UserSwitcherClass: TCustomSwitcherClass read GetUserSwitcherClass;
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

function TControlPanel.GetUserSwitcherClass: TCustomSwitcherClass;
var
  i: integer;
  item: TMenuItem;
  switcherClassName: string;
begin
  result := nil;
  for i := 0 to SwitcherMenuItem.Count - 1 do
  begin
    item := SwitcherMenuItem.Items[i];
    if item.Checked then
    begin
      switcherClassName := item.Name;
      result := GetSwitcherClassByName( item.Name );
      break;
    end;
  end;
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
  switcherClassName: string;
begin
  for i := 0 to GetGlobalSwitcherClasses.Count - 1 do
  begin
    item := TMenuItem.Create(aMenuItem);
    switcherClassName := GetGlobalSwitcherClasses[i].ClassName;
    item.Caption := switcherClassName + ' Switcher';
    item.Name := switcherClassName;
    item.RadioItem := true;
    item.GroupIndex := SWITCHER_SELECT_MENU_GROUP;
    item.OnClick := HandleSwitcherMenuItemClick;
    aMenuItem.Add(item);
  end;
  if aMenuItem.Count > 0 then
    aMenuItem.Items[0].Checked := true;
end;

procedure TControlPanel.HandleSwitcherMenuItemClick(aSender: TObject);
var
  item: TMenuItem;
begin
  AssertType(aSender, TMenuItem);
  item := aSender as TMenuItem;
  item.Checked := true;
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
