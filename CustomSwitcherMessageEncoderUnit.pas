unit CustomSwitcherMessageEncoderUnit;

interface

uses
  SysUtils,
  Classes,

  EmptyLogEntity,

  CustomSwitcherMessageUnit;

type
  ESwitcherMessageEncoderError = class(ESwitcherMessage);

  TCustomSwitcherMessageEncoder = class
  public
    constructor Create(const aMessage: TCustomSwitcherMessage); virtual;
  protected
    FLog: TEmptyLog;
    FMessageToDecode: TCustomSwitcherMessage; 
    procedure SetLog(const aLog: TEmptyLog);
    function GetResultStream: TStream; virtual; abstract;
  public
    property Log: TEmptyLog read FLog write SetLog;
    property ResultStream: TStream read GetResultStream;
    property MessageToDecode: TCustomSwitcherMessage read FMessageToDecode;
    procedure Encode; virtual; abstract;
    class function EncodeThis(const aStream: TCustomSwitcherMessage): TStream;
    destructor Destroy; override;
  end;

  TCustomSwitcherMessageEncoderClass = class of TCustomSwitcherMessageEncoder;


implementation

{ TCustomSwitcherMessageEncoder }

constructor TCustomSwitcherMessageEncoder.Create(const aMessage: TCustomSwitcherMessage);
begin
  inherited Create;
  FMessageToDecode := aMessage;
end;

class function TCustomSwitcherMessageEncoder.EncodeThis(
  const aStream: TCustomSwitcherMessage): TStream;
begin

end;

procedure TCustomSwitcherMessageEncoder.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(FLog, aLog);
end;

destructor TCustomSwitcherMessageEncoder.Destroy;
begin
  FreeAndNil(FLog);
  inherited Destroy;
end;

end.
