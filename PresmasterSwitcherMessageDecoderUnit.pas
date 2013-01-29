unit PresmasterSwitcherMessageDecoderUnit;

{ $Define DecodeMessageDetailedLog}

interface

uses
  SysUtils,
  Classes,

  UAdditionalTypes,
  UAdditionalExceptions,
  UStreamUtilities,
  UTextUtilities,

  CustomSwitcherMessageUnit,
  CustomSwitcherMessageListUnit,
  CustomSwitcherMessageDecoderUnit,
  PresmasterSwitcherMessage,
  PresmasterSwitcherExtendedMessage,
  PresmasterSwitcherMessageListUnit;

type
  TPresmasterSwitcherMessageDecoder = class(TCustomSwitcherMessageDecoder)
  public
    constructor Create(const aStream: TStream); override;
  protected
    FMessages: TPresmasterSwitcherMessageList;
    function GetResults: TCustomSwitcherMessageList; override;
    function GetLatestMessage: TPresmasterMessage;
    procedure SetLatestMessage(const aMessage: TPresmasterMessage); inline;
    procedure DecodeMessages;
    procedure DecodeMessage;
    procedure ReadFormatField;
    procedure ReadCommandField;
    procedure ResolveSpecific; overload;
    procedure ReadSpecific;
    procedure ReadSimpleCommand;
    procedure ReadExtendedCommand;
    procedure ReadSimpleSetMessageTail;

    {$Region Resolving capabilities}
      // metohd: CLASS <-> HEX CODE
    class function DetectClass(const aFormat: Byte; const aCommand: Word): TPresmasterMessageClass;
    class function CreateSpecific(const aMessage: TPresmasterMessage): TPresmasterMessage;
    class procedure ResolveSpecific(var aResult: TPresmasterMessage); overload;
    {$EndRegion}
  public
    property LatestMessage: TPresmasterMessage read GetLatestMessage write SetLatestMessage;
    procedure Decode; override;
  end;


implementation

constructor TPresmasterSwitcherMessageDecoder.Create(const aStream: TStream);
begin
  inherited Create(aStream);
  FMessages := TPresmasterSwitcherMessageList.Create;
end;

function TPresmasterSwitcherMessageDecoder.GetResults: TCustomSwitcherMessageList;
begin
  result := FMessages;
end;

function TPresmasterSwitcherMessageDecoder.GetLatestMessage: TPresmasterMessage;
begin
  AssertAssigned(FMessages, 'FMessages', TVariableType.Field);
  Assert(FMessages.Count > 0, 'Can not GetLatestMessage: FMessages.Count > 0 failed');
  result := FMessages[FMessages.Count - 1];
end;

procedure TPresmasterSwitcherMessageDecoder.SetLatestMessage(const aMessage: TPresmasterMessage);
begin
  FMessages[FMessages.Count - 1] := aMessage;
end;

procedure TPresmasterSwitcherMessageDecoder.DecodeMessages;
var
  nextMessage: TPresmasterMessage;
begin
  while GetRemainingSize(Stream) > 0 do
  begin
    AssertAssigned(FMessages, 'FMessages', TVariableType.Field);
    nextMessage := TPresmasterMessage.Create;
    FMessages.Add(nextMessage);
    DecodeMessage;
  end;
end;

procedure TPresmasterSwitcherMessageDecoder.DecodeMessage;
  procedure LogWrite(const s: string);
  begin
    {$IfDef DecodeMessageDetailedLog}
    Log.Write('TPresmasterSwitcherMessageDecoder.DecodeMessage', s);
    {$EndIf}
  end;
begin
  {$REGION LOG}LogWrite('ReadFormatField...');{$ENDREGION}
  ReadFormatField;
  {$REGION LOG} LogWrite('ReadCommandField...'); {$ENDREGION}
  ReadCommandField;
  {$REGION} LogWrite('ResolveSpecific...'); {$ENDREGION}
  ResolveSpecific;
  {$REGION} LogWrite('LatestMessage.Specific...'); {$ENDREGION}
  ReadSpecific;
  {$REGION} LogWrite('Decoded.'); {$ENDREGION}
end;

procedure TPresmasterSwitcherMessageDecoder.ReadFormatField;
var
  messageFormat: byte;
  latestMessage: TPresmasterMessage;
begin
  latestMessage := self.LatestMessage;
  AssertAssigned(latestMessage, 'latestMessage', TVariableType.Local);
  AssertAssigned(Stream, 'Stream', TVariableType.Prop);
  Stream.ReadBuffer(messageFormat, 1);
  latestMessage.Format := messageFormat;
  Assert(latestMessage.IsValidFormat);
end;

procedure TPresmasterSwitcherMessageDecoder.ReadCommandField;
begin
  if LatestMessage.Format = TPresmasterMessage.FormatSimple then
    ReadSimpleCommand;
  if LatestMessage.Format = TPresmasterMessage.FormatExtended then
    ReadExtendedCommand;
end;

procedure TPresmasterSwitcherMessageDecoder.ResolveSpecific;
var
  m: TPresmasterMessage;
begin
  m := LatestMessage;
  AssertAssigned(m, 'm', TVariableType.Local);
  ResolveSpecific(m);
  LatestMessage := m;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadSimpleCommand;
var
  command: byte;
begin
  Stream.ReadBuffer(command, 1);
  LatestMessage.Command := command;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadExtendedCommand;
var
  command: word;
begin
  Stream.ReadBuffer(command, 2);
  ReverseWord(command);
  LatestMessage.Command := command;
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

class function TPresmasterSwitcherMessageDecoder.DetectClass(const aFormat: Byte;
  const aCommand: Word): TPresmasterMessageClass;
const
  Simple = TPresmasterMessage.FormatSimple;
  Extended = TPresmasterMessage.FormatExtended;
var
  command: word;
begin
  result := nil;
  {$Region TypeDetection}
  with TPresmasterMessage do
  begin
    {$Region Simple Format}
    if (aFormat = Simple) and (aCommand = SetTransitionType) then
      result := TPresmasterMessageSwitchTransitionType;
    if (aFormat = Simple) and (aCommand = PollCommand) then
      result := TPresmasterMessagePoll;
    if (aFormat = Simple) and (aCommand = SetTXVideo) then
      result := TPresmasterMessageSwitchVideo;
    if (aFormat = Simple) and (aCommand = SetTXAudio) then
      result := TPresmasterMessageSwitchAudio;
    if (aFormat = Simple) and (aCommand = SetPresetVideo) then
      result := TPresmasterMessageSwitchPresetVideo;
    if (aFormat = Simple) and (aCommand = SetPresetAudio) then
      result := TPresmasterMessageSwitchPresetAudio;
    {$EndRegion}
    {$Region Extended Format}
    if (aFormat = Extended) and (aCommand = VoiceoverArmCommand) then
      result := TPresmasterSwitcherVoiceoverArmCommand;
    {$EndRegion}
  end;
  {$EndRegion}
  if result = nil then
    result := TPresmasterMessageUnknown;
end;

class function TPresmasterSwitcherMessageDecoder.CreateSpecific(const aMessage: TPresmasterMessage)
  : TPresmasterMessage;
var
  t: TPresmasterMessageClass;
begin
  t := DetectClass(aMessage.Format, aMessage.Command);
  result := t.Create;
  result.Assign(aMessage);
end;

class procedure TPresmasterSwitcherMessageDecoder.ResolveSpecific(var aResult: TPresmasterMessage);
var
  result: TPresmasterMessage;
begin
  result := CreateSpecific(aResult);
  result.Assign(aResult);
  aResult.Free;
  aResult := result;
end;

procedure TPresmasterSwitcherMessageDecoder.ReadSpecific;
begin
  AssertAssigned(LatestMessage, 'LatestMessage', TVariableType.Prop);
  LatestMessage.ReadSpecific(stream);
end;

procedure TPresmasterSwitcherMessageDecoder.Decode;
begin
  DecodeMessages;
end;

end.
