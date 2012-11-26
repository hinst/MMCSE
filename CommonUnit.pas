unit CommonUnit;

interface

uses
  SysUtils,
  Classes,
  CustomLogManager;

type
  TGlobalSettings = class
  protected
    FSwitcherClassName: string;
  public
    property SwitcherClassName: string read FSwitcherClassName write FSwitcherClassName;
  end;

var
  GlobalLogManager: TCustomLogManager;

implementation

end.
