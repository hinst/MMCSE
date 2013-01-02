unit PresmasterSwitcherMessageDecoderUnit;

{$Define DecodeMessageDetailedLog}

interface

uses
  SysUtils,
  Classes,

  UAdditionalTypes,
  UAdditionalExceptions,
  UStreamUtilities,

  CustomSwitcherMessageUnit,
  CustomSwitcherMessageListUnit,
  CustomSwitcherMessageDecoderUnit,
  PresmasterSwitcherMessage,
  PresmasterSwitcherMessageListUnit;

type
  TPresmasterSwitcherMessageDecoder = class(TCustomSwitcherMessageDecoder)
  public
    constructor Create(const aStream: TStream); override;
  protected
    FMessages: TPresmasterSwitcherMessageList;
    function GetResults: TCustomSwitcherMessageList; override;
    function GetLatestMessage: TPresmasterMessage; inline;
    procedure SetLatestMessage(const aMessage: TPresmasterMessage); inline;
    procedure DecodeMessages;
    procedure DecodeMessage;
    procedure ReadFormatField;
    procedure ReadCommandField;
    procedure ResolveSpecific;
    procedure ReadSimpleCommand;
    procedure ReadExtendedCommand;
    procedure ReadSimpleSetMessageTail;
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
  result := FMessages[FMessages.Count - 1];
end;

procedure TPresmasterSwitcherMessageDecoder.SetLatestMessage(const aMessage: TPresmasterMessage);
begin
  FMessages[FMessages.Count - 1] := aMessage;
end;

procedure TPresmasterSwitcherMessageDecoder.DecodeMessages;
begin
  Log.Write('***Decode messages...');
  while GetRemainingSize(Stream) > 0 do
  begin
    FMessages.Add(TPresmasterMessage.Create);
    Log.Write('***Decode message [...]');
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
  {}LogWrite('ReadFormatField...');
  ReadFormatField;
  {}LogWrite('ReadCommandField...');
  ReadCommandField;
  {}LogWrite('ResolveSpecific...');
  ResolveSpecific;
  {}LogWrite('LatestMessage.Specific...');
  LatestMessage.ReadSpecific(Stream);
  {}LogWrite('Decoded.');
end;

procedure TPresmasterSwitcherMessageDecoder.ReadFormatField;
var
  messageFormat: byte;
begin
  Stream.ReadBuffer(messageFormat, 1);
  LatestMessage.Format := messageFormat;
  Assert(LatestMessage.IsValidFormat);
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
  TPresmasterMessage.ResolveSpecific(m);
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

procedure TPresmasterSwitcherMessageDecoder.Decode;
begin
  DecodeMessages;
end;

end.
