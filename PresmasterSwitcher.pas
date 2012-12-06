unit PresmasterSwitcher;

interface

uses
  Classes,
  
  CustomSwitcherUnit,
  CustomSwitcherFactoryUnit;

type
  TPresmasterSwitcher = class(TCustomSwitcher)
  public
    procedure Startup; override;
  end;


implementation

procedure TPresmasterSwitcher.Startup;
begin
  Log.Write('Starting up Presmaster switcher...');
end;

initialization
  RegisterSwitcherClass(TPresmasterSwitcher);
end.
