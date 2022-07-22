unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;


const
  WM_FORM_CANCEL = WM_USER + 1;
  WM_FORM_OK     = WM_USER + 2;


type
  TPasswordForm = class(TForm)
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    SpeedButton7: TSpeedButton;
    SpeedButton8: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButton10: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure AddPassStr(const PassStr: WideString);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure SpeedButton8Click(Sender: TObject);
    procedure SpeedButton9Click(Sender: TObject);
    procedure SpeedButton10Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure WmFormCancel(var Msg: TMessage); message WM_FORM_CANCEL;
    procedure WmFormOK(var Msg: TMessage); message WM_FORM_OK;
  end;


function ShowPasswordForm(const Title: string; var Password: WideString): Boolean;


implementation

{$R *.DFM}


const
  PASS_STR_0 = '8wcg';
  PASS_STR_1 = 'R5Ln';
  PASS_STR_2 = 'ua0&';
  PASS_STR_3 = 'E/Vy';
  PASS_STR_4 = 'cX)&';
  PASS_STR_5 = 'OYr3';
  PASS_STR_6 = ')DgM';
  PASS_STR_7 = ')6$J';
  PASS_STR_8 = '5(8E';
  PASS_STR_9 = 'C*p2';



var
  hPasswordForm: HWND;
  OriginalEdtProc: function(const hWindow: HWND; const Msg, wParam, lParam: Integer): Integer; stdcall;
  KeyStroke: WideString;


function ShowPasswordForm(const Title: string; var Password: WideString): Boolean;
var
PasswordForm: TPasswordForm;
begin
PasswordForm:=TPasswordForm.Create(Application);
try
  with PasswordForm do
    begin
    Label1.Caption:=Title;
    if Password <> '' then
      begin
      KeyStroke:=Password;
      SendMessage(Edit1.Handle, WM_CHAR, 0, 0);
      end;
    result:=(ShowModal = mrOk);
    if result then Password:=KeyStroke;
    KeyStroke:='';
    end;
finally
  PasswordForm.Free;
  end;
end;


procedure TPasswordForm.WmFormCancel(var Msg: TMessage);
begin
ModalResult:=mrCancel;
end;


procedure TPasswordForm.WmFormOK(var Msg: TMessage);
begin
ModalResult:=mrOk;
end;


procedure CallWmFormCancel;
begin
SendMessage(hPasswordForm, WM_FORM_CANCEL, 0, 0);
end;


procedure CallWmFormOK;
begin
SendMessage(hPasswordForm, WM_FORM_OK, 0, 0);
end;



procedure TPasswordForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
Action:=caFree;
end;



procedure ProceedWmChar(const hWindow: HWND; const wParam, lParam: Integer);
var
KeyBoardState: TKeyBoardState;
Buf: DWORD;
Len: Integer;
begin
if wParam = VK_BACK then
  begin
  Len:=length(KeyStroke);
  if Len > 0 then SetLength(KeyStroke, Len - 1);
  Exit;
  end;

if wParam = VK_ESCAPE then
  begin
  CallWmFormCancel;
  Exit;
  end;

if wParam = VK_RETURN then
  begin
  CallWmFormOK;
  Exit;
  end;

GetKeyboardState(KeyBoardState);

if ToUnicode(wParam, HiWord(lParam) AND $0000FFFF, KeyBoardState, Buf, 2, 0) <> 0
  then KeyStroke:=KeyStroke + PWideChar(@Buf);
end;




function NewEdtProc(const hWindow: HWND; const Msg, wParam, lParam: Integer): Integer; stdcall;
var
Len: Integer;
s: AnsiString;
begin
case Msg of

  WM_KEYDOWN:
    begin
    ProceedWmChar(hWindow, wParam, lParam);
    result:=0;
    end;

  WM_CHAR:
    begin
    Len:=length(KeyStroke);
    SetLength(s, Len);
    FillChar(PAnsiChar(s)^, Len, '#');
    SetWindowText(hWindow, PAnsiChar(s));
    OriginalEdtProc(hWindow, EM_SETSEL, Len, -1);
    result:=0;
    end;

  else result:=OriginalEdtProc(hWindow, Msg, wParam, lParam);
  end;
end;




procedure TPasswordForm.FormCreate(Sender: TObject);
begin
KeyStroke:='';
hPasswordForm:=Handle;
Edit1.Ctl3D:=False;
Edit1.DoubleBuffered:=True;
@OriginalEdtProc:=Pointer(GetWindowLong(Edit1.Handle, GWL_WNDPROC));
SetWindowLong(Edit1.Handle, GWL_WNDPROC, Integer(@NewEdtProc));
end;



procedure TPasswordForm.Button1Click(Sender: TObject);
begin
if KeyStroke <> '' then ModalResult:=mrOk
else
  begin
  ShowMessage('Keyword can not be empty.');
  Edit1.SetFocus;
  end;
end;


procedure TPasswordForm.AddPassStr(const PassStr: WideString);
begin
KeyStroke:=KeyStroke + PassStr;
SendMessage(Edit1.Handle, WM_CHAR, 0, 0);
end;

procedure TPasswordForm.SpeedButton1Click(Sender: TObject);
begin
AddPassStr(PASS_STR_0);
end;

procedure TPasswordForm.SpeedButton2Click(Sender: TObject);
begin
AddPassStr(PASS_STR_1);
end;

procedure TPasswordForm.SpeedButton3Click(Sender: TObject);
begin
AddPassStr(PASS_STR_2);
end;

procedure TPasswordForm.SpeedButton4Click(Sender: TObject);
begin
AddPassStr(PASS_STR_3);
end;

procedure TPasswordForm.SpeedButton5Click(Sender: TObject);
begin
AddPassStr(PASS_STR_4);
end;

procedure TPasswordForm.SpeedButton6Click(Sender: TObject);
begin
AddPassStr(PASS_STR_5);
end;

procedure TPasswordForm.SpeedButton7Click(Sender: TObject);
begin
AddPassStr(PASS_STR_6);
end;

procedure TPasswordForm.SpeedButton8Click(Sender: TObject);
begin
AddPassStr(PASS_STR_7);
end;

procedure TPasswordForm.SpeedButton9Click(Sender: TObject);
begin
AddPassStr(PASS_STR_8);
end;

procedure TPasswordForm.SpeedButton10Click(Sender: TObject);
begin
AddPassStr(PASS_STR_9);
end;

end.
