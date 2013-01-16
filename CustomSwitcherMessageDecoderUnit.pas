unit CustomSwitcherMessageDecoderUnit;

{$Define EnableDefaultMMCSELog}

interface

uses
  SysUtils,
  Classes,

  UAdditionalTypes,
  UAdditionalExceptions,

  EmptyLogEntity,
  {$IfDef EnableDefaultMMCSELog}
  DefaultLogEntity,
  CommonUnit,
  {$EndIf}
  CustomSwitcherMessageUnit,
  CustomSwitcherMessageListUnit;

type

  ESwitcherMessageDecoderError = class(ESwitcherMessage);

  TCustomSwitcherMessageDecoder = class
  public
    constructor Create(const aStream: TStream); virtual;
  protected
    FLog: TEmptyLog;
    FStream: TStream;
    procedure SetLog(const aLog: TEmptyLog);
    function GetResults: TCustomSwitcherMessageList; virtual; abstract;
  public
    property Log: TEmptyLog read FLog write SetLog;
    property Stream: TStream read FStream;
    property Results: TCustomSwitcherMessageList read GetResults;
    procedure Decode; virtual; abstract;
    class function DecodeThis(const aStream: TStream): TCustomSwitcherMessageList;
    destructor Destroy; override;
  end;

  TCustomSwitcherMessageDecoderClass = class of TCustomSwitcherMessageDecoder;


implementation

constructor TCustomSwitcherMessageDecoder.Create(const aStream: TStream);
begin
  AssertAssigned(aStream, 'aStream', TVariableType.Prop);
  inherited Create;
  FLog := TEmptyLog.Create;
  FStream := aStream;
end;

procedure TCustomSwitcherMessageDecoder.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(FLog, aLog);
end;

class function TCustomSwitcherMessageDecoder.DecodeThis(const aStream: TStream)
  : TCustomSwitcherMessageList;
var
  decoder: TCustomSwitcherMessageDecoder;
begin
  decoder := self.Create(aStream);
  {$IfDef EnableDefaultMMCSELog}
  decoder.Log := TLog.Create(GlobalLogManager, 'Decoder[' + self.ClassName + ']');
  {$EndIf}
  try
    decoder.Decode;
    result := decoder.Results;
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
