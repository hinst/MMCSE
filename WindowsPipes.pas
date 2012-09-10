unit WindowsPipes;

interface

uses
  Windows, SysUtils;

type
  ECannotCreatePipe = class(Exception);
  EInvalidPipe = class(Exception);
  ECannotReadPipe = class(Exception);
  EConnectionFailure = class(Exception);

  TCommonPipe = class
  public
    constructor Create(const aName: string); reintroduce;
  protected
    fName: string;
    fPipe: THandle;
  public
    property Name: string read fName;
    property Pipe: THandle read fPipe;
    procedure AssertPipeCreated;
  end;

implementation

constructor TCommonPipe.Create(const aName: string);
begin
  inherited Create;
  fName := aName;
end;

procedure TCommonPipe.AssertPipeCreated;
begin
  if Pipe = INVALID_HANDLE_VALUE then
    raise EInvalidPipe.Create('');
end;

end.
