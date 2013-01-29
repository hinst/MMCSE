unit PresmasterSwitcherExtendedMessage;

interface

uses
  SysUtils,
  Classes,
  UMath,
  PresmasterSwitcherMessage;

type

  TPresmasterSwitcherExtendedCommand = class(TPresmasterMessage)
  public
    procedure ReadSpecific(const aStream: TStream); overload; override;
  public const
    LogDebugChecksumVerification = true;
  public type
    EChecksumIncorrect = class(Exception);
  protected
      // this method rewinds the specified stream to the initial position,
      // so after calling it the stream Position property remains unchanged 
    procedure AssertChecksum(const aStream: TStream; const aDataLength: Byte);
    function VerifyChecksum(const aStream: TStream; const aDataLength: Byte;
      out actualSum, specifiedSum: Byte): boolean;
      // no autorewind in this function
    class function DebugChecksumMessage(const aActual, aSpecified: Byte): string;
    class function EvaluateChecksum(const aStream: TStream; const aDataLength: Byte): Byte;
      // this method is meant to be overridden in descendant classes
    procedure ReadSpecific(const aStream: TStream; const aDataLength: Byte); overload; virtual;
  end;

  // HEX 00 13
  TPresmasterSwitcherVoiceoverArmCommand = class(TPresmasterSwitcherExtendedCommand)
  protected
    FMixerIndex: Byte;
    FMixerState: Byte;
    procedure ReadSpecific(const aStream: TStream; const aDataLength: Byte); overload; override;
  public
    property MixerIndex: Byte read FMixerIndex;
    property MixerState: Byte read FMixerState;
  end;

  // HEX 08 13
  TPresmasterSwitchVoiceoverArmCommandAnswer = class(TPresmasterMessage)
  public
    constructor Create; override;
  protected
    procedure WriteSpecific(const aStream: TStream); override;
  end;

implementation

procedure TPresmasterSwitcherExtendedCommand.ReadSpecific(const aStream: TStream);
var
  dataLength: Byte;
  mixerIndex: Byte;
begin
  inherited ReadSpecific(aStream);
  aStream.Read(dataLength, sizeOf(dataLength));
  AssertChecksum(aStream, dataLength);
  ReadSpecific(aStream, dataLength);
end;

procedure TPresmasterSwitcherExtendedCommand.AssertChecksum(const aStream: TStream;
  const aDataLength: Byte);
var
  checksumCorrect: boolean;
  actual, specified: byte;
begin
  checksumCorrect := VerifyChecksum(aStream, aDataLength, actual, specified);
  if not checksumCorrect then
    raise EChecksumIncorrect.Create( DebugChecksumMessage(actual, specified) );
end;

function TPresmasterSwitcherExtendedCommand.VerifyChecksum(const aStream: TStream;
  const aDataLength: Byte; out actualSum, specifiedSum: Byte): boolean;
var
  initialPosition: Int64;
begin
  initialPosition := aStream.Position;
  actualSum := EvaluateChecksum(aStream, aDataLength); // evaluate actual sum
  aStream.ReadBuffer(specifiedSum, sizeOf(specifiedSum)); // read specified sum
  result := specifiedSum = actualSum;
  if LogDebugChecksumVerification then
    log.Write( DebugChecksumMessage(actualSum, specifiedSum) );
  aStream.Position := initialPosition;
end;

class function TPresmasterSwitcherExtendedCommand.DebugChecksumMessage(
  const aActual, aSpecified: Byte): string;
begin
  result :=
    'Checksum: actual = '
    + IntToHex(aActual, CountOfHexadecimalDigits(aActual))
    + ' = '
    + IntToHex(aSpecified, CountOfHexadecimalDigits(aSpecified))
    + ' = specified';
end;

class function TPresmasterSwitcherExtendedCommand.EvaluateChecksum(const aStream: TStream;
  const aDataLength: Byte): Byte;
var
  i: Byte;
  current, sum: Byte;
begin
  sum := 0;
  for i := 1 to aDataLength do
  begin
    aStream.Read(current, sizeOf(current));
    sum := OverflowAdd(sum, current);
  end;
  sum := sum and $7F;
  result := sum;
end;

procedure TPresmasterSwitcherExtendedCommand.ReadSpecific(const aStream: TStream;
  const aDataLength: Byte);
begin
end;


procedure TPresmasterSwitcherVoiceoverArmCommand.ReadSpecific(const aStream: TStream;
  const aDataLength: Byte);
begin
  inherited ReadSpecific(aStream, aDataLength);
  aStream.Read(FMixerIndex, sizeOf(FMixerIndex));
  aStream.Read(FMixerState, sizeOf(FMixerState));
end;


constructor TPresmasterSwitchVoiceoverArmCommandAnswer.Create;
begin
  inherited Create;
  Command := AnswerVoiceoverArmCommand;
end;

procedure TPresmasterSwitchVoiceoverArmCommandAnswer.WriteSpecific(const aStream: TStream);
begin
  inherited WriteSpecific(aStream);

end;


end.
