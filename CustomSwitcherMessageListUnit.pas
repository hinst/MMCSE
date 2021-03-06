unit CustomSwitcherMessageListUnit;

interface

uses
  contnrs,

  UAdditionalExceptions,

  CustomSwitcherMessageUnit;

type

  // does not owns its items at all.
  TCustomSwitcherMessageList = class(TObjectList)
  public
    constructor Create; reintroduce;
  protected
    function GetItem(const aIndex: integer): TCustomSwitcherMessage; inline;
    procedure SetItem(const aIndex: integer; const aItem: TCustomSwitcherMessage); inline;
  public
    property Items[const aIndex: integer]: TCustomSwitcherMessage
      read GetItem write SetItem; default;
    procedure FreeClear;
  end;

implementation

constructor TCustomSwitcherMessageList.Create;
begin
  inherited Create(false);
end;

function TCustomSwitcherMessageList.GetItem(const aIndex: integer): TCustomSwitcherMessage;
begin
  result := TCustomSwitcherMessage(inherited GetItem(aIndex));
end;

procedure TCustomSwitcherMessageList.SetItem(const aIndex: integer;
  const aItem: TCustomSwitcherMessage);
begin
  inherited SetItem(aIndex, aItem);
end;

// Use this method to release & remove items
procedure TCustomSwitcherMessageList.FreeClear;
var
  i: integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  Clear;
end;

end.
