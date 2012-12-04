unit CustomSwitcherUnit;

interface

uses
  SysUtils,
  Classes,

  CustomLogEntity,
  EmptyLogEntity;

type
  TCustomSwitcher = class
  public
    constructor Create;
    procedure Startup; virtual; abstract;
  public type
    TSendResponceMethod = procedure(const aResponce: TStream) of object;
      //< nil stream indicates that there is no message data available at the moment
  protected
    FLog: TEmptyLog;
    FSendMessageMethod: TSendResponceMethod;
    procedure SetLog(const aLog: TEmptyLog);
  public
      // external log assignment scheme
    property Log: TEmptyLog read FLog write FLog;
    property SendMessageMethod: TSendResponceMethod read FSendMessageMethod write FSendMessageMethod;
    procedure ProcessMessage(const aMessage: TStream); virtual; abstract;
    destructor Destroy; override;
  end;

  TCustomSwitcherClass = class of TCustomSwitcher;

implementation

constructor TCustomSwitcher.Create;
begin
  inherited Create;
  FLog := TEmptyLog.Create;
end;

procedure TCustomSwitcher.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(FLog, aLog);
end;

destructor TCustomSwitcher.Destroy;
begin
  FreeAndNil(FLog);
  inherited Destroy;
end;

initialization
finalization
end.
