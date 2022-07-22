unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus, ExtCtrls, ShellAPI, ImgList;


const

  INFO_TEXT = '  Configs Manager' + #13#10 +
              '  version 2.0'     + #13#10#13#10 +
              '  coded by K10';

  HELP_TEXT = 'Command line parameters:' + #13#10#13#10 +
              'CfgMgr.exe [profile.cmdb] [/launch:"config_name"]' + #13#10#13#10 +
              'profile.cmdb - profile DB file for auto load at start' + #13#10 +
              'config_name - config name for auto launch with auto load profile';

  WM_TRAYICONNOTIFY          = WM_USER + 123;
  WM_CLOSE_CURRENT_PROFILE   = WM_USER + 124;
  WM_MAIN_FORM_ACTION        = WM_USER + 125;


type

  PButton = ^TButton;
  PMenuItem = ^TMenuItem;


  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    Profile1: TMenuItem;
    Newprofile1: TMenuItem;
    Closecurrentprofile1: TMenuItem;
    Exit1: TMenuItem;
    Editcurrentprofile1: TMenuItem;
    Configs1: TMenuItem;
    Add1: TMenuItem;
    Delete1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Movedown1: TMenuItem;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    StaticText1: TStaticText;
    Button5: TButton;
    Button6: TButton;
    StaticText2: TStaticText;
    Panel2: TPanel;
    ListBox1: TListBox;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Openprofile1: TMenuItem;
    Help1: TMenuItem;
    Help2: TMenuItem;
    N4: TMenuItem;
    About1: TMenuItem;
    N5: TMenuItem;
    Launch1: TMenuItem;
    N1: TMenuItem;
    ImageList1: TImageList;
    PopupMenu1: TPopupMenu;
    ShowCFGMGR1: TMenuItem;
    N6: TMenuItem;
    Exit2: TMenuItem;
    Button7: TButton;
    Export1: TMenuItem;
    N7: TMenuItem;
    Rename1: TMenuItem;
    N8: TMenuItem;
    Button8: TButton;
    StaticText3: TStaticText;
    Button9: TButton;
    Terminate1: TMenuItem;
    N9: TMenuItem;
    Terminate2: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Newprofile1Click(Sender: TObject);
    procedure Editcurrentprofile1Click(Sender: TObject);
    procedure Add1Click(Sender: TObject);
    procedure Closecurrentprofile1Click(Sender: TObject);
    procedure Delete1Click(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure Movedown1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Openprofile1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Launch1Click(Sender: TObject);
    procedure ListBox1DrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ShowCFGMGR1Click(Sender: TObject);
    procedure Exit2Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure Help2Click(Sender: TObject);
    procedure Export1Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Rename1Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Terminate1Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Terminate2Click(Sender: TObject);
  private
    { Private declarations }
   procedure SetActionState(const pBtn: PButton; const pMnItem: PMenuItem;
                            const EnabledImageIndex, DisabledImageIndex: Integer;
                            const bEnabled: Boolean);
    procedure UpdateActionsState;
    procedure CreateNewProfile;
    procedure CloseCurrentProfile;
    procedure ApplyCurrentProfile;
    procedure ActivateSelectedConfig;
    procedure TerminateSelectedConfigApp;
    procedure DeleteTrayIcon;
    procedure RestoreFromTray;
    procedure MinimizeToTray;
    procedure ProfileIconToItemIcon;
  public
    procedure WmIconNotify(var Msg: TMessage); message WM_TRAYICONNOTIFY;
    procedure WmCloseCurrentProfile(var Msg: TMessage); message WM_CLOSE_CURRENT_PROFILE;
    procedure WmMainFormAction(var Msg: TMessage); message WM_MAIN_FORM_ACTION;
  end;


var
  MainForm: TMainForm;

implementation

{$R *.DFM}

uses Unit2, Unit3, ConfigActivation, Utils, SxMenu, CustomMB, ProfileClass;

{$I dbg.inc}


const
  CFG_MGR_PROFILE_FILENAME = 'CfgMgr.ini';

var
  CurrentProfile: TProfile;
  WndIcon, AppIcon, ItemIcon: TIcon;
  ItemBitmap, SeparatorBitmap: TBitmap;
  dwFormAction: DWORD = 0;
  bTray: Boolean = false;




//procedure SetProfileTestData(var Profile: TProfile);
//begin
//with Profile do
//  begin
//  ProfileName:='Test profile';
//  ProfileDirectory:='C:\_PROJECTS\ConfigsManager\test\cfg_mgr\';
//  TargetConfig:='C:\_PROJECTS\ConfigsManager\test\wallet.dat';
//  Password:='123';
//  end;
//end;




procedure MainFormAction(const dwAction: DWORD);
begin
if dwAction <= MAIN_FORM_ACTION_RESTORE then dwFormAction:=dwAction;
if hMainForm <> 0 then SendMessage(hMainForm, WM_MAIN_FORM_ACTION, dwAction, 0)
else if dwAction = AFTER_LAUNCH_APP_ACTION_EXIT then ExitProcess(0); // если формы еще нет
end;




procedure TMainForm.WmMainFormAction(var Msg: TMessage);
begin
case Msg.wParam of

  MAINFORM_ACTION_APP_STARTED,
  MAINFORM_ACTION_APP_ENDED:   UpdateActionsState;

  AFTER_LAUNCH_APP_ACTION_MINIMIZE: Application.Minimize;

  AFTER_LAUNCH_APP_ACTION_HIDE: begin
                                MainForm.Hide;
                                Application.ShowMainForm:=false;
                                end;

  AFTER_LAUNCH_APP_ACTION_TRAY: MinimizeToTray;

  MAIN_FORM_ACTION_RESTORE: begin
                            if Visible then Application.Restore
                            else
                              begin
                              if bTray then RestoreFromTray else
                                begin
                                MainForm.Show;
                                Application.ShowMainForm:=true;
                                end;
                              end;
                            end;

  AFTER_LAUNCH_APP_ACTION_EXIT: begin
                                if bTray then DeleteTrayIcon;
                                Close;
                                end;
  end;      
end;



procedure TMainForm.WmCloseCurrentProfile(var Msg: TMessage);
begin
CloseCurrentProfile;
end;


procedure CloseCurrentProfileAsync;
begin
if hMainForm <> 0 then SendMessage(hMainForm, WM_CLOSE_CURRENT_PROFILE, 0, 0);
end;



procedure TMainForm.DeleteTrayIcon;
var
TrayIconData: TNotifyIconData;
begin
TrayIconData.cbSize:=SizeOf(TNotifyIconData);
TrayIconData.Wnd:=hMainForm;
TrayIconData.uID:=1;
Shell_NotifyIcon(NIM_DELETE, @TrayIconData);
end;

procedure TMainForm.RestoreFromTray;
begin
bTray:=false;
DeleteTrayIcon;
Application.ShowMainForm:=true;
MainForm.Show;
Application.Restore;
SetForegroundWindow(Handle);
end;

procedure TMainForm.MinimizeToTray;
var
TrayIconData: TNotifyIconData;
begin
bTray:=true;
TrayIconData.cbSize:=SizeOf(TNotifyIconData);
TrayIconData.Wnd:=hMainForm;
TrayIconData.uID:=1;
TrayIconData.uFlags:=NIF_ICON OR NIF_MESSAGE OR NIF_TIP;
TrayIconData.uCallBackMessage:=WM_TRAYICONNOTIFY;
if (CurrentProfile <> nil) AND
   CurrentProfile.bIconPresented then TrayIconData.hIcon:=ItemIcon.Handle
                                 else TrayIconData.hIcon:=WndIcon.Handle;
CopyMemory(@TrayIconData.szTip, PChar(Caption), length(Caption) + 1);
Shell_NotifyIcon(NIM_ADD, @TrayIconData);
Application.ShowMainForm:=false;
MainForm.Hide;
end;


procedure TMainForm.WmIconNotify(var Msg: TMessage);
var
P: TPoint;
begin
  case Msg.LParam of
    WM_RBUTTONUP:
      begin
      if GetCursorPos(p) then
        begin
        SetForegroundWindow(Handle);
        PopupMenu1.Popup(P.X, P.Y);
        PostMessage(Handle, WM_NULL, 0, 0);
        end;
      end;
    //WM_LBUTTONDBLCLK : ShowMainForm;
    WM_LBUTTONUP : RestoreFromTray;
    //WM_LBUTTONDOWN : ShowMainForm;
  end;
end;



procedure TMainForm.ActivateSelectedConfig;
var
i: Integer;
begin
if CurrentProfile = nil then Exit;
i:=ListBox1.ItemIndex;
if (i >= 0) then ActivateProfileConfig(CurrentProfile, i);
end;


procedure TMainForm.TerminateSelectedConfigApp;
begin
TerminateProfileApp;
end;


procedure ActivateConfigByName(const ConfigName: WideString);
var
i: Integer;
CfgName: string;
begin
if (CurrentProfile = nil) OR (length(CurrentProfile.Configs) = 0) then Exit;
CfgName:=LowerCase(ConfigName);
for i:=0 to length(CurrentProfile.Configs) - 1 do
  begin
  if CfgName = LowerCase(CurrentProfile.Configs[i].CfgName) then
    begin
    ActivateProfileConfig(CurrentProfile, i);
    Exit;
    end;
  end;
ShowError('Config "' + ConfigName + '" not found.');
end;



procedure TMainForm.SetActionState(const pBtn: PButton; const pMnItem: PMenuItem;
                                   const EnabledImageIndex, DisabledImageIndex: Integer;
                                   const bEnabled: Boolean);
begin
if pBtn  <> nil then pBtn^.Enabled:=bEnabled;

if pMnItem <> nil then
  begin
  pMnItem^.Enabled:=bEnabled;
  if bEnabled then pMnItem^.ImageIndex:=EnabledImageIndex
              else pMnItem^.ImageIndex:=DisabledImageIndex;
  end;
end;




procedure TMainForm.UpdateActionsState;
var
bProfileFound, bSeparator, bSelected: Boolean;
begin
bProfileFound:=(CurrentProfile <> nil);
bSelected:=ListBox1.ItemIndex >= 0;
bSeparator:=bSelected AND (ListBox1.Items[ListBox1.ItemIndex] = '-');

if hAppProcess <> 0 then
  begin           
  SetActionState(@Button1, @Launch1, 14, 15, false);
  SetActionState(@Button9, @Terminate1, 3, 3, true);
  Terminate2.Enabled:=true;
  SetActionState(nil, @Newprofile1, 0, 0, false);
  SetActionState(nil, @Openprofile1, 1, 1, false);
  SetActionState(nil, @Editcurrentprofile1, 2, 5, false);
  SetActionState(nil, @Closecurrentprofile1, 3, 3, false);
  end
else
  begin
  Terminate2.Enabled:=false;
  SetActionState(nil, @Closecurrentprofile1, 3, 3, bProfileFound);
  SetActionState(nil, @Editcurrentprofile1, 2, 5, bProfileFound);
  SetActionState(nil, @Newprofile1, 0, 0, true);
  SetActionState(nil, @Openprofile1, 1, 1, true);
  SetActionState(@Button1, @Launch1, 14, 15, bProfileFound AND bSelected AND (NOT bSeparator));
  SetActionState(@Button9, @Terminate1, 3, 3, hAppProcess <> 0);
  end;

SetActionState(@Button2, @Add1, 6, 7, bProfileFound);
SetActionState(@Button3, @Delete1, 8, 9, bProfileFound AND bSelected);
SetActionState(@Button4, @N3, 12, 13, bProfileFound AND bSelected AND (ListBox1.ItemIndex > 0));
SetActionState(@Button5, @Movedown1, 10, 11, bProfileFound AND bSelected AND (ListBox1.ItemIndex < ListBox1.Items.Count - 1));
SetActionState(@Button7, @Export1, 19, 20, bProfileFound AND bSelected AND (NOT bSeparator));
SetActionState(@Button8, @Rename1, 2, 5, bProfileFound AND bSelected AND (NOT bSeparator));
end;


procedure TMainForm.CloseCurrentProfile;
begin
if CurrentProfile <> nil then FreeAndNil(CurrentProfile);
ListBox1.Clear;
ListBox1.Enabled:=false;
ListBox1.Color:=clBtnFace;
UpdateActionsState;
Caption:='CFG MGR';
end;



procedure TMainForm.ApplyCurrentProfile;
var
i: Integer;
begin          
if CurrentProfile = nil then
  begin
  CloseCurrentProfile;
  Exit;
  end;

Caption:=CurrentProfile.ProfileName + ' - CFG MGR';
ListBox1.Clear;
ListBox1.Enabled:=true;
ListBox1.Color:=clWindow;
UpdateActionsState;

if CurrentProfile.bIconPresented then
  begin
  ProfileIconToItemIcon;
  MainForm.Icon:=ItemIcon;
  Application.Icon:=ItemIcon;
  end
else
  begin
  MainForm.Icon:=WndIcon;
  Application.Icon:=AppIcon;
  end;

if length(CurrentProfile.Configs) > 0 then
  begin
  for i:=0 to length(CurrentProfile.Configs) - 1 do
    ListBox1.Items.Add(CurrentProfile.Configs[i].CfgName);
  end;
end;



//"C:\_APP_DATA\Mega\Mega.cmdb" -launch:"default"
procedure TMainForm.CreateNewProfile;
var
dwRes: DWORD;
NewProfile: TProfile;
begin
NewProfile:=TProfile.Create;

if ShowProfileForm(true, NewProfile) then
  begin
  dwRes:=NewProfile.SaveProfile;
  if dwRes = PROFILE_ERR_SUCCESS then
    begin
    if CurrentProfile <> nil then CloseCurrentProfile;
    CurrentProfile:=NewProfile;
    ApplyCurrentProfile;
    end
  else
    begin
    //CloseCurrentProfile;
    ShowError('Saving profile failed.' + #13#10 +
              'Error: ' + ProfileErrToStr(dwRes));
    end
  end;
end;



procedure TMainForm.ProfileIconToItemIcon;
var
x, y: Integer;
ImgList: TImageList;
begin
if CurrentProfile = nil then Exit;
for x:=0 to 15 do
  begin
  for y:=0 to 15 do
    ItemBitmap.Canvas.Pixels[x, y]:=CurrentProfile.IconData.Pixels[x, y];
  end;
ItemBitmap.TransparentColor:=CurrentProfile.IconData.dwTransparentColor;
ImgList:=TImageList.CreateSize(16, 16);
try
  ImgList.AddMasked(ItemBitmap, ItemBitmap.TransparentColor);
  ImgList.GetIcon(0, ItemIcon);
finally
  ImgList.Free;
  end;
end;



function LoadProfile(const ConfigFileName: WideString): Boolean;
var
dwRes: DWORD;
Password: WideString;
begin
result:=false;

if CurrentProfile <> nil then CloseCurrentProfileAsync;

repeat
  CurrentProfile:=TProfile.Create;

  if NOT ShowPasswordForm('Enter keyword for profile:', Password) then
    begin
    FreeAndNil(CurrentProfile);
    Exit;
    end;

  dwRes:=CurrentProfile.Load(ConfigFileName, Password);

  ZeroWideString(Password);

  result:=dwRes = PROFILE_ERR_SUCCESS;
  if result then
    begin
    // ApplyCurrentProfile
    end
  else
    begin
    if dwRes = PROFILE_ERR_DECRYPT_DB_FAILED then ShowError('Incorrect password.')
    else
      begin
      FreeAndNil(CurrentProfile);
      ShowError('Load profile failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
      Break;
      end;
    end;
until dwRes <> PROFILE_ERR_DECRYPT_DB_FAILED;
end;





procedure TMainForm.FormCreate(Sender: TObject);
var
IniFile: WideString;
i: Integer;
bForeground: Boolean;
begin
hMainForm:=Handle;

if CurrentProfile <> nil then
  begin
  ApplyCurrentProfile;
  UpdateActionsState;
  end;

bForeground:=false;    // showmessage(IntToStr(dwFormAction));
case dwFormAction of
  AFTER_LAUNCH_APP_ACTION_MINIMIZE: Application.Minimize;
  AFTER_LAUNCH_APP_ACTION_HIDE: begin
                                Application.ShowMainForm:=false;
                                MainForm.Hide;
                                end;
  AFTER_LAUNCH_APP_ACTION_TRAY: MinimizeToTray;
  else bForeground:=true;
  end;
dwFormAction:=AFTER_LAUNCH_APP_ACTION_NONE;

IniFile:=SelfDir + CFG_MGR_PROFILE_FILENAME;
i:=IniGetInt(IniFile, 'Window', 'width', 0);
if i <> 0 then Width:=i;
i:=IniGetInt(IniFile, 'Window', 'height', 0);
if i <> 0 then Height:=i;
i:=IniGetInt(IniFile, 'Window', 'left', 0);
if i <> 0 then Left:=i;
i:=IniGetInt(IniFile, 'Window', 'top', 0);
if i <> 0 then Top:=i;

ModifyMenu(MainMenu1.Handle, 2, MF_BYPOSITION OR MF_POPUP OR MF_HELP,
           Help1.Handle, 'Help');

SxMenu_Initialize(@MainForm);
SxMenu_SetDefaultColors;
SxMenu_AddMenu(MainMenu1);
SxMenu_AddMenu(PopupMenu1);

if bForeground then SetForegroundWindow(Handle);

SeparatorBitmap:=TBitmap.Create;
with SeparatorBitmap do
  begin
  Height:=ListBox1.ItemHeight - 4;
  Width:=140;
  Transparent:=true;
  TransparentColor:=clWhite;
  SeparatorBitmap.Canvas.FillRect(Rect(0, 0, 180, 16));
  for i:=20 to 178 do
    begin
    Canvas.Pixels[i, 7]:=clBlack;
    Canvas.Pixels[i, 8]:=clBlack;
    end;
  end;
end;


procedure TMainForm.Exit1Click(Sender: TObject);
begin
Close;
end;

procedure TMainForm.Newprofile1Click(Sender: TObject);
begin
CreateNewProfile;
end;

procedure TMainForm.Editcurrentprofile1Click(Sender: TObject);
var
dwRes: DWORD;
begin
if ShowProfileForm(false, CurrentProfile) then
  begin
  dwRes:=CurrentProfile.SaveProfile;
  if dwRes <> PROFILE_ERR_SUCCESS then ShowError('Saving profile failed.' + #13#10 +
                                                 'Error: ' + ProfileErrToStr(dwRes))
                                  else ApplyCurrentProfile;
  end;
end;


procedure TMainForm.Add1Click(Sender: TObject);
var
FileName: WideString;
ConfigName: string;
dwRes: DWORD;
begin
if CurrentProfile = nil then Exit;

ConfigName:='';
if NOT InputQuery('New Config', 'Config name:', ConfigName) then Exit;

FileName:='';
if ConfigName <> '-' then
  begin
  if NOT GetFileNameW(true, Handle, FileName, 'Select file to add...',
                      'All Files (*.*)'#0'*.*'#0#0, '',
                      ExtractFilePathW(CurrentProfile.DbFileName), 0) then Exit;

  if ListBox1.Items.IndexOf(ConfigName) >= 0 then
    begin
    ShowError('Config "' + ConfigName + '" already exists.');
    Exit;
    end;
  end;

dwRes:=CurrentProfile.AddConfig(ConfigName, FileName);

if dwRes = PROFILE_ERR_SUCCESS then
  begin
  CurrentProfile.SaveProfile;
  ApplyCurrentProfile;
  end
else ShowError('Add config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
end;


procedure TMainForm.Closecurrentprofile1Click(Sender: TObject);
begin
CloseCurrentProfile;
end;


procedure TMainForm.Delete1Click(Sender: TObject);
var
i: Integer;
dwRes: DWORD;
begin
if CurrentProfile = nil then Exit;
i:=ListBox1.ItemIndex;
if (ListBox1.Items.Count < 1) OR (i < 0) then Exit;

if MessageBox(Handle, PChar('Delete config "' + ListBox1.Items[i] + '" ?'),
              'Delete Config', MB_YESNO OR MB_ICONQUESTION) <> ID_YES then Exit;

dwRes:=CurrentProfile.DeleteConfig(i);
if dwRes = PROFILE_ERR_SUCCESS then
  begin
  dwRes:=CurrentProfile.SaveProfile;
  if dwRes = PROFILE_ERR_SUCCESS then
    begin
    ApplyCurrentProfile;
    if ListBox1.Items.Count > 0 then
      begin
      if i > ListBox1.Items.Count - 1 then ListBox1.ItemIndex:=ListBox1.Items.Count - 1
      else ListBox1.ItemIndex:=i;
      end;
    end
  else ShowError('Delete config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
  UpdateActionsState;
  end
else ShowError('Delete config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
end;


procedure TMainForm.ListBox1Click(Sender: TObject);
begin
UpdateActionsState;
end;


procedure TMainForm.N3Click(Sender: TObject);
var
i: Integer;
dwRes: DWORD;
begin
if CurrentProfile = nil then Exit;
i:=ListBox1.ItemIndex;
if (ListBox1.Items.Count < 1) OR (i < 1) then Exit;

dwRes:=CurrentProfile.MoveConfigUp(i);
if dwRes = PROFILE_ERR_SUCCESS then
  begin
  dwRes:=CurrentProfile.SaveProfile;
  if dwRes = PROFILE_ERR_SUCCESS then
    begin
    ApplyCurrentProfile;
    ListBox1.ItemIndex:=i - 1;
    UpdateActionsState;
    end
  else ShowError('Move config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
  end
else ShowError('Move config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
end;




procedure TMainForm.Movedown1Click(Sender: TObject);
var
i: Integer;
dwRes: DWORD;
begin
if CurrentProfile = nil then Exit;
i:=ListBox1.ItemIndex;
if (ListBox1.Items.Count < 1) OR (i > ListBox1.Items.Count - 1) then Exit;

dwRes:=CurrentProfile.MoveConfigDown(i);
if dwRes = PROFILE_ERR_SUCCESS then
  begin
  dwRes:=CurrentProfile.SaveProfile;
  if dwRes = PROFILE_ERR_SUCCESS then
    begin
    ApplyCurrentProfile;
    ListBox1.ItemIndex:=i + 1;
    UpdateActionsState;
    end
  else ShowError('Move config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
  end
else ShowError('Move config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
end;



procedure TMainForm.FormResize(Sender: TObject);
begin
Button6.Top:=Height - 91;

end;

procedure TMainForm.Openprofile1Click(Sender: TObject);
var
FileName: WideString;
begin
if NOT GetFileNameW(true, Handle, FileName, 'Open Profile...',
                    'CMDB Files (*.cmdb)'#0'*.cmdb'#0'All Files (*.*)'#0'*.*'#0#0,
                    '', SelfDir, 0) then Exit;

if LoadProfile(FileName) then
  begin
  ApplyCurrentProfile;
  UpdateActionsState;
  end;
end;


procedure TMainForm.FormDestroy(Sender: TObject);
var
IniFile: WideString;
begin
IniFile:=SelfDir + CFG_MGR_PROFILE_FILENAME;
IniSetInt(IniFile, 'Window', 'width', Width);
IniSetInt(IniFile, 'Window', 'height', Height);
IniSetInt(IniFile, 'Window', 'left', Left);
IniSetInt(IniFile, 'Window', 'top', Top);
SxMenu_Finalize;
end;


procedure TMainForm.Button2Click(Sender: TObject);
begin
Add1Click(Sender);
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
Delete1Click(Sender);
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
N3Click(Sender);
end;

procedure TMainForm.Button5Click(Sender: TObject);
begin
Movedown1Click(Sender);
end;

procedure TMainForm.Button6Click(Sender: TObject);
begin
Close;
end;


procedure TMainForm.Button1Click(Sender: TObject);
begin
ActivateSelectedConfig;
end;

procedure TMainForm.Launch1Click(Sender: TObject);
begin
ActivateSelectedConfig;
end;

procedure TMainForm.About1Click(Sender: TObject);
var
hApplicationIcon: HICON;
begin
hApplicationIcon:=LoadIcon(hInstance, 'MAINICON');
CustomMessageBox(Handle, INFO_TEXT, 'About...', hApplicationIcon, MainForm.Font.Handle);
DestroyIcon(hApplicationIcon);
end;


procedure TMainForm.ListBox1DrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var
LineText: AnsiString;
begin
with (Control as TListBox).Canvas do
  begin
  LineText:=ListBox1.Items[Index];
  FillRect(Rect);
  if CurrentProfile.bIconPresented
    then BrushCopy(Bounds(Rect.Left + 4, Rect.Top + 2, 16, 16),
                   ItemBitmap, Bounds(0, 0, 16, 16),
                   ItemBitmap.TransparentColor)
    else Draw(Rect.Left + 4, Rect.Top + 2, WndIcon);

  if LineText = '-' then Draw(Rect.Left + 20, Rect.Top + 2, SeparatorBitmap)
                    else TextOut(Rect.Left + 28, Rect.Top + 2, ListBox1.Items[Index]);
  end;
end;


procedure TMainForm.ShowCFGMGR1Click(Sender: TObject);
begin
if bTray then RestoreFromTray;
end;


procedure TMainForm.Exit2Click(Sender: TObject);
begin
if bTray then DeleteTrayIcon;
Close;
end;


procedure TMainForm.ListBox1DblClick(Sender: TObject);
begin
ActivateSelectedConfig;
end;





procedure TMainForm.Help2Click(Sender: TObject);
begin
MessageBox(Handle, HELP_TEXT, 'Help', MB_OK OR MB_ICONINFORMATION);
end;


////////////////////////////////////////////////////////////////////////////////


procedure AppInit;
var
Param: string;
begin
SelfDir:=GetSelfDir;

@MainFormActionProc:=@MainFormAction;

AppIcon:=TIcon.Create;
AppIcon.Handle:=LoadImage(hInstance, 'MAINICON', IMAGE_ICON, 32, 32, 0);

WndIcon:=TIcon.Create;
WndIcon.Handle:=LoadImage(hInstance, 'MAINICON', IMAGE_ICON, 16, 16, 0);

ItemIcon:=TIcon.Create;
ItemIcon.Width:=16;
ItemIcon.Height:=16;
ItemIcon.Transparent:=True;

ItemBitmap:=TBitmap.Create;
ItemBitmap.Width:=16;
ItemBitmap.Height:=16;
ItemBitmap.TransparentMode:=tmFixed;
ItemBitmap.Transparent:=true;

if (ParamCount > 0) AND FileExists(ParamStr(1)) then
  begin
  if LoadProfile(ParamStr(1)) then
    begin
    if ParamCount > 1 then
      begin
      Param:=ParamStr(2);
      if (length(Param) > 9) AND (copy(Param, 1, 8) = '/launch:') then
        ActivateConfigByName(copy(Param, 9, length(Param) - 8));
      end;
    end;
  end;
end;



procedure AppFinal;
begin
if CurrentProfile <> nil then FreeAndNil(CurrentProfile);
DestroyIcon(AppIcon.Handle);
DestroyIcon(WndIcon.Handle);
AppIcon.Free;
WndIcon.Free;
ItemIcon.Free;
ItemBitmap.Free;
end;




procedure TMainForm.Export1Click(Sender: TObject);
var
FileName, Ext, Filter: WideString;
i: Integer;
dwRes: DWORD;
begin
if CurrentProfile = nil then Exit;

i:=ListBox1.ItemIndex;
if (i < 0) then Exit;

FileName:=CurrentProfile.Configs[i].CfgName;
Ext:=ExtractFileExtW(CurrentProfile.TargetConfigFileName);
if Ext <> '' then FileName:=FileName + '.' + Ext;
if Ext <> '' then Filter:=UpperCase(Ext) + ' Files (*.' + Ext + ')'#0'*.' + Ext + #0'All Files (*.*)'#0'*.*'#0#0
             else Filter:='';

if NOT GetFileNameW(false, Handle, FileName, 'Open Profile...',
                    Filter, '', ExtractFilePathW(FileName), 0) then Exit;

dwRes:=CurrentProfile.ExportConfig(i, FileName);

if dwRes = PROFILE_ERR_SUCCESS
  then MessageBox(Handle, 'Config exported.', 'Success', MB_OK OR MB_ICONINFORMATION)
  else ShowError('Export failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
end;




procedure TMainForm.Button7Click(Sender: TObject);
begin
Export1Click(Sender);
end;

procedure TMainForm.Rename1Click(Sender: TObject);
var
i: Integer;
ConfigName: AnsiString;
dwRes: DWORD;
begin
if CurrentProfile = nil then Exit;

i:=ListBox1.ItemIndex;
if i < 0 then Exit;

ConfigName:=CurrentProfile.Configs[i].CfgName;
if InputQuery('Rename', 'Config name:', ConfigName) then
  begin
  CurrentProfile.Configs[i].CfgName:=ConfigName;
  dwRes:=CurrentProfile.SaveProfile;
  if dwRes = PROFILE_ERR_SUCCESS then
    begin
    ApplyCurrentProfile;
    ListBox1.ItemIndex:=i;
    UpdateActionsState;
    end
  else ShowError('Save profile failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
  end;
end;

procedure TMainForm.Button8Click(Sender: TObject);
begin
Rename1Click(Sender);
end;

procedure TMainForm.Terminate1Click(Sender: TObject);
begin
TerminateSelectedConfigApp;
end;

procedure TMainForm.Button9Click(Sender: TObject);
begin
TerminateSelectedConfigApp;
end;

procedure TMainForm.Terminate2Click(Sender: TObject);
begin
TerminateSelectedConfigApp;
end;

initialization
  IsMultiThread:=true;
  AppInit;

finalization
  AppFinal;


end.
