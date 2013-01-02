unit PresmasterSwitcherMessageDecoderUnit;

{ $Define DecodeMessageDetailedLog}

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
  while GetRemainingSize(Stream) > 0 do
  begin
    FMessages.Add(TPresmasterMessage.Create);
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
  LatestMessage.ReadSpecific(Stream);
  {$REGION} LogWrite('Decoded.'); {$ENDREGION}
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

procedure TPresmasterSwitcherMessageDecoder.Decode;
begin
  DecodeMessages;
end;

end.
