unit PresmasterSwitcherMessageDecoderUnit;

interface

uses
  SysUtils,
  Classes,

  UStreamUtilities,

  CustomSwitcherMessageUnit,
  CustomSwitcherMessageDecoderUnit,
  PresmasterSwitcherMessage;

type
  TPresmasterSwitcherMessageDecoder = class(TCustomSwitcherMessageDecoder)
  public
    constructor Create(const aStream: TStream); override;
  protected
    FMessage: TPresmasterMessage;
    function GetResultMessage: TCustomSwitcherMessage; override;
    procedure ReadFormatField;
    procedure ReadCommandField;
    procedure ReadSimpleCommand;
    procedure ReadExtendedCommand;
    procedure ReadUnknown(const aMessage: TPresmasterMessageUnknown);
    procedure ReadSimpleSetMessageTail;
  public
    procedure Decode; override;
  end;


implementation

constructor TPresmasterSwitcherMessageDecoder.Create(const aStream: TStream);
begin
  inherited Create(aStream);
  FMessage := TPresmasterMessage.Create;
end;

function TPresmasterSwitcherMessageDecoder.GetResultMessage: TCustomSwitcherMessage;
begin
  result := FMessage;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadFormatField;
var
  messageFormat: byte;
begin
  Stream.ReadBuffer(messageFormat, 1);
  FMessage.Format := messageFormat;
  Assert(FMessage.IsValidFormat);
end;

procedure TPresmasterSwitcherMessageDecoder.ReadCommandField;
begin
  if FMessage.Format = FMessage.FormatSimple then
    ReadSimpleCommand;
  if FMessage.Format = FMessage.FormatExtended then
    ReadExtendedCommand;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadSimpleCommand;
var
  command: byte;
var
  transformedMessage: TPresmasterMessage;
begin
  Stream.ReadBuffer(command, 1);
  FMessage.Command := command;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadExtendedCommand;
var
  command: word;
begin
  Stream.ReadBuffer(command, 2);
  FMessage.Command := command;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadSimpleSetMessageTail;
var
  formatTail: byte;
  sourceNumber: word;
begin
  Stream.ReadBuffer(formatTail, 1);
  if formatTail = TPresmasterMessage.FormatSimpleTail then
    Stream.ReadBuffer(sourceNumber, 2)
  else
    sourceNumber := formatTail;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadUnknown(const aMessage: TPresmasterMessageUnknown);
begin
  aMessage.Stream.CopyFrom(Stream, CalculateRemainingSize(Stream));
end;

procedure TPresmasterSwitcherMessageDecoder.Decode;
begin
  ReadFormatField;
  ReadCommandField;
  TPresmasterMessage.ResolveSpecific(FMessage);
  if FMessage is TPresmasterMessageUnknown then
    ReadUnknown(FMessage as TPresmasterMessageUnknown);
end;

end.
