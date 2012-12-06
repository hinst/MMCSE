unit CustomSwitcherUnit;

{ $DEFINE LOG_MESSAGE_STREAM_BEFORE_PROCESSING}

interface

uses
  SysUtils,
  Classes,

  UAdditionalExceptions,
  UAdditionalTypes,
  UExceptionTracer,
  UStreamUtilities,

  CustomLogEntity,
  EmptyLogEntity,

  CustomSwitcherMessageUnit,
  CustomSwitcherMessageDecoderUnit,
  CustomSwitcherMessageEncoderUnit;

type
  TCustomSwitcher = class
  public
    constructor Create;
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
    function SafeDecodeMessage(const aMessage: TStream): TCustomSwitcherMessage;
    function SafeProcessMessage(const aMessage: TCustomSwitcherMessage): TCustomSwitcherMessage;
    function ProcessMessage(const aMessage: TCustomSwitcherMessage): TCustomSwitcherMessage;
      virtual; abstract;
    function SafeSendMessage(const aMessage: TCustomSwitcherMessage): boolean;
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
end;

procedure TCustomSwitcher.SetLog(const aLog: TEmptyLog);
begin
  ReplaceLog(FLog, aLog);
end;

function TCustomSwitcher.SafeDecodeMessage(const aMessage: TStream): TCustomSwitcherMessage;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  AssertAssigned(DecoderClass, 'DecoderClass', TVariableType.Prop);
  try
    result := DecoderClass.DecodeThis(aMessage);
    AssertAssigned(result, 'result', TVariableType.Local);
  except
    on e: Exception do
    begin
      try
        StreamRewind(aMessage);
      except end;
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
  try
    result := ProcessMessage(aMessage);
  except
    on e: Exception do
      Log.Write('ERROR', 'While processing message ' + aMessage.ToText);
  end;
end;

function TCustomSwitcher.SafeSendMessage(const aMessage: TCustomSwitcherMessage): boolean;
begin

end;

(*
procedure TM2100Switcher.SendMessage(const aMessage: TM2100Message);
var
  stream: TStream;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  stream := TM2100MessageEncoder.Encode(aMessage);
  {$IFDEF LOG_MESSAGE_CONTENT_BEFORE_SENDING}
  Log.Write(
    SpacedStrings(['Sending', GetAdditionalMessageLogTags(aMessage)]),
    aMessage.ToText
  );
  {$ENDIF}
  {$IFDEF LOG_MESSAGE_STREAM_BEFORE_SENGING}
  StreamRewind(stream);
  Log.Write('send message', 'Now sending message ' + StreamToText(stream));
  {$ENDIF}
  SafeSendMessage(stream);
  stream.Free;
end;
*)

procedure TCustomSwitcher.ReceiveMessage(const aMessage: TStream);
var
  messge: TCustomSwitcherMessage;
  answerMessage: TCustomSwitcherMessage;
begin
  AssertAssigned(aMessage, 'aMessage', TVariableType.Argument);
  {$IFDEF LOG_MESSAGE_STREAM_BEFORE_PROCESSING}
  StreamRewind(aMessage);
  Log.Write('Now processing message stream: ' + StreamToText(aMessage) + '...');
  {$ENDIF}
  messge := SafeDecodeMessage(aMessage);
  answerMessage := SafeProcessMessage(messge);
  messge.Free;
  if answerMessage = nil then
    Log.Write('No responce for this message')
  else
    SafeSendMessage(answerMessage);
  answerMessage.Free;
end;

destructor TCustomSwitcher.Destroy;
begin
  FreeAndNil(FLog);
  inherited Destroy;
end;

initialization
finalization
end.
