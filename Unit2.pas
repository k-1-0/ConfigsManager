unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ProfileClass, ExtCtrls, ComCtrls;

const

  PRESETS_VARS_INFO = 'In target profile path, deleting filenames, application path and application args you may use this embedded variables:' + #13#10#13#10 +
                      '%PROFILE_DIR% .................... profile DB directory' + #13#10 +
                      '%TARGET_CONFIG% ............ target config filename' + #13#10 +
                      '%TARGET_CONFIG_DIR% .... target config directory' + #13#10 +
                      '%APP_FILE% .......................... launching application filename' + #13#10 +
                      '%APP_DIR% ........................... launching application directory' + #13#10#13#10 +
                      'Also system environment variables.';


type
  TProfileForm = class(TForm)
    Label2: TLabel;
    Edit3: TEdit;
    Label3: TLabel;
    Edit2: TEdit;
    CheckBox1: TCheckBox;
    Edit4: TEdit;
    CheckBox2: TCheckBox;
    Label5: TLabel;
    Label6: TLabel;
    GroupBox1: TGroupBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    Button1: TButton;
    Button2: TButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    GroupBox2: TGroupBox;
    RadioButton4: TRadioButton;
    RadioButton5: TRadioButton;
    RadioButton6: TRadioButton;
    RadioButton7: TRadioButton;
    Edit5: TEdit;
    Label7: TLabel;
    Label4: TLabel;
    GroupBox3: TGroupBox;
    Button3: TButton;
    StaticText1: TStaticText;
    CheckBox3: TCheckBox;
    SpeedButton1: TSpeedButton;
    Bevel1: TBevel;
    Label8: TLabel;
    Image1: TImage;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    RadioButton8: TRadioButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    ListBox1: TListBox;
    ListBox2: TListBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton3Click(Sender: TObject);
    procedure RadioButton8Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure SpeedButton8Click(Sender: TObject);
    procedure SpeedButton9Click(Sender: TObject);
    procedure SpeedButton10Click(Sender: TObject);
    function SysActionInputQuery(var ActionString: WideString): Boolean;
    procedure RadioButton7Click(Sender: TObject);
  private
    { Private declarations }
    FProfile: TProfile;
    FbIconChanged, FbIconPresented: Boolean;
    procedure SetControlsState;
  public
    { Public declarations }
  end;


function ShowProfileForm(const bNewProfile: Boolean; var Profile: TProfile): Boolean;


implementation

{$R *.DFM}

uses Utils, Unit3;


function ShowProfileForm(const bNewProfile: Boolean; var Profile: TProfile): Boolean;
var
ProfileForm: TProfileForm;
IconData: TIconData;
i, x, y: Integer;
Actions: TWideStringArray;
begin
ProfileForm:=TProfileForm.Create(Application);
try
  with ProfileForm do
    begin
    if bNewProfile then Caption:='New Profile'
                   else Caption:='Edit Profile "' + Profile.ProfileName + '"';
    FProfile:=Profile;
    Edit2.Text:=FProfile.ProfileName;
    Edit3.Text:=FProfile.TargetConfigFileName;
    Edit4.Text:=FProfile.AppPath;
    Edit5.Text:=FProfile.AppArgs;

    FbIconChanged:=false;
    FbIconPresented:=FProfile.bIconPresented;
    if FProfile.bIconPresented then
      begin
      Image1.Picture.Bitmap.Width:=16;
      Image1.Picture.Bitmap.Height:=16;
      Image1.Picture.Bitmap.TransparentMode:=tmFixed;
      Image1.Picture.Bitmap.Transparent:=true;
      Image1.Picture.Bitmap.TransparentColor:=FProfile.IconData.dwTransparentColor;
      for x:=0 to 15 do
        begin
        for y:=0 to 15 do
          Image1.Picture.Bitmap.Canvas.Pixels[x, y]:=FProfile.IconData.Pixels[x, y];
        end;
      end;

    CheckBox1.Checked:=FProfile.bLaunchApplication;
    CheckBox2.Checked:=FProfile.bDeleteConfigAfterAppEnded;
    CheckBox3.Checked:=FProfile.bUpdateConfigAfterAppEnded;
    case FProfile.AfterLaunchAppAction of
      AFTER_LAUNCH_APP_ACTION_NONE     : RadioButton1.Checked:=true;
      AFTER_LAUNCH_APP_ACTION_MINIMIZE : RadioButton2.Checked:=true;
      AFTER_LAUNCH_APP_ACTION_TRAY     : RadioButton3.Checked:=true;
      AFTER_LAUNCH_APP_ACTION_HIDE     : RadioButton7.Checked:=true;
      AFTER_LAUNCH_APP_ACTION_EXIT     : RadioButton8.Checked:=true;
      end;
    case FProfile.AfterEndingAppAction of
      AFTER_ENDING_APP_ACTION_NONE     : RadioButton4.Checked:=true;
      AFTER_ENDING_APP_ACTION_RESTORE  : RadioButton5.Checked:=true;
      AFTER_ENDING_APP_ACTION_EXIT     : RadioButton6.Checked:=true;
      end;

    Actions:=FProfile.BeforeLaunchAppSysActions;
    for i:=Low(Actions) to High(Actions) do ListBox1.Items.Add(Actions[i]);
    Actions:=FProfile.AfterEndingAppSysActions;
    for i:=Low(Actions) to High(Actions) do ListBox2.Items.Add(Actions[i]);

    if FProfile.Password <> '' then
      begin
      StaticText1.Caption:='Keyword found';
      StaticText1.Font.Color:=clGreen;
      end;

    result:=ShowModal = mrOK;

    if result then
      begin
      FProfile.ProfileName:=Edit2.Text;
      FProfile.TargetConfigFileName:=Edit3.Text;
      FProfile.AppPath:=Edit4.Text;
      FProfile.AppArgs:=Edit5.Text;
      FProfile.bLaunchApplication:=CheckBox1.Checked;
      FProfile.bDeleteConfigAfterAppEnded:=CheckBox2.Checked;
      FProfile.bUpdateConfigAfterAppEnded:=CheckBox3.Checked;

      FProfile.bIconPresented:=FbIconPresented;
      FProfile.bIconChanged:=FbIconChanged;
      if FbIconChanged then
        begin
        if FbIconPresented then
          begin
          IconData.dwTransparentColor:=Image1.Picture.Bitmap.TransparentColor;
          for x:=0 to 15 do
            begin
            for y:=0 to 15 do IconData.Pixels[x, y]:=GetPixel(Image1.Canvas.Handle, x, y);
            end;
          end
        else ZeroMemory(@IconData, SizeOf(IconData));
        FProfile.IconData:=IconData;
        end;

           if RadioButton2.Checked then FProfile.AfterLaunchAppAction:=AFTER_LAUNCH_APP_ACTION_MINIMIZE
      else if RadioButton3.Checked then FProfile.AfterLaunchAppAction:=AFTER_LAUNCH_APP_ACTION_TRAY
      else if RadioButton7.Checked then FProfile.AfterLaunchAppAction:=AFTER_LAUNCH_APP_ACTION_HIDE
      else if RadioButton8.Checked then FProfile.AfterLaunchAppAction:=AFTER_LAUNCH_APP_ACTION_EXIT
      else FProfile.AfterLaunchAppAction:=AFTER_LAUNCH_APP_ACTION_NONE;

           if RadioButton5.Checked then FProfile.AfterEndingAppAction:=AFTER_ENDING_APP_ACTION_RESTORE
      else if RadioButton6.Checked then FProfile.AfterEndingAppAction:=AFTER_ENDING_APP_ACTION_EXIT
      else FProfile.AfterEndingAppAction:=AFTER_ENDING_APP_ACTION_NONE;

      FProfile.ClearBeforeLaunchAppActions;
      if ListBox1.Items.Count > 0 then
        begin
        for i:=0 to ListBox1.Items.Count - 1 do FProfile.AddBeforeLaunchAppAction(ListBox1.Items[i]);
        end;

      FProfile.ClearAfterEndingAppActions;
      if ListBox2.Items.Count > 0 then
        begin
        for i:=0 to ListBox2.Items.Count - 1 do FProfile.AddAfterEndingAppAction(ListBox2.Items[i]);
        end;

      Profile:=FProfile;

      end;
    end;
finally
  ProfileForm.Free;
  end;
end;



procedure TProfileForm.SetControlsState;
var
bLaunchApp: Boolean;
begin
bLaunchApp:=CheckBox1.Checked;
CheckBox2.Enabled:=bLaunchApp;
CheckBox3.Enabled:=bLaunchApp;
Label4.Enabled:=bLaunchApp;
Label5.Enabled:=bLaunchApp;
Label6.Enabled:=bLaunchApp;
Label7.Enabled:=bLaunchApp;
Edit4.Enabled:=bLaunchApp;
Edit5.Enabled:=bLaunchApp;
SpeedButton4.Enabled:=bLaunchApp;
ListBox1.Enabled:=bLaunchApp;
ListBox1.Enabled:=bLaunchApp;   
RadioButton1.Enabled:=bLaunchApp;
RadioButton2.Enabled:=bLaunchApp;
RadioButton3.Enabled:=bLaunchApp;
GroupBox1.Enabled:=bLaunchApp;
RadioButton4.Enabled:=bLaunchApp;
RadioButton5.Enabled:=bLaunchApp;
RadioButton6.Enabled:=bLaunchApp;
RadioButton7.Enabled:=bLaunchApp;
RadioButton8.Enabled:=bLaunchApp;
ListBox1.Enabled:=bLaunchApp;
ListBox2.Enabled:=bLaunchApp AND (NOT RadioButton8.Checked);
SpeedButton7.Enabled:=bLaunchApp;
SpeedButton8.Enabled:=bLaunchApp;
SpeedButton9.Enabled:=bLaunchApp AND (NOT RadioButton8.Checked);
SpeedButton10.Enabled:=bLaunchApp AND (NOT RadioButton8.Checked);
GroupBox2.Enabled:=bLaunchApp;
Label6.Enabled:=bLaunchApp AND (NOT RadioButton8.Checked);
end;


procedure TProfileForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
Action:=caFree;
end;

procedure TProfileForm.FormCreate(Sender: TObject);
begin
GroupBox1.Ctl3D:=false;
GroupBox2.Ctl3D:=false;
GroupBox3.Ctl3D:=false;
SetControlsState;
end;

procedure TProfileForm.CheckBox1Click(Sender: TObject);
begin
SetControlsState;
end;

procedure TProfileForm.SpeedButton3Click(Sender: TObject);
var
FileName: WideString;
begin
if GetFileNameW(True, Handle, FileName, 'Select target config file...',
                '', '', SelfDir, 0) then
  begin
  Edit3.Text:=FileName;
  FProfile.TargetConfigFileName:=FileName;
  end;
Edit3.SetFocus;
Edit3.SelStart:=length(Edit3.Text);
Edit3.SelLength:=0;
end;


procedure TProfileForm.SpeedButton1Click(Sender: TObject);
var
FileName: WideString;
Icon: TIcon;
begin
if NOT GetFileNameW(true, Handle, FileName, 'Select config icon file (16 x 16 pixels)...',
                    'Icon Files (*.ico)'#0'*.ico'#0'All Files (*.*)'#'*.*'#0#0,
                    '', SelfDir, 0) then Exit;
try
  Icon:=TIcon.Create;
  Icon.Width:=16;
  Icon.Height:=16;
  Icon.Transparent:=false;
  Icon.Handle:=LoadImageW(0, PWideChar(FileName), IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
  Image1.Canvas.FillRect(Image1.Canvas.ClipRect);
  Image1.Canvas.Draw(0, 0, Icon);
  Image1.Height:=16; //  чтоб не обрезалась
  Image1.Width:=16;  //  иконка
  Icon.Free;
  FbIconChanged:=true;
  FbIconPresented:=true;
except
  ShowError('Load icon failed.');
  FbIconChanged:=false;
  end;
end;


procedure TProfileForm.SpeedButton4Click(Sender: TObject);
var
FileName: WideString;
Dir: WideString;
begin
if Edit3.Text <> '' then
  begin
  Dir:=ExtractFilePathW(Edit3.Text);
  if NOT DirectoryExistsW(Dir) then Dir:=SelfDir;
  end
else Dir:=SelfDir;

if GetFileNameW(True, Handle, FileName, 'Select application...',
                'EXE Files (*.exe)'#0'*.exe'#0'All Files (*.*)'#0'*.*'#0#0,
                '', SelfDir, 0) then
  begin
  FProfile.AppPath:=FileName;
  Edit4.Text:=FileName;
  end;
Edit4.SetFocus;
Edit4.SelStart:=length(Edit4.Text);
Edit4.SelLength:=0;
end;



procedure TProfileForm.Button1Click(Sender: TObject);
var
FileName: WideString;
begin
if Edit2.Text = '' then
  begin
  ShowMessage('Profile name must be specified.');
  Exit;
  end;

if length(Edit2.Text) > MAX_PROFILE_NAME_LEN then
  begin
  ShowMessage('Profile name too long.');
  Exit;
  end;

if FProfile.TargetConfigFileName = '' then
  begin
  if Edit3.Text = '' then
    begin
    ShowMessage('Target config must be specified.');
    Exit;
    end;
  end;

if FProfile.Password = '' then
  begin
  ShowMessage('Encryption keyword must be specified.');
  Exit;
  end;

if CheckBox1.Checked then
  begin
  if FProfile.AppPath = '' then
    begin
    if Edit4.Text = '' then
      begin
      ShowMessage('Launching application must be specified.');
      Exit;
      end;
    end;
  end;

if FProfile.DbFileName = '' then
  begin
  if GetFileNameW(false, Handle, FileName, 'Save profile as...',
                  'CMDB Files (*.cmdb)'#0'*.cmdb'#0'All Files (*.*)'#0'*.*'#0#0,
                  '', SelfDir, 0) then
    begin
    FProfile.DbFileName:=FileName;
    ModalResult:=mrOK;
    end
  else ModalResult:=mrCancel;
  end
else ModalResult:=mrOK;
end;





procedure TProfileForm.Button3Click(Sender: TObject);
var
Password1, Password2: WideString;
begin
if NOT ShowPasswordForm('Enter keyword for profile:', Password1) then Exit;
if NOT ShowPasswordForm('Confirm keyword:', Password2) then Exit;
if Password1 = Password2 then
  begin
  FProfile.Password:=Password1;
  StaticText1.Caption:='Keyword found';
  StaticText1.Font.Color:=clGreen;
  end
else ShowMessage('Keywords not equal.');
ZeroWideString(Password1);
ZeroWideString(Password2);
end;


procedure TProfileForm.SpeedButton5Click(Sender: TObject);
begin
Image1.Canvas.FillRect(Image1.Canvas.ClipRect);
FbIconPresented:=false;
FbIconChanged:=true;
end;

procedure TProfileForm.SpeedButton6Click(Sender: TObject);
begin
MessageBox(Handle, PRESETS_VARS_INFO, 'Info', MB_OK OR MB_ICONINFORMATION);
end;

procedure TProfileForm.RadioButton1Click(Sender: TObject);
begin
SetControlsState;
end;

procedure TProfileForm.RadioButton2Click(Sender: TObject);
begin
SetControlsState;
end;

procedure TProfileForm.RadioButton3Click(Sender: TObject);
begin
SetControlsState;
end;

procedure TProfileForm.RadioButton8Click(Sender: TObject);
begin
SetControlsState;
end;


procedure TProfileForm.RadioButton7Click(Sender: TObject);
begin
SetControlsState;
end;



function _SysActionInputQuery(var ActionString: WideString): Boolean;
var
Frm: TForm;
Edit: TEdit;
Rb1, Rb2, Rb3, Rb4, Rb5, Rb6: TRadioButton;
begin
Frm:=CreateMessageDialog('', mtCustom, [mbOK, mbCancel]);
Edit:=TEdit.Create(Frm);
Rb1:=TRadioButton.Create(Frm);
Rb2:=TRadioButton.Create(Frm);
Rb3:=TRadioButton.Create(Frm);
Rb4:=TRadioButton.Create(Frm);
Rb5:=TRadioButton.Create(Frm);
Rb6:=TRadioButton.Create(Frm);

with Frm do
try
  Font.Name:='Tahoma';
  Font.Size:=8;
  Caption:='Add Action';
  Height:=220;
  Width:=300;
  //BorderIcons:=[];
  Position:=poMainFormCenter;

  Edit.Parent:=Frm;
  Edit.Height:=20;
  Edit.Width:=Width - 40;
  Edit.Left:=(Width - Edit.Width) div 2;
  Edit.Top:=110;
  Edit.Font.Name:='Courier New';
  Edit.Text:=ActionString;

  Rb1.Parent:=Frm;
  Rb1.Left:=20;
  Rb1.Top:=10;
  Rb1.Width:=120;
  Rb1.Caption:=' Erase file ';
  Rb1.Checked:=true;

  Rb2.Parent:=Frm;
  Rb2.Left:=160;
  Rb2.Top:=10;
  Rb2.Width:=120;
  Rb2.Caption:=' Clear directory ';

  Rb3.Parent:=Frm;
  Rb3.Left:=20;
  Rb3.Top:=40;
  Rb3.Width:=120;
  Rb3.Caption:=' Erase registry value ';

  Rb4.Parent:=Frm;
  Rb4.Left:=160;
  Rb4.Top:=40;
  Rb4.Width:=120;
  Rb4.Caption:=' Erase registry key ';

  Rb5.Parent:=Frm;
  Rb5.Left:=20;
  Rb5.Top:=70;
  Rb5.Width:=120;
  Rb5.Caption:=' Clear registry key ';

  Rb6.Parent:=Frm;
  Rb6.Left:=160;
  Rb6.Top:=70;
  Rb6.Width:=120;
  Rb6.Caption:=' Execute ';

  Controls[2].Height:=23;
  Controls[2].Top:=Height - (Controls[1].Height + 40);
  Controls[2].Left:=Width - Controls[1].Width - 20;

  Controls[1].Height:=23;
  Controls[1].Top:=Controls[2].Top;
  Controls[1].Left:=Width - (Controls[2].Width shl 1) - 30;

  result:=(ShowModal = mrOK) AND (Edit.text <> '');

  if result then
    begin
         if Rb1.Checked then ActionString:=SYS_ACTION_ERASE_FILE_PREFIX + Edit.Text
    else if Rb2.Checked then ActionString:=SYS_ACTION_CLEAR_DIRECTORY_PREFIX + Edit.Text
    else if Rb3.Checked then ActionString:=SYS_ACTION_ERASE_REG_VALUE_PREFIX + Edit.Text
    else if Rb4.Checked then ActionString:=SYS_ACTION_ERASE_REG_KEY_PREFIX + Edit.Text
    else if Rb5.Checked then ActionString:=SYS_ACTION_CLEAR_REG_KEY_PREFIX + Edit.Text
    else if Rb6.Checked then ActionString:=SYS_ACTION_EXECUTE_PREFIX + Edit.Text;
    end;

  finally
    Edit.Free;
    Rb1.Free;
    Rb2.Free;
    Rb3.Free;
    Rb4.Free;
    Rb5.Free;
    Rb6.Free;
    Free;
  end;
end;


function TProfileForm.SysActionInputQuery(var ActionString: WideString): Boolean;
var
ActionStrLower: WideString;
begin
repeat
  result:=_SysActionInputQuery(ActionString);
  ActionStrLower:=LowerCase(ActionString);
  if result then
    begin
    if length(ActionString) < 4 then break;
    if (pos(SYS_ACTION_ERASE_REG_VALUE_PREFIX, ActionString) = 1) OR
       (pos(SYS_ACTION_ERASE_REG_KEY_PREFIX, ActionString) = 1)   OR
       (pos(SYS_ACTION_CLEAR_REG_KEY_PREFIX, ActionString) = 1) then
      begin
      if (pos(HKCU_SHORT_STR, ActionStrLower) <> 4) AND
         (pos(HKLM_SHORT_STR, ActionStrLower) <> 4) AND
         (pos(HKCR_SHORT_STR, ActionStrLower) <> 4) AND
         (pos(HKCU_LONG_STR, ActionStrLower) <> 4)  AND
         (pos(HKLM_LONG_STR, ActionStrLower) <> 4)  AND
         (pos(HKCR_LONG_STR, ActionStrLower) <> 4) then
        begin
        ShowModalError(Handle, 'Incorrect registry path.');
        delete(ActionString, 1, 3);
        result:=false;
        end;
      end;
    end
  else break;
until result;
end;


procedure TProfileForm.SpeedButton7Click(Sender: TObject);
var
ActionStr: WideString;
begin
if SysActionInputQuery(ActionStr) then ListBox1.Items.Add(ActionStr);
end;

procedure TProfileForm.SpeedButton8Click(Sender: TObject);
var
i: Integer;
begin
i:=ListBox1.ItemIndex;
if i < 0 then Exit;
if MessageBox(Handle, PAnsiChar('Delete "' + ListBox1.Items[i] + '" ?'),
              'Delete Action', MB_YESNO OR MB_ICONQUESTION) = ID_YES
  then ListBox1.Items.Delete(i);
end;

procedure TProfileForm.SpeedButton9Click(Sender: TObject);
var
ActionStr: WideString;
begin
if SysActionInputQuery(ActionStr) then ListBox2.Items.Add(ActionStr);
end;

procedure TProfileForm.SpeedButton10Click(Sender: TObject);
var
i: Integer;
begin
i:=ListBox2.ItemIndex;
if i < 0 then Exit;
if MessageBox(Handle, PAnsiChar('Delete "' + ListBox2.Items[i] + '" ?'),
              'Delete Action', MB_YESNO OR MB_ICONQUESTION) = ID_YES
  then ListBox2.Items.Delete(i);
end;


end.
