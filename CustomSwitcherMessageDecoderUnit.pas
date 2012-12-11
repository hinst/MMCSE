unit CustomSwitcherMessageDecoderUnit;

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
    FStream: TStream;
    procedure SetLog(const aLog: TEmptyLog);
    function GetResultMessage: TCustomSwitcherMessage; virtual; abstract;
  public
    property Log: TEmptyLog read FLog write SetLog;
    property Stream: TStream read FStream;
    property ResultMessage: TCustomSwitcherMessage read GetResultMessage;
    procedure Decode; virtual; abstract;
    class function DecodeThis(const aStream: TStream): TCustomSwitcherMessage;
    destructor Destroy; override;
  end;

  TCustomSwitcherMessageDecoderClass = class of TCustomSwitcherMessageDecoder;


implementation

constructor TCustomSwitcherMessageDecoder.Create(const aStream: TStream);
begin
  inherited Create;
  FLog := TEmptyLog.Create;
  FStream := aStream;
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
