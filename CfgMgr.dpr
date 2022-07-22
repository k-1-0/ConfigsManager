program CfgMgr;

uses
  Forms,
  Unit1 in 'Unit1.pas' {MainForm},
  Unit2 in 'Unit2.pas' {ProfileForm},
  Unit3 in 'Unit3.pas' {PasswordForm};

{$R *.RES}
{$R manifest.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
