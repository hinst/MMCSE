unit M2100Message;

interface

uses
  SysUtils,
  Classes,
  Contnrs,

  CustomSwitcherMessageUnit,
  M2100Command;

type
  TM2100Message = class(TCustomSwitcherMessage)
  public
    constructor Create;
  public
    STX: byte;
    IsDoubleLength: boolean;
    Length: integer;
    Commands: TObjectList;
    CheckSum: byte;
  protected
    function ToTextInternal: string; override;
  public
    function CommandsToText: string;
    function IsAcknowledged: boolean;
    class function TwosComponent(const aSum: byte): byte;
    destructor Destroy; override;
  end;

  EM2100Message = class(Exception);

implementation

constructor TM2100Message.Create;
begin
  inherited Create;
  Commands := TObjectList.Create(true);
end;

function TM2100Message.ToTextInternal: string;
begin
  result := 'M2100-Msg {';
  if IsAcknowledged then
  begin
    result := result + 'Acknowledged';
  end
  else
  begin
    result := result + 'STX=$' + IntToHex(stx, 2);
    result := result + ' |' + IntToStr(Length);
    if IsDoubleLength then
      result := result + '/'
    else
      result := result + '|';
    if Commands.Count > 0 then
      result := result + ' ' + CommandsToText + ' ';
    result := result + '+$' + IntToHex(CheckSum, 2);
  end;
  result := result + '}';
end;

function TM2100Message.CommandsToText: string;
var
  i: integer;
begin
  result := '';
  for i := 0 to Commands.Count - 1 do
    result := result + TM2100Command(Commands[i]).ToText;
end;

function TM2100Message.IsAcknowledged: boolean;
var
  i: integer;
  command: TM2100Command;
begin
  if STX = M2100MessageCommandClass_ACKNOWLEDGED then
  begin
    result := true;
    exit;
  end;
  if Commands.Count = 0 then
  begin
    result := false;
    exit;
  end;
  result := true;
  for i := 0 to Commands.Count - 1 do
  begin
    command := Commands[i] as TM2100Command;
    result := result and (command.CommandClass = M2100MessageCommandClass_ACKNOWLEDGED);
  end;  
end;

class function TM2100Message.TwosComponent(const aSum: byte): byte;
var
  x: integer;
begin
  x := aSum;
  x := 256 - x;
  result := x and $00FF; 
end;

destructor TM2100Message.Destroy;
begin
  Commands.Free;
  inherited Destroy;
end;

end.
