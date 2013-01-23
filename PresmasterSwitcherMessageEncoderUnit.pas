unit PresmasterSwitcherMessageEncoderUnit;

interface

uses
  Classes,

  UAdditionalTypes,
  UAdditionalExceptions,

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
    procedure WriteMessage;
    procedure WriteMessageFormat;
    procedure WriteCommandCode;
    procedure WriteSimpleCommandCode;
    procedure WriteExtendedCommandCode;
    procedure WriteMessageSpecific;
  end;

implementation

constructor TPresmasterSwitcherMessageEncoder.Create(const aMessage: TCustomSwitcherMessage);
begin
  inherited Create(aMessage);
  AssertType(aMessage, TPresmasterMessage);
  FMessage := aMessage as TPresmasterMessage;
  FStream := TMemoryStream.Create;
end;

procedure TPresmasterSwitcherMessageEncoder.Encode;
begin
  WriteMessage;
end;

procedure TPresmasterSwitcherMessageEncoder.WriteMessage;
begin
  WriteMessageFormat;
  WriteCommandCode;
  WriteMessageSpecific;
end;

procedure TPresmasterSwitcherMessageEncoder.WriteMessageFormat;
var
  format: byte;
begin
  Assert(FMessage.IsValidFormat, 'Message format invalid');
  format := FMessage.Format;
  Stream.Write(format, 1);
end;

procedure TPresmasterSwitcherMessageEncoder.WriteCommandCode;
begin
  if FMessage.Format = FMessage.FormatSimple then
    WriteSimpleCommandCode;
  if FMessage.Format = FMessage.FormatExtended then
    WriteExtendedCommandCode;
end;

procedure TPresmasterSwitcherMessageEncoder.WriteSimpleCommandCode;
var
  command: byte;
begin
  command := FMessage.Command;
  Stream.Write(command, 1);
end;

procedure TPresmasterSwitcherMessageEncoder.WriteExtendedCommandCode;
var
  command: word;
begin
  command := FMessage.Command;
end;

procedure TPresmasterSwitcherMessageEncoder.WriteMessageSpecific;
begin
  FMessage.WriteSpecific(Stream);
end;

end.









