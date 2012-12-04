unit CustomSwitcherMessageUnit;

interface

uses
  SysUtils;

type
  ESwitcherMessage = class(Exception);

  TCustomSwitcherMessage = class
  public
    constructor Create; virtual;
    function ToText: string; virtual;
  end;

implementation

constructor TCustomSwitcherMessage.Create;
begin
  inherited Create;
end;

function TCustomSwitcherMessage.ToText: string;
begin
  result := 'instanceOf ' + self.ClassName;
end;

end.
