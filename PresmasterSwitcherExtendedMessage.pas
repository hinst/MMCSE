unit PresmasterSwitcherExtendedMessage;

interface

uses
  Classes,
  PresmasterSwitcherMessage;

type

  // HEX 00 13
  TPresmasterSwitcherVoiceoverArmCommand = class(TPresmasterMessage)
  protected
    procedure ReadSpecific(const aStream: TStream); override;

  end;

implementation

procedure TPresmasterSwitcherVoiceoverArmCommand.ReadSpecific(const aStream: TStream);
var
  dataSize: byte;
  mixerIndex: byte;
begin
  inherited ReadSpecific(aStream);
  aStream.Read(dataSize, sizeOf(dataSize));
  aStream.Read(mixerIndex, sizeOf(mixerIndex));
end;

end.
