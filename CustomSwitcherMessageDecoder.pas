unit CustomSwitcherMessageDecoder;

interface

uses
  SysUtils,
  Classes,

  EmptyLogEntity,
  CustomSwitcherMessageUnit;

type

  ESwitcherMessageDecoderError = class(ESwitcherMessage);

  TCustomSwitcherMessageDecoder = class
  public
    constructor Create(const aStream: TStream); virtual;
  protected
    FLog: TEmptyLog;
    procedure SetLog(const aLog: TEmptyLog);
    function GetResult: TCustomSwitcherMessage; virtual; abstract;
  public
    property Log: TEmptyLog read FLog write SetLog;
    property ResultMessage: TCustomSwitcherMessage read GetResult;
    procedure Decode; virtual; abstract;
    class function DecodeThis(const aStream: TStream): TCustomSwitcherMessage;
    destructor Destroy; override;
  end;


implementation

constructor TCustomSwitcherMessageDecoder.Create(const aStream: TStream);
begin
  inherited Create;
  FLog := TEmptyLog.Create;
end;

procedure TCustomSwitcherMessageDecoder.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(FLog, aLog);
end;

class function TCustomSwitcherMessageDecoder.DecodeThis(const aStream: TStream)
  : TCustomSwitcherMessage;
var
  decoder: TCustomSwitcherMessageDecoder;
begin
  decoder := self.Create(aStream);
  try
    decoder.Decode;
    result := decoder.ResultMessage;
  finally
    decoder.Free;
  end;
end;

destructor TCustomSwitcherMessageDecoder.Destroy;
begin
  FreeAndNil(FLog);
  inherited Destroy;
end;

end.
