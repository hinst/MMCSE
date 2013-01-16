unit PresmasterSwitcherMessageListUnit;

interface

uses
  UAdditionalExceptions,
  CustomSwitcherMessageUnit,
  CustomSwitcherMessageListUnit,
  PresmasterSwitcherMessage;

type
  TPresmasterSwitcherMessageList = class(TCustomSwitcherMessageList)
  protected
    function GetItem(const aIndex: integer): TPresmasterMessage; inline;
    procedure SetItem(const aIndex: integer; const aMessage: TPresmasterMessage);
  public
    property Items[const i: integer]: TPresmasterMessage read GetItem write SetItem; default;
  end;

implementation

function TPresmasterSwitcherMessageList.GetItem(const aIndex: integer): TPresmasterMessage;
begin
  result := TPresmasterMessage(inherited GetItem(aIndex));
  if result <> nil then
    AssertType(result, TPresmasterMessage);
end;

procedure TPresmasterSwitcherMessageList.SetItem(const aIndex: integer;
  const aMessage: TPresmasterMessage);
begin
  if aMessage <> nil then
    AssertType(aMessage as TObject, TPresmasterMessage);
  inherited SetItem(aIndex, aMessage);
end;

end.
