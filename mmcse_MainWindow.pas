
unit mmcse_MainWindow;


interface

uses
  SysUtils,
  Classes,

  Controls,
  Forms,

  VCLLogDisplayerAttachable,

  mmcse_common;


type
  TEmulatorMainForm = class(TForm)
  public
    constructor Create(aOwner: TComponent); override;
  protected
    fLogDisplay: TLogDisplayer;
    procedure CreateThis;
    procedure AdjustInitialPosition;
    procedure DestroyThis;
  public
    property LogDisplay: TLogDisplayer read fLogDisplay;
    destructor Destroy; override;
  end;


  implementation

constructor TEmulatorMainForm.Create(aOwner: TComponent);
begin
  inherited CreateNew(aOwner);
  CreateThis;
end;

procedure TEmulatorMainForm.CreateThis;
begin
  AdjustInitialPosition;
  fLogDisplay := TLogDisplayer.Create(self);
  LogDisplay.AttachTo(GlobalLogManager);
  LogDisplay.Parent := self;
  LogDisplay.Align := alClient;
end;

procedure TEmulatorMainForm.AdjustInitialPosition;
begin
  Width := Screen.DesktopWidth div 3 * 2;
  Height := Screen.DesktopHeight div 3 * 2;
  Position := poDesktopCenter;
end;

procedure TEmulatorMainForm.DestroyThis;
begin
  FreeAndNil(fLogDisplay);
end;

destructor TEmulatorMainForm.Destroy;
begin
  DestroyThis;
  inherited Destroy;
end;

end.
