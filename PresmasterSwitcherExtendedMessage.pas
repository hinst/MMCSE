unit PresmasterSwitcherExtendedMessage;

interface

uses
  Classes,
  PresmasterSwitcherMessage;

type

  TPresmasterSwitcherExtendedCommand = class(TPresmasterMessage)
  public
    procedure ReadSpecific(const aStream: TStream); overload; override;
  protected
    procedure ReadSpecific(const aStream: TStream; const aDataLength: byte); overload; virtual;
  end;

  // HEX 00 13
  TPresmasterSwitcherVoiceoverArmCommand = class(TPresmasterSwitcherExtendedCommand)
  protected
    procedure ReadSpecific(const aStream: TStream; const aDataLength: byte); overload; override;
  end;

  // HEX 08 13
  TPresmasterSwitchVoiceoverArmCommandAnswer = class(TPresmasterMessage)
  protected
    procedure WriteSpecific(const aStream: TStream); override;
  end;

implementation

procedure TPresmasterSwitcherExtendedCommand.ReadSpecific(const aStream: TStream);
var
  dataLength: byte;
  mixerIndex: byte;
begin
  inherited ReadSpecific(aStream);
  aStream.Read(dataLength, sizeOf(dataLength));
  ReadSpecific(aStream, dataLength);
end;

procedure TPresmasterSwitcherExtendedCommand.ReadSpecific(const aStream: TStream;
  const aDataLength: byte);
begin
end;


procedure TPresmasterSwitcherVoiceoverArmCommand.ReadSpecific(const aStream: TStream;
  const aDataLength: byte);
var
  mixerIndex: byte;
begin
  inherited ReadSpecific(aStream, aDataLength);
  aStream.Read(mixerIndex, sizeOf(mixerIndex));
end;


procedure TPresmasterSwitchVoiceoverArmCommandAnswer.WriteSpecific(const aStream: TStream);
begin
  inherited WriteSpecific(aStream);

end;


end.
