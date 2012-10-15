unit mmcse_ControlPanel;

interface

uses
  Classes,
  Controls,
  StdCtrls,
  ExtCtrls,
  Buttons,
  Forms;

type
  TControlPanel = class(TFlowPanel)
  public
    constructor Create(aOwner: TComponent); override;
  protected
    fConnectButton: TSpeedButton;
    fControlsCreated: boolean;
    procedure SetParent(aParent: TWinControl); override;
    procedure CreateControls;
    procedure CreateControlsIfNotCreated;
  public
    property ConnectButton: TSpeedButton read fConnectButton;
    property ControlsCreated: boolean read fControlsCreated;
  end;


implementation

constructor TControlPanel.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  fControlsCreated := false;
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
  fConnectButton := TSpeedButton.Create(self);
  ConnectButton.Caption := 'Connect';
  ConnectButton.Parent := self;
  ConnectButton.ClientWidth := 100;
  ConnectButton.AlignWithMargins := true;
  ClientHeight :=
    ConnectButton.Height
     + BevelWidth
     + Padding.Top + Padding.Bottom
     + ConnectButton.Margins.Top + ConnectButton.Margins.Bottom;
end;

procedure TControlPanel.CreateControlsIfNotCreated;
begin
  if not ControlsCreated then
  begin
    CreateControls;
    fControlsCreated := true;
  end;
end;

end.
