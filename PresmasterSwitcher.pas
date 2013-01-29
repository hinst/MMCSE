unit PresmasterSwitcher;

{ $DEFINE LOG_MESSAGE_ON_STARTUP}

interface

uses
  Classes,

  UAdditionalExceptions,
  UTextUtilities,
  UMath,

  CustomSwitcherMessageUnit,
  CustomSwitcherUnit,
  CustomSwitcherFactoryUnit,
  PresmasterSwitcherMessage,
  PresmasterSwitcherExtendedMessage,
  PresmasterSwitcherMessageDecoderUnit,
  PresmasterSwitcherMessageEncoderUnit;

type
  TPresmasterSwitcher = class(TCustomSwitcher)
  public
    constructor Create; override;
    procedure Startup; override;
  public const
    VoiceoverCount = 10; //< Not sure about this one
  protected
    FVoiceoverStatus: array[0..VoiceoverCount - 1] of Boolean;
    function GetAdditionalMessageLogTags(const aMessage: TCustomSwitcherMessage): string; overload;
      override;
    function GetAdditionalMessageLogTags(const aMessage: TPresmasterMessage): string; overload;
    function ProcessMessage(const aMessage: TCustomSwitcherMessage): TCustomSwitcherMessage;
      overload; override;
    function ProcessMessage(const aMessage: TPresmasterMessage): TPresmasterMessage; overload;
    function ProcessVoiceoverArmCommand(const aMessage: TPresmasterSwitcherVoiceoverArmCommand)
      : TPresmasterSwitcherVoiceoverArmCommandAnswer;
    function SwitchArmState(const aIndex, aState: Byte): Byte;
    procedure CleanVoiceoverStatus;
  end;


implementation

procedure TPresmasterSwitcher.CleanVoiceoverStatus;
var
  i: integer;
begin
  for i := 0 to Length(FVoiceoverStatus) do
    FVoiceoverStatus[i] := False;
end;

constructor TPresmasterSwitcher.Create;
begin
  inherited Create;
end;

procedure TPresmasterSwitcher.Startup;
begin
  {$IFDEF LOG_MESSAGE_ON_STARTUP}
  Log.Write('Starting up Presmaster switcher...');
  {$ENDIF}
  FDecoderClass := TPresmasterSwitcherMessageDecoder;
  FEncoderClass := TPresmasterSwitcherMessageEncoder;  
  CleanVoiceoverStatus;
end;

function TPresmasterSwitcher.GetAdditionalMessageLogTags(const aMessage: TCustomSwitcherMessage)
  : string;
begin
  AssertType(aMessage, TPresmasterMessage);
  result := GetAdditionalMessageLogTags(aMessage as TPresmasterMessage);
end;

function TPresmasterSwitcher.GetAdditionalMessageLogTags(const aMessage: TPresmasterMessage)
  : string;
begin
  result := '';
  if aMessage is TPresmasterMessagePoll then
    AppendSpaced(result, aMessage.PollingTag);
  if aMessage is TPresmasterMessagePollAnswer then
    AppendSpaced(result, aMessage.PollingTag);
end;

function TPresmasterSwitcher.ProcessMessage(const aMessage: TCustomSwitcherMessage)
  : TCustomSwitcherMessage;
begin
  AssertType(aMessage, TPresmasterMessage);
  result := ProcessMessage(aMessage as TPresmasterMessage);
end;

function TPresmasterSwitcher.ProcessMessage(const aMessage: TPresmasterMessage): TPresmasterMessage;
begin
  result := nil;
  if aMessage is TPresmasterMessagePoll then
    result := TPresmasterMessagePollAnswer.Create;
  {$Region SwitchTransitionType}
  if aMessage is TPresmasterMessageSwitchTransitionType then
    result := TPresmasterMessageSwitchTransitionTypeReport.Create(
      (aMessage as TPresmasterMessageSwitchTransitionType).SwitchTo
    );
  {$EndRegion}
  {$Region Switch Preset}
  if aMessage is TPresmasterMessageSwitchPresetVideo then
    result :=
      TPresmasterMessageSwitchPresetVideoAnswer.Create(
        (aMessage as TPresmasterMessageSwitchPresetVideo).SwitchTo
      );
  if aMessage is TPresmasterMessageSwitchPresetAudio then
    result :=
      TPresmasterMessageSwitchPresetAudioAnswer.Create(
        (aMessage as TPresmasterMessageSwitchPresetAudio).SwitchTo
      );
  {$EndRegion}
  if aMessage is TPresmasterSwitcherVoiceoverArmCommand then
    ProcessVoiceoverArmCommand(aMessage as TPresmasterSwitcherVoiceoverArmCommand)
end;

function TPresmasterSwitcher.ProcessVoiceoverArmCommand(
  const aMessage: TPresmasterSwitcherVoiceoverArmCommand)
  : TPresmasterSwitcherVoiceoverArmCommandAnswer;
begin
  result := TPresmasterSwitcherVoiceoverArmCommandAnswer.Create(
      aMessage.Index, SwitchArmState(aMessage.Index, aMessage.State));
end;

function TPresmasterSwitcher.SwitchArmState(const aIndex, aState: Byte): Byte;
begin
  AssertIndex(0, aIndex, Length(FVoiceoverStatus) - 1);
  case aState of
  TPresmasterSwitcherVoiceoverArmCommand.StateDisarm:
    FVoiceoverStatus[aIndex] := False;
  TPresmasterSwitcherVoiceoverArmCommand.StateOpposite:
    Reverse(FVoiceoverStatus[aIndex]);
  end;//of case

  case FVoiceoverStatus[aIndex] of
  false:
    result := TPresmasterSwitcherVoiceoverArmCommandAnswer.StateDisarmed;
  true:
    result := TPresmasterSwitcherVoiceoverArmCommandAnswer.StateArmed;
  end;//of case
end;

initialization
  RegisterSwitcherClass(TPresmasterSwitcher);
end.
