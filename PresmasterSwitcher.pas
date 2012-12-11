unit PresmasterSwitcher;

{ $DEFINE LOG_MESSAGE_ON_STARTUP}

interface

uses
  Classes,

  UAdditionalExceptions,
  UTextUtilities,

  CustomSwitcherMessageUnit,
  CustomSwitcherUnit,
  CustomSwitcherFactoryUnit,
  PresmasterSwitcherMessage,
  PresmasterSwitcherMessageDecoderUnit,
  PresmasterSwitcherMessageEncoderUnit;

type
  TPresmasterSwitcher = class(TCustomSwitcher)
  public
    constructor Create; override;
    procedure Startup; override;
  protected
    function GetAdditionalMessageLogTags(const aMessage: TCustomSwitcherMessage): string; overload;
      override;
    function GetAdditionalMessageLogTags(const aMessage: TPresmasterMessage): string; overload;
    function CreatePollingAnswer: TPresmasterMessage;
    function ProcessMessage(const aMessage: TCustomSwitcherMessage): TCustomSwitcherMessage;
      overload; override;
    function ProcessMessage(const aMessage: TPresmasterMessage): TPresmasterMessage; overload;
  end;


implementation

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
  if aMessage.IsPolling then
    AppendSpaced(result, aMessage.PollingTag);
end;

function TPresmasterSwitcher.CreatePollingAnswer: TPresmasterMessage;
begin
  result := TPresmasterMessagePollAnswer.Create;
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
  if aMessage.IsPolling then
    result := CreatePollingAnswer;
end;

initialization
  RegisterSwitcherClass(TPresmasterSwitcher);
end.
