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
end;

procedure TPresmasterSwitcherMessageList.SetItem(const aIndex: integer;
  const aMessage: TPresmasterMessage);
begin
  inherited SetItem(aIndex, aMessage);
end;

end.
