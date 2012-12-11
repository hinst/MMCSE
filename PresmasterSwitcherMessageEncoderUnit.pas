unit PresmasterSwitcherMessageEncoderUnit;

interface

uses
  Classes,

  CustomSwitcherMessageUnit,
  CustomSwitcherMessageEncoderUnit,
  PresmasterSwitcherMessage;

type
  TPresmasterSwitcherMessageEncoder = class(TCustomSwitcherMessageEncoder)
  public
    constructor Create(const aMessage: TCustomSwitcherMessage); override;
  protected
    FMessage: TPresmasterMessage;
    procedure Encode; override;
    procedure WriteMessageFormat;
    procedure WriteSimpleMessage;
    procedure WriteSimpleMessageCommand;
    procedure WriteExtendedMessage;
  end;

implementation

constructor TPresmasterSwitcherMessageEncoder.Create(const aMessage: TCustomSwitcherMessage);
begin
  inherited Create(aMessage);
  FStream := TMemoryStream.Create;
end;

procedure TPresmasterSwitcherMessageEncoder.Encode;
begin
  WriteMessageFormat;
  if FMessage.Format = FMessage.FormatSimple then
    WriteSimpleMessage;
  if FMessage.Format = FMessage.FormatExtended then
    WriteExtendedMessage;
end;

procedure TPresmasterSwitcherMessageEncoder.WriteMessageFormat;
var
  format: byte;
begin
  Assert(FMessage.IsValidFormat, 'Message format invalid');
  format := FMessage.Format;
  Stream.Write(format, 1);
end;

procedure TPresmasterSwitcherMessageEncoder.WriteSimpleMessage;
var
  transformedMessage: TPresmasterMessage;
begin
  WriteSimpleMessageCommand;
  transformedMessage := FMessage.Transform;
end;

procedure TPresmasterSwitcherMessageEncoder.WriteSimpleMessageCommand;
var
  command: byte;
begin
  command := FMessage.Command;
  Stream.Write(command, 1);
end;

procedure TPresmasterSwitcherMessageEncoder.WriteExtendedMessage;
begin
  // not implemented
end;

end.
