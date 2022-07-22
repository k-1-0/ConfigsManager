unit CustomMB;

interface

uses Windows, Messages;


function CustomMessageBox(hParent: HWND; Text, Caption: string;
                          hMbIcon: HICON; hMbFont: HFONT): Integer;
                          

implementation


{$DEFINE REMOVE_WND_SYSMENU}
{.$DEFINE WMD_TOOLWINDOW}

const
  CLOSE_BUTTON_CAPTION = 'Close';

var
  CmbCaption: string;
  hCmbIcon: HICON;
  hCmbFont: HFONT;


procedure EventProc(hWinEventHook: THandle; dwEvent: DWORD; hWindow: HWND;
                    idObject, idChild: Integer; dwEventThread, dwmsEventTime: DWORD); stdcall;
const
  STATIC_CLASS_NAME = 'Static';
  BUTTON_CLASS_NAME = 'Button';
var
  Buf: Array[0..99] of Char;
  hChild: HWND;

  procedure SetCmbFont;
  begin
  if hCmbFont <> 0 then SendMessage(hChild, WM_SETFONT, hCmbFont, 0);
  end;

  procedure FindStatic;
  begin
  hChild:=FindWindowEx(hWindow, hChild, STATIC_CLASS_NAME, nil);
  if (hChild <> 0) AND (GetWindowLong(hChild, GWL_STYLE) AND SS_ICON = 0)
    then SetCmbFont
    else if hCmbIcon <> 0 then SendMessage(hChild, STM_SETICON, hCmbIcon, 0);
  end;

begin
if (GetClassName(hWindow, @Buf, length(Buf)) = 6) AND
   (PDWORD(@Buf)^ = $37323323) AND (PWORD(@Buf[SizeOf(DWORD)])^ = $3037) then
  begin
  if (GetWindowText(hWindow, @Buf, length(Buf)) = length(CmbCaption)) AND
     (PChar(@Buf) = CmbCaption) then
    begin
    {$IFDEF REMOVE_WND_SYSMENU}
      SetWindowLong(hWindow, GWL_STYLE, GetWindowLong(hWindow, GWL_STYLE) AND (NOT WS_SYSMENU));
    {$ENDIF}
    {$IFDEF WMD_TOOLWINDOW}
    SetWindowLong(hWindow, GWL_EXSTYLE, GetWindowLong(hChild, GWL_EXSTYLE) OR WS_EX_TOOLWINDOW);
    {$ENDIF}
    hChild:=FindWindowEx(hWindow, 0, BUTTON_CLASS_NAME, nil);
    if hChild <> 0 then
      begin
      SetWindowText(hChild, CLOSE_BUTTON_CAPTION);
      //SetWindowLong(hChild, GWL_STYLE, GetWindowLong(hChild, GWL_STYLE) OR BS_FLAT);
      SetCmbFont;
      end;
    if (hCmbIcon <> 0) OR (hCmbFont <> 0) then
      begin
      hChild:=0;
      FindStatic;
      FindStatic;
      end;
    end;
  end;
end;


function CustomMessageBox(hParent: HWND; Text, Caption: string;
                          hMbIcon: HICON; hMbFont: HFONT): Integer;
var
hEventHook: HHOOK;
begin
hCmbIcon:=hMbIcon;
hCmbFont:=hMbFont;
CmbCaption:=Caption;

hEventHook:=SetWinEventHook(EVENT_OBJECT_CREATE, EVENT_OBJECT_DESTROY,
                            0, @EventProc, GetCurrentProcessID,
                            GetCurrentThreadID, WINEVENT_OUTOFCONTEXT);

result:=MessageBox(hParent, PChar(Text), PChar(Caption), MB_ICONINFORMATION);

if hEventHook <> 0 then UnHookWinEvent(hEventHook);
end;


end.
 