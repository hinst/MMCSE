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
    procedure ProcessMessage(const aMessage: TStream); override;
  end;


implementation

procedure TPresmasterSwitcher.Startup;
begin
  Log.Write('Starting up Presmaster switcher...');
end;

procedure TPresmasterSwitcher.ProcessMessage(const aMessage: TStream);
begin

end;

initialization
  RegisterSwitcherClass(TPresmasterSwitcher);
end.
