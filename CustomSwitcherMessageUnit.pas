unit CustomSwitcherMessageUnit;

interface

uses
  SysUtils,

  UExceptionTracer;

type
  ESwitcherMessage = class(Exception);

  TCustomSwitcherMessage = class
  public
    constructor Create; virtual;
  protected
    function ToTextInternal: string; virtual;
  public
    function ToText: string;
  end;

implementation

constructor TCustomSwitcherMessage.Create;
begin
  inherited Create;
end;

function TCustomSwitcherMessage.ToTextInternal: string;
begin
  result := 'instance of ' + self.ClassName;
end;

function TCustomSwitcherMessage.ToText: string;
begin
  try
    result := ToTextInternal;
  except
    on e: Exception do
      result := 'Exception while converting this object to text: ' + GetExceptionBrief(e);
  end;
end;

end.
