unit PresmasterSwitcherExtendedMessage;

interface

uses
  SysUtils,
  Classes,

  UMath,
  UStreamUtilities,
  
  PresmasterSwitcherMessage;

type

  TPresmasterSwitcherExtendedMessage = class(TPresmasterMessage)
  public
    procedure ReadSpecific(const aStream: TStream); overload; override;
    procedure WriteSpecific(const aStream: TStream); overload; override;
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
      // this method is meant to be overridden in descendant classes
    procedure WriteSpecificDescendantPlug(const aStream: TStream); virtual;
    procedure WriteExtendedData(const aStream, aData: TStream); overload;
    procedure WriteExtendedData(const aStream: TStream); overload;
  end;

  // HEX 00 13
  TPresmasterSwitcherVoiceoverArmCommand = class(TPresmasterSwitcherExtendedMessage)
  protected
    FIndex, FState: Byte;
    procedure ReadSpecific(const aStream: TStream; const aDataLength: Byte); overload; override;
  public const
    StateOpposite = $00;
    StateDisarm = $04;
  public
    property Index: Byte read FIndex;
    property State: Byte read FState;
  end;

  // HEX 08 13
  TPresmasterSwitcherVoiceoverArmCommandAnswer = class(TPresmasterSwitcherExtendedMessage)
  public
    constructor Create; overload; override;
    constructor Create(const aIndex, aState: Byte); overload;
  public const
    StateDisarmed = $00;
    StateArmed = $01;
  protected
    FIndex, FState: Byte;
    procedure WriteSpecific(const aStream: TStream); override;
  end;

implementation

procedure TPresmasterSwitcherExtendedMessage.ReadSpecific(const aStream: TStream);
var
  dataLength: Byte;
  mixerIndex: Byte;
begin
  inherited ReadSpecific(aStream);
  aStream.Read(dataLength, sizeOf(dataLength));
  AssertChecksum(aStream, dataLength);
  ReadSpecific(aStream, dataLength);
end;

procedure TPresmasterSwitcherExtendedMessage.WriteSpecific(const aStream: TStream);
begin
  inherited WriteSpecific(aStream);
end;

procedure TPresmasterSwitcherExtendedMessage.AssertChecksum(const aStream: TStream;
  const aDataLength: Byte);
var
  checksumCorrect: boolean;
  actual, specified: byte;
begin
  checksumCorrect := VerifyChecksum(aStream, aDataLength, actual, specified);
  if not checksumCorrect then
    raise EChecksumIncorrect.Create( DebugChecksumMessage(actual, specified) );
end;

function TPresmasterSwitcherExtendedMessage.VerifyChecksum(const aStream: TStream;
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

class function TPresmasterSwitcherExtendedMessage.DebugChecksumMessage(
  const aActual, aSpecified: Byte): string;
begin
  result :=
    'Checksum: actual = '
    + IntToHex(aActual, CountOfHexadecimalDigits(aActual))
    + ' = '
    + IntToHex(aSpecified, CountOfHexadecimalDigits(aSpecified))
    + ' = specified';
end;

class function TPresmasterSwitcherExtendedMessage.EvaluateChecksum(const aStream: TStream;
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

procedure TPresmasterSwitcherExtendedMessage.ReadSpecific(const aStream: TStream;
  const aDataLength: Byte);
begin
end;

procedure TPresmasterSwitcherExtendedMessage.WriteSpecificDescendantPlug(const aStream: TStream);
begin
end;

procedure TPresmasterSwitcherExtendedMessage.WriteExtendedData(const aStream, aData: TStream);
var
  checkSum, dataSize: byte;
begin
  Rewind(aData);
  checkSum := EvaluateChecksum(aData, aData.Size);
  dataSize := Byte(aData.Size);
  Rewind(aData);
  aStream.Write(dataSize, sizeOf(dataSize)); // data size
  aStream.CopyFrom(aData, aData.Size); // data
  aStream.Write(checkSum, sizeOf(checkSum));
end;

procedure TPresmasterSwitcherExtendedMessage.WriteExtendedData(const aStream: TStream);
var
  data: TStream;
begin
  data := TMemoryStream.Create;
  WriteSpecificDescendantPlug(data);
  WriteExtendedData(aStream, data);
  FreeAndNil(data);
end;


procedure TPresmasterSwitcherVoiceoverArmCommand.ReadSpecific(const aStream: TStream;
  const aDataLength: Byte);
begin
  inherited ReadSpecific(aStream, aDataLength);
  aStream.Read(FIndex, sizeOf(FIndex));
  aStream.Read(FState, sizeOf(FState));
end;


constructor TPresmasterSwitcherVoiceoverArmCommandAnswer.Create(const aIndex, aState: Byte);
begin
  Create;
  FIndex := aIndex;
  FState := aState;
end;

constructor TPresmasterSwitcherVoiceoverArmCommandAnswer.Create;
begin
  inherited Create;
  Command := AnswerVoiceoverArmCommand;
end;

procedure TPresmasterSwitcherVoiceoverArmCommandAnswer.WriteSpecific(const aStream: TStream);
begin
  inherited WriteSpecific(aStream);
  aStream.Write(FIndex, sizeOf(FIndex));
  aStream.Write(FState, sizeOf(FState));
end;


end.
