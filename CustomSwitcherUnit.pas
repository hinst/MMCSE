unit CustomSwitcherUnit;

{$DEFINE LOG_MESSAGE_STREAM_BEFORE_DECODING}
{$DEFINE LOG_MESSAGE_CONTENT_BEFORE_PROCESSING}
{$DEFINE LOG_MESSAGE_CONTENT_BEFORE_SENDING}
{$DEFINE LOG_MESSAGE_STREAM_BEFORE_SENDING}
{ $DEFINE NODECODE_MODE}
{ $DEFINE LOG_WARN_ON_NO_RESPONSE}
{ $Define LogProcessReceivedMessageStages}

interface

uses
  SysUtils,
  Classes,

  UAdditionalExceptions,
  UAdditionalTypes,
  UExceptionTracer,
  UStreamUtilities,
  UTextUtilities,

  CustomLogEntity,
  EmptyLogEntity,

  CustomSwitcherMessageUnit,
  CustomSwitcherMessageDecoderUnit,
  CustomSwitcherMessageEncoderUnit;

type
  TCustomSwitcher = class
  public
    constructor Create; virtual;
    procedure Startup; virtual; abstract;
  public type
    TSendResponceMethod = procedure(const aResponce: TStream) of object;
      //< nil stream indicates that there is no message data available at the moment
  protected
    FLog: TEmptyLog;
    FSendMessageMethod: TSendResponceMethod;
    FDecoderClass: TCustomSwitcherMessageDecoderClass;
    FEncoderClass: TCustomSwitcherMessageEncoderClass;
    procedure SetLog(const aLog: TEmptyLog);
    function GetAdditionalMessageLogTags(const aMessage: TCustomSwitcherMessage): string; virtual;
    function SafeDecodeMessage(const aMessage: TStream): TCustomSwitcherMessage;
    function SafeProcessMessage(const aMessage: TCustomSwitcherMessage): TCustomSwitcherMessage;
    function ProcessMessage(const aMessage: TCustomSwitcherMessage): TCustomSwitcherMessage;
      virtual; abstract;
    function SafeEncodeMessage(const aMessage: TCustomSwitcherMessage): TStream;
    function SafeSendMessage(const aMessage: TStream): boolean;
    procedure ProcessReceivedMessage(const aMessage: TStream);
    procedure LogProcessReceivedMessageStages(const aText: string); inline;
  public
      // external log assignment scheme
    property Log: TEmptyLog read FLog write FLog;
    property SendMessageMethod: TSendResponceMethod
      read FSendMessageMethod write FSendMessageMethod;
    property DecoderClass: TCustomSwitcherMessageDecoderClass read FDecoderClass;
    property EncoderClass: TCustomSwitcherMessageEncoderClass read FEncoderClass;
    procedure ReceiveMessage(const aMessage: TStream);
    destructor Destroy; override;
  end;

  TCustomSwitcherClass = class of TCustomSwitcher;

implementation

constructor TCustomSwitcher.Create;
begin
  inherited Create;
  FLog := TEmptyLog.Create;
  {$IFDEF NOENCODE_MODE}
  Log.Write(Log.StandardTag.Warning, 'No encode mode defined');
  {$ENDIF}
end;

procedure TCustomSwitcher.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(FLog, aLog);
end;

function TCustomSwitcher.GetAdditionalMessageLogTags(const aMessage: TCustomSwitcherMessage)
  : string;
begin
  result := '';
  //< no additional tags by default
end;

function TCustomSwitcher.SafeDecodeMessage(const aMessage: TStream): TCustomSwitcherMessage;
begin
  result := nil;
  try
    AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
    AssertAssigned(DecoderClass, 'DecoderClass', TVariableType.Prop);
    StreamRewind(aMessage);
    result := DecoderClass.DecodeThis(aMessage);
    AssertAssigned(result, 'result', TVariableType.Local);
  except
    on e: Exception do
    begin
      Log.Write(
        'ERROR',
        'Exception while decoding message stream: '
         + sLineBreak + GetExceptionInfo(e)
         + sLineBreak + 'Stream is: ' + StreamToText(aMessage, true));
    end;
  end;
end;

function TCustomSwitcher.SafeProcessMessage(const aMessage: TCustomSwitcherMessage)
  : TCustomSwitcherMessage;
begin
  result := nil;
  try
    result := ProcessMessage(aMessage);
  except
    on e: Exception do
      Log.Write(
        'ERROR',
        'While processing message'
         + sLineBreak + 'Message: ' + aMessage.ToText
         + sLineBreak + GetExceptionInfo(e)
      );
  end;
end;

function TCustomSwitcher.SafeEncodeMessage(const aMessage: TCustomSwitcherMessage): TStream;
begin
  result := nil;
  try
    AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
    AssertAssigned(EncoderClass, 'EncoderClass', TVariableType.Prop);
    result := EncoderClass.EncodeThis(aMessage);
    AssertAssigned(result, 'result', TVariableType.Local);
  except
    on e: Exception do
      Log.Write(
        TCustomLog.StandardTag.Error,
        'While encoding message'
         + sLineBreak + 'Message: ' + aMessage.ToText
         + sLineBreak + GetExceptionInfo(e)
      );
  end;
end;

function TCustomSwitcher.SafeSendMessage(const aMessage: TStream): boolean;
begin
  result := false;
  try
    AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
    AssertAssigned(@SendMessageMethod, 'SendMessageMethod', TVariableType.Prop);
    {$IFDEF LOG_MESSAGE_STREAM_BEFORE_SENDING}
    Log.Write('send message stream', StreamToText(aMessage, true));
    {$ENDIF}
    StreamRewind(aMessage);
    SendMessageMethod(aMessage);
    result := true;
  except
    on e: Exception do
      Log.Write('ERROR',
        'While sending message'
         + sLineBreak + 'Message: ' + StreamToText(aMessage, true)
         + sLineBreak + GetExceptionInfo(e)
      );
  end;
end;

procedure TCustomSwitcher.ProcessReceivedMessage(const aMessage: TStream);
  procedure lprms(const s: string);
  begin
    LogProcessReceivedMessageStages(s);
  end;
var
  messge: TCustomSwitcherMessage;
  answerMessage: TCustomSwitcherMessage;
  encodedAnswerMessage: TStream;
  seamr: boolean; // sendEncodedAnswerMessageResult
begin
  lprms('Received');
  {$IFDEF LOG_MESSAGE_STREAM_BEFORE_DECODING}
  Log.Write('receive message stream', StreamToText(aMessage, true));
  {$ENDIF}
  {$IFDEF NODECODE_MODE}
  exit;
  {$ENDIF}
  lprms('Decoding...');
  messge := SafeDecodeMessage(aMessage);
  if messge = nil then
    exit;
  {$IFDEF LOG_MESSAGE_CONTENT_BEFORE_PROCESSING}
  Log.Write(
    SpacedStrings(['receive message content', GetAdditionalMessageLogTags(messge)]),
    messge.ToText
  );
  {$ENDIF}
  lprms('Processing...');
  answerMessage := SafeProcessMessage(messge);
  messge.Free;
  if answerMessage = nil then
  begin
    {$IFDEF LOG_WARN_ON_NO_RESPONSE}
    Log.Write('WARN', 'No responce for this message');
    {$ENDIF}
    lprms('End of routine: no answer');
    exit;
  end;
  {$IFDEF LOG_MESSAGE_CONTENT_BEFORE_SENDING}
  Log.Write(
    SpacedStrings(['send message content', GetAdditionalMessageLogTags(answerMessage)]),
    answerMessage.ToText
  );
  {$ENDIF}
  lprms('Encoding...');
  encodedAnswerMessage := SafeEncodeMessage(answerMessage);
  answerMessage.Free;
  if encodedAnswerMessage = nil then
    exit;
  StreamRewind(encodedAnswerMessage);
  lprms('Sending...');
  seamr := SafeSendMessage(encodedAnswerMessage);
  encodedAnswerMessage.Free;
  if not seamr then
    exit;
  lprms('End of routine.');
end;

procedure TCustomSwitcher.LogProcessReceivedMessageStages(const aText: string);
begin
  {$IFDEF LogProcessReceivedMessageStages}
  Log.Write('process stages', aText);
  {$ENDIF}
end;

procedure TCustomSwitcher.ReceiveMessage(const aMessage: TStream);
begin
  ProcessReceivedMessage(aMessage);
end;

destructor TCustomSwitcher.Destroy;
begin
  FreeAndNil(FLog);
  inherited Destroy;
end;

initialization
finalization
end.
