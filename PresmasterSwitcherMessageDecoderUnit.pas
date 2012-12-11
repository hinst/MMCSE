unit PresmasterSwitcherMessageDecoderUnit;

interface

uses
  SysUtils,
  Classes,

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
    procedure ReadMessageFormat;
    procedure ReadMessageCommand;
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

procedure TPresmasterSwitcherMessageDecoder.ReadMessageFormat;
var
  messageFormat: byte;
begin
  Stream.ReadBuffer(messageFormat, 1);
  FMessage.Format := messageFormat;
  Assert(FMessage.IsValidFormat);
end;

procedure TPresmasterSwitcherMessageDecoder.ReadMessageCommand;
var
  command: byte;
begin
  Stream.ReadBuffer(command, 1);
  FMessage.Command := command;
  if FMessage.IsSimpleSetCommand then
    ReadSimpleSetMessageTail;
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

procedure TPresmasterSwitcherMessageDecoder.Decode;
begin
  ReadMessageFormat;
end;

end.
