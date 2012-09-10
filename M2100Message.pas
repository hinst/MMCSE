unit M2100Message;

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  M2100Command;

type
  TM2100Message = class
  public
    constructor Create;
  public
    STX: byte;
    IsDoubleLength: boolean;
    Length: integer;
    Commands: TObjectList;
    CheckSum: byte;
  public
    function CommandsToText: string;
    function ToText: string;
    destructor Destroy; override;
  end;

implementation

constructor TM2100Message.Create;
begin
  inherited Create;
  Commands := TObjectList.Create(true);
end;

function TM2100Message.CommandsToText: string;
var
  i: integer;
begin
  result := '';
  for i := 0 to Commands.Count - 1 do
    result := result + TM2100Command(Commands[i]).ToText;
end;

function TM2100Message.ToText: string;
begin
  result := 'M2100-Msg {';
  result := result + '$TX=' + IntToHex(stx, 2);
  result := result + ' |' + IntToStr(Length);
  if IsDoubleLength then
    result := result + '/'
  else
    result := result + '|';
  if Commands.Count > 0 then
    result := result + ' ' + CommandsToText + ' ';
  result := result + '}';
end;

destructor TM2100Message.Destroy;
begin
  Commands.Free;
  inherited Destroy;
end;

end.
