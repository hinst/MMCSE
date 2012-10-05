
unit mmcse_MainWindow;


interface

uses
  SysUtils,
  Classes,

  Controls,
  Forms,

  EmptyLogEntity,
  DefaultLogEntity,
  VCLLogDisplayerAttachable,

  mmcse_common;


type
  TEmulatorMainForm = class(TForm)
  public
    constructor Create(aOwner: TComponent); override;
  protected
    fLog: TEmptyLog;
    fLogDisplay: TLogDisplayer;
    procedure SetLog(const aLog: TEmptyLog);
    procedure CreateThis;
    procedure AdjustInitialPosition;
    procedure DestroyThis;
  public
    property Log: TEmptyLog read fLog write SetLog;
    property LogDisplay: TLogDisplayer read fLogDisplay;
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
  fLogDisplay := TLogDisplayer.Create(self);
  LogDisplay.Log := TLog.Create(GlobalLogManager, 'LogDisplay');
  LogDisplay.Writer.Log := TLog.Create(GlobalLogManager, 'LogDisplayWriter');
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
  DisposeContent;
  FreeAndNil(fLog);
end;

procedure TEmulatorMainForm.DisposeContent;
begin
  if LogDisplay <> nil then
    FreeAndNil(fLogDisplay);
end;

destructor TEmulatorMainForm.Destroy;
begin
  Log.Write('Destroy...');
  DestroyThis;
  inherited Destroy;
end;

end.
