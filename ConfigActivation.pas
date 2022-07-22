unit ConfigActivation;

interface

uses Forms, Windows, SysUtils, Classes, ShellAPI, Crypt, ProfileClass, Utils;



procedure ActivateProfileConfig(var Profile: TProfile; const Index: Integer);

procedure TerminateProfileApp;


var
  hJobObject: THandle = 0;
  hAppProcess: THandle = 0;



implementation


type

  TWaitThreadParams = packed record
    CfgIndex: Integer;
    pProf: PProfile;
  end;
  PWaitThreadParams = ^TWaitThreadParams;


function CreateJobObjectW(lpJobAttributes: PSecurityAttributes; lpName: PWideChar): THandle; stdcall external kernel32;
function AssignProcessToJobObject(hJob: THandle; hProcess: THandle): BOOL; stdcall external kernel32;
function TerminateJobObject(hJob: THandle; uExitCode: UINT): BOOL; stdcall external kernel32;




function StartApp(const AppFile, Args: WideString; var hAppProcess: THandle): Boolean;
var
SeInfoW: SHELLEXECUTEINFOW;
begin
ZeroMemory(@SeInfoW, SizeOf(SeInfoW));
SeInfoW.cbSize:=SizeOf(SHELLEXECUTEINFOW);
SeInfoW.Wnd:=HWND_DESKTOP;
SeInfoW.lpVerb:='open';
SeInfoW.lpFile:=PWideChar(AppFile);
SeInfoW.lpDirectory:=PWideChar(ExtractFilePathW(AppFile));
if length(Args) > 0 then SeInfoW.lpParameters:=PWideChar(Args);
SeInfoW.nShow:=SW_SHOWNORMAL;
SeInfoW.fMask:=SEE_MASK_NOCLOSEPROCESS;
result:=ShellExecuteExW(@SeInfoW);
hAppProcess:=SeInfoW.hProcess;
end;


procedure TerminateProfileApp;
var
hJob: THandle;
begin
if hJobObject <> 0 then
  begin
  hJob:=hJobObject;
  hJobObject:=0;
  TerminateJobObject(hJob, 0);
  CloseHandle(hJob);
  end;
end;



procedure ProceedAction(const ActionStr: WideString; var Profile: TProfile);
var
ActionPrefix, ActionParam: WideString;
begin
if length(ActionStr) < 4 then Exit;
ActionPrefix:=copy(ActionStr, 1, 3);
ActionParam:=Profile.ExpandVars(ActionStr);
delete(ActionParam, 1, 3);
     if ActionPrefix = SYS_ACTION_ERASE_FILE_PREFIX then EraseFileW(ActionParam)
else if ActionPrefix = SYS_ACTION_CLEAR_DIRECTORY_PREFIX then ClearDirectoryW(ActionParam)
else if ActionPrefix = SYS_ACTION_ERASE_REG_KEY_PREFIX then RegEraseKeyW(ActionParam)
else if ActionPrefix = SYS_ACTION_CLEAR_REG_KEY_PREFIX then RegClearKeyW(ActionParam)
else if ActionPrefix = SYS_ACTION_ERASE_REG_VALUE_PREFIX then RegEraseValueW(ActionParam)
else if ActionPrefix = SYS_ACTION_EXECUTE_PREFIX then StartProcess(PWideChar(ActionParam), SW_SHOWNORMAL, 0, nil);
end;



procedure WaitAppThreadProc(pParams: PWaitThreadParams); stdcall;
var
dwRes: DWORD;
i: Integer;
hJob: THandle;
begin
if hAppProcess = 0 then Exit;

MainFormActionProc(MAINFORM_ACTION_APP_STARTED);

WaitForSingleObject(hAppProcess, INFINITE);
TerminateProcess(hAppProcess, 0);
CloseHandle(hAppProcess);

if hJobObject <> 0 then
  begin
  hJob:=hJobObject;
  hJobObject:=0;
  TerminateJobObject(hJob, 0);
  CloseHandle(hJob);
  end;

//------------------------------------------------------------------------------
//          Update config in DB after application ended
//------------------------------------------------------------------------------
if pParams^.pProf^.bUpdateConfigAfterAppEnded then
  begin
  dwRes:=pParams^.pProf^.UpdateConfigFromTarget(pParams^.CfgIndex);
  if dwRes <> PROFILE_ERR_SUCCESS
    then ShowError('Update config failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes))
    else pParams^.pProf^.SaveProfile;
  end;

//------------------------------------------------------------------------------
//          Delete plain config after application ended
//------------------------------------------------------------------------------
if pParams^.pProf^.bDeleteConfigAfterAppEnded
  then EraseFileW(pParams^.pProf^.ExpandVars(pParams^.pProf^.TargetConfigFileName));

//------------------------------------------------------------------------------
//          After application ending actions
//------------------------------------------------------------------------------
if length(pParams^.pProf^.AfterEndingAppSysActions) > 0 then
  begin
  for i:=Low(pParams^.pProf^.AfterEndingAppSysActions) to High(pParams^.pProf^.AfterEndingAppSysActions) do
    ProceedAction(pParams^.pProf^.AfterEndingAppSysActions[i], pParams^.pProf^);
  end;

if pParams^.pProf^.AfterEndingAppAction = AFTER_ENDING_APP_ACTION_EXIT
  then MainFormActionProc(AFTER_LAUNCH_APP_ACTION_EXIT)
else if pParams^.pProf^.AfterEndingAppAction = AFTER_ENDING_APP_ACTION_RESTORE
  then MainFormActionProc(MAIN_FORM_ACTION_RESTORE);

LocalFree(HLOCAL(pParams));

hAppProcess:=0;
MainFormActionProc(MAINFORM_ACTION_APP_ENDED);
end;




procedure ActivateProfileConfig(var Profile: TProfile; const Index: Integer);
var
i: Integer;
dwRes: DWORD;
bWait: Boolean;
hApp: THandle;
hThread: THandle;
dwThreadID: DWORD;
pParams: PWaitThreadParams;
begin
//------------------------------------------------------------------------------
//          Actions before launch application
//------------------------------------------------------------------------------
if length(Profile.BeforeLaunchAppSysActions) > 0 then
  begin
  for i:=Low(Profile.BeforeLaunchAppSysActions) to High(Profile.BeforeLaunchAppSysActions) do
    ProceedAction(Profile.BeforeLaunchAppSysActions[i], Profile);
  end;

EraseFileW(Profile.TargetConfigFileName);

dwRes:=Profile.ExportConfig(Index, Profile.ExpandVars(Profile.TargetConfigFileName));
if dwRes <> PROFILE_ERR_SUCCESS then
  begin
  ShowError('Export config "' + Profile.ExpandVars(Profile.TargetConfigFileName) +
            '" failed.' + #13#10 + 'Error: ' + ProfileErrToStr(dwRes));
  Exit;
  end;

if Profile.bLaunchApplication then
  begin
  bWait:=(Profile.AfterLaunchAppAction <> AFTER_LAUNCH_APP_ACTION_EXIT);

  if NOT StartApp(Profile.ExpandVars(Profile.AppPath),
                  Profile.ExpandVars(Profile.AppArgs), hApp) then
    begin
    ShowError('Start application "' + Profile.AppPath + '" failed.');
    Exit;
    end;

  hAppProcess:=hApp;

  hJobObject:=CreateJobObjectW(nil, nil);
  if hJobObject <> 0 then AssignProcessToJobObject(hJobObject, hApp);

  if Profile.AfterLaunchAppAction = AFTER_LAUNCH_APP_ACTION_EXIT then
    begin
    CloseHandle(hApp);
    hApp:=0;
    end;

  MainFormActionProc(Profile.AfterLaunchAppAction);

  if bWait AND (hApp <> 0) then
    begin
    pParams:=PWaitThreadParams(LocalAlloc(LMEM_FIXED, SizeOf(pParams^)));
    pParams^.pProf:=@Profile;
    pParams^.CfgIndex:=Index;
    hThread:=CreateThread(nil, 0, @WaitAppThreadProc, pParams, 0, dwThreadID);
    if hThread <> 0 then CloseHandle(hThread) else ShowError('Start thread failed.');
    end;
  end;

end;



end.
