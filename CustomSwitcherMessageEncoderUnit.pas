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
      // does not assigns aMessage
    constructor Create(const aMessage: TCustomSwitcherMessage); virtual;
  protected
    FLog: TEmptyLog;
    FStream: TStream;
    property Stream: TStream read FStream; 
    procedure SetLog(const aLog: TEmptyLog);
    procedure Encode; virtual; abstract;
  public
    property Log: TEmptyLog read FLog write SetLog;
    property ResultStream: TStream read FStream;
    class function EncodeThis(const aStream: TCustomSwitcherMessage): TStream;
    destructor Destroy; override;
  end;

  TCustomSwitcherMessageEncoderClass = class of TCustomSwitcherMessageEncoder;


implementation

constructor TCustomSwitcherMessageEncoder.Create(const aMessage: TCustomSwitcherMessage);
begin
  inherited Create;
  FLog := TEmptyLog.Create;
end;

procedure TCustomSwitcherMessageEncoder.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(FLog, aLog);
end;

class function TCustomSwitcherMessageEncoder.EncodeThis(const aStream: TCustomSwitcherMessage)
  : TStream;
var
  encoder: TCustomSwitcherMessageEncoder;
begin
  encoder := self.Create(aStream);
  try
    encoder.Encode;
    result := encoder.ResultStream;
  finally
    encoder.Free;
  end;
end;

destructor TCustomSwitcherMessageEncoder.Destroy;
begin
  FreeAndNil(FLog);
  inherited Destroy;
end;

end.
