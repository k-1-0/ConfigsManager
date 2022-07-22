unit ProfileClass;

interface

uses Windows, SysUtils, Classes, Crypt, Utils;


const

  CFG_MGR_DB_SIGN                              = $42444D43; // "CMDB"
  CFG_MGR_DB_VESRION                           = $0001;

  MAX_PROFILE_NAME_LEN                         = 20;
  MAX_CONFIG_NAME_LEN                          = 32;

  AFTER_LAUNCH_APP_ACTION_NONE                 = 0;
  AFTER_LAUNCH_APP_ACTION_MINIMIZE             = 1;
  AFTER_LAUNCH_APP_ACTION_TRAY                 = 2;
  AFTER_LAUNCH_APP_ACTION_HIDE                 = 3;
  AFTER_LAUNCH_APP_ACTION_EXIT                 = 4;
  AFTER_LAUNCH_APP_ACTION_RESTORE              = 5;

  MAINFORM_ACTION_NONE                         = AFTER_LAUNCH_APP_ACTION_NONE;
  MAINFORM_ACTION_MINIMIZE                     = AFTER_LAUNCH_APP_ACTION_MINIMIZE;
  MAINFORM_ACTION_TRAY                         = AFTER_LAUNCH_APP_ACTION_TRAY;
  MAINFORM_ACTION_HIDE                         = AFTER_LAUNCH_APP_ACTION_HIDE;
  MAINFORM_ACTION_EXIT                         = AFTER_LAUNCH_APP_ACTION_EXIT;
  MAIN_FORM_ACTION_RESTORE                     = AFTER_LAUNCH_APP_ACTION_RESTORE;
  MAINFORM_ACTION_APP_STARTED                  = 10;
  MAINFORM_ACTION_APP_ENDED                    = 11;


  AFTER_ENDING_APP_ACTION_NONE                 = 0;
  AFTER_ENDING_APP_ACTION_RESTORE              = 1;
  AFTER_ENDING_APP_ACTION_EXIT                 = 2;

  SYS_ACTION_ERASE_FILE_PREFIX                 = 'EF_';
  SYS_ACTION_CLEAR_DIRECTORY_PREFIX            = 'CD_';
  SYS_ACTION_ERASE_REG_VALUE_PREFIX            = 'EV_';
  SYS_ACTION_ERASE_REG_KEY_PREFIX              = 'EK_';
  SYS_ACTION_CLEAR_REG_KEY_PREFIX              = 'CK_';
  SYS_ACTION_EXECUTE_PREFIX                    = 'XV_';

  HKLM_SHORT_STR                               = 'hklm\';
  HKCU_SHORT_STR                               = 'hkcu\';
  HKCR_SHORT_STR                               = 'hkcr\';
  HKLM_LONG_STR                                = 'hkey_local_machine\';
  HKCU_LONG_STR                                = 'hkey_current_user\';
  HKCR_LONG_STR                                = 'hkey_classes_root\';

  PROFILE_ERR_SUCCESS                             = 0;
  PROFILE_ERR_AUTH_FAILED                         = 1;
  PROFILE_ERR_PROFILE_DIRECTORY_NOT_FOUND         = 2;
  PROFILE_ERR_PROFILE_FILE_NOT_FOUND              = 3;
  PROFILE_ERR_CONFIG_FILE_NOT_FOUND               = 4;
  PROFILE_ERR_DELETE_PROFILE_FILE_FAILED          = 5;
  PROFILE_ERR_SAVE_VALUE_FAILED                   = 6;
  PROFILE_ERR_READ_VALUE_FAILED                   = 7;
  PROFILE_ERR_CONFIG_NAME_EXISTS                  = 8;
  PROFILE_ERR_DELETE_INI_SECTION_FAILED           = 9;
  PROFILE_ERR_INVALID_CONFIG_INDEX                = 10;
  PROFILE_ERR_DELETE_CONFIG_FILE_FAILED           = 11;
  PROFILE_ERR_DB_FILENAME_NOT_FOUND               = 13;
  PROFILE_ERR_GET_MEMORY_FOR_DB_DATA_FAILED       = 14;
  PROFILE_ERR_GET_MEMORY_FOR_PROFILE_DATA_FAILED  = 15;
  PROFILE_ERR_PASSWORD_NOT_FOUND                  = 16;
  PROFILE_ERR_PROFILE_NAME_NOT_FOUND              = 17;
  PROFILE_ERR_TARGET_CONFIG_NOT_FOUND             = 18;
  PROFILE_ERR_ADD_RECORD_TO_DATA_FAILED           = 19;
  PROFILE_ERR_ADD_PROFILE_DATA_FAILED             = 20;
  PROFILE_ERR_ADD_BEFORE_LAUNCH_APP_ACTION_FAILED = 21;
  PROFILE_ERR_ADD_AFTER_LAUNCH_APP_ACTION_FAILED  = 22;
  PROFILE_ERR_ADD_CONFIG_FAILED                   = 23;
  PROFILE_ERR_DELETE_DB_FILE_FAILED               = 24;
  PROFILE_ERR_WRITE_DB_FILE_FAILED                = 25;
  PROFILE_ERR_CREATE_DB_FILE_FAILED               = 26;
  PROFILE_ERR_CONFIG_NAME_TOO_LONG                = 27;
  PROFILE_ERR_OPEN_CONFIG_FILE_FAILED             = 29;
  PROFILE_ERR_CONFIG_FILE_IS_EMPTY                = 30;
  PROFILE_ERR_GET_MEM_FOR_READ_CONFIG_FAILED      = 31;
  PROFILE_ERR_READ_CONFIG_FILE_FAILED             = 32;
  PROFILE_ERR_GET_MEM_FOR_CONFIG_DATA_FAILED      = 33;
  PROFILE_ERR_DB_FILE_NOT_FOUND                   = 34;
  PROFILE_ERR_OPEN_DB_FILE_FAILED                 = 35;
  PROFILE_ERR_DB_FILE_TOO_SMALL                   = 36;
  PROFILE_ERR_GET_MEM_FOR_READ_DB_FAILED          = 37;
  PROFILE_ERR_READ_DB_FILE_FAILED                 = 38;
  PROFILE_ERR_DECRYPT_DB_FAILED                   = 39;
  PROFILE_ERR_UNSUPPORTED_VERSION                 = 40;
  PROFILE_ERR_INVALID_DATA_SIGN                   = 41;
  PROFILE_ERR_DELETE_FILE_FAILED                  = 42;
  PROFILE_ERR_WRITE_FILE_FAILED                   = 43;
  PROFILE_ERR_CREATE_FILE_FAILED                  = 44;

  R_CONFIG_DATA                      = 1;
  R_PROFILE_DATA                     = 2;
  R_BEFORE_LAUNCH_APP_SYS_ACTION     = 3;
  R_AFTER_ENDING_APP_SYS_ACTION      = 4;


var
  CHECKING_BLOCK_CONTROL_VALUE: T128bit = ($71A41E23, $33C3B9C9, $21765406, $EC3E42D1);
  
type

  // структура для хранения конфига в экземпляре класса
  TConfig = record
    CfgName: WideString;
    PlainCfgHash: T128bit;
    dwDataSize: DWORD;
    pData: Pointer;
    end;
  PConfig = ^TConfig;

  // структура для хранения конфига в данных БД
  TBinDBConfig = packed record
    CfgName: packed Array[0..MAX_CONFIG_NAME_LEN - 1] of WideChar;
    PlainCfgHash: T128bit;
    dwDataSize: DWORD;
    Data: packed Array[0..0] of Byte;
    end;
  PBinDBConfig = ^TBinDBConfig;

  TCfgList = Array of TConfig;

  TIcon16x16Pixels = packed Array[0..15, 0..15] of COLORREF;

  TIconData = packed record
                dwTransparentColor: COLORREF;
                Pixels: TIcon16x16Pixels;
              end;
  PIConData = ^TIconData;

  TDbRecord = packed record
    RecordType: Byte;
    dwDataSize: DWORD;
    Data: packed Array[0..0] of Byte;
  end;
  PDbRecord = ^TDbRecord;

  TBinDBHeader = packed record
    Sign: DWORD;
    wBinDbVersion: WORD;
    Salt: packed Array[0..SALT_SIZE - 1] of WideChar;
    IV: T128bit;
    RandomBlock: T128bit;
    CheckingBlock: T128bit;
  end;
  PBinDBHeader = ^TBinDBHeader;

  TBinDBProfileData = packed record
    ProfileName: packed Array[0..MAX_PROFILE_NAME_LEN - 1] of WideChar;
    TargetConfig: packed Array[0..MAX_PATH - 1] of WideChar;
    AppPath: packed Array[0..MAX_PATH - 1] of WideChar;
    AppArgs: packed Array[0..MAX_PATH - 1] of WideChar;
    bLaunchApp: Boolean;
    bUpdateConfigAfterAppEnded: Boolean;
    bDeleteConfigAfterAppEnded: Boolean;
    AfterLaunchAppAction: Byte;
    AfterEndAppAction: Byte;
    bIconPresented: Boolean;
    IconData: TIconData;
  end;
  PBinDBProfileData = ^TBinDBProfileData;


{ TProfile }

  TProfile = class
  private
    FpDBData: Pointer;
    FdwDBDataSize: DWORD;
    FProfileName: WideString;
    FDbFileName: WideString;
    FTargetConfigFileName: WideString;
    FbIconPresented: Boolean;
    FbIconChanged: Boolean;
    FIconData: TIconData;
    FPassword: WideString;
    FAppPath: WideString;
    FAppArgs: WideString;
    FbLaunchApplication: Boolean;
    FbUpdateConfigAfterAppEnded: Boolean;
    FbDeleteConfigAfterAppEnded: Boolean;
    FAfterLaunchAppAction: Integer;
    FAfterEndingAppAction: Integer;
    FBeforeLaunchAppSysActions: TWideStringArray;
    FAfterEndingAppSysActions: TWideStringArray;
    FConfigs: TCfgList;
  public
    property ProfileName: WideString read FProfileName write FProfileName;
    property DbFileName: WideString read FDbFileName write FDbFileName;
    property TargetConfigFileName: WideString read FTargetConfigFileName write FTargetConfigFileName;
    property bIconPresented: Boolean read FbIconPresented write FbIconPresented;
    property bIconChanged: Boolean read FbIconChanged write FbIconChanged;
    property IconData: TIconData read FIconData write FIconData;
    property AppPath: WideString read FAppPath write FAppPath;
    property AppArgs: WideString read FAppArgs write FAppArgs;
    property Password: WideString read FPassword write FPassword;
    property bLaunchApplication: Boolean read FbLaunchApplication write FbLaunchApplication;
    property bUpdateConfigAfterAppEnded: Boolean read FbUpdateConfigAfterAppEnded write FbUpdateConfigAfterAppEnded;
    property bDeleteConfigAfterAppEnded: Boolean read FbDeleteConfigAfterAppEnded write FbDeleteConfigAfterAppEnded;
    property AfterLaunchAppAction: Integer read FAfterLaunchAppAction write FAfterLaunchAppAction;
    property AfterEndingAppAction: Integer read FAfterEndingAppAction write FAfterEndingAppAction;
    property BeforeLaunchAppSysActions: TWideStringArray read FBeforeLaunchAppSysActions write FBeforeLaunchAppSysActions;
    property AfterEndingAppSysActions: TWideStringArray read FAfterEndingAppSysActions write FAfterEndingAppSysActions;
    procedure ClearBeforeLaunchAppActions;
    procedure ClearAfterEndingAppActions;
    procedure AddBeforeLaunchAppAction(const ActionStr: WideString);
    procedure AddAfterEndingAppAction(const ActionStr: WideString);
    property Configs: TCfgList read FConfigs write FConfigs;
    constructor Create;
    destructor Destroy; override;
    function SaveProfile: DWORD;
    procedure FreeConfigData(const nIndex: Integer);
    procedure ZeroData;
    procedure EncryptDbData;
    function DecryptDbData: DWORD;
    function CheckDBDataVersion: DWORD;
    procedure ProceedRecord(const RecordType: Byte; const pData: Pointer; const dwSize: DWORD);
    procedure ParseDbData;
    function ReadDbFile: DWORD;
    function Load(const FileName, Password: WideString): DWORD;
    function CheckData: DWORD;
    function WriteDbData: DWORD;
    function PrepareDbData: DWORD;
    function AddConfigToDbData(const nIndex: Integer): Boolean;
    function AddRecordToDbData(const RecordType: Byte; const pData: Pointer;
                               const dwDataSize: DWORD): Boolean;
    function AddWideStringToDbData(const RecordType: Byte; const StrW: WideString): Boolean;
    procedure FreeDbData;
    function ImportConfigFromDB(const pBinDbCfg: PBinDBConfig;
                                const dwSize: DWORD): DWORD;
    function AddConfig(const NewConfigName, NewConfigFileName: WideString): DWORD;
    function InternalAddConfig(const NewConfigName: WideString;
                               const pData: Pointer;
                               const dwSize: DWORD;
                               const pPlainHash: P128bit): DWORD;
    function DeleteConfig(const Index: Integer): DWORD;
    function MoveConfigUp(const Index: Integer): DWORD;
    function MoveConfigDown(const Index: Integer): DWORD;
    function ExportConfig(const Index: Integer; const FileName: WideString): DWORD;
    function UpdateConfigFromTarget(const Index: Integer): DWORD;
    function ExpandVars(const SrcStr: WideString): WideString;
  published

  end;

  PProfile = ^TProfile;


function ProfileErrToStr(const dwErrCode: DWORD): WideString;


implementation


function ProfileErrToStr(const dwErrCode: DWORD): WideString;
var
dwSysError: DWORD;
begin
dwSysError:=GetLastError;
case dwErrCode of
  PROFILE_ERR_SUCCESS                        : result:='PROFILE_ERR_SUCCESS';
  //PROFILE_ERR_AUTH_FAILED                    : result:='PROFILE_ERR_AUTH_FAILED';
  PROFILE_ERR_PROFILE_DIRECTORY_NOT_FOUND    : result:='PROFILE_ERR_PROFILE_DIRECTORY_NOT_FOUND';
  PROFILE_ERR_PROFILE_FILE_NOT_FOUND         : result:='PROFILE_ERR_PROFILE_FILE_NOT_FOUND';
  PROFILE_ERR_CONFIG_FILE_NOT_FOUND          : result:='PROFILE_ERR_CONFIG_FILE_NOT_FOUND';
  PROFILE_ERR_DELETE_PROFILE_FILE_FAILED     : result:='PROFILE_ERR_DELETE_PROFILE_FILE_FAILED';
  PROFILE_ERR_SAVE_VALUE_FAILED              : result:='PROFILE_ERR_SAVE_VALUE_FAILED';
  PROFILE_ERR_READ_VALUE_FAILED              : result:='PROFILE_ERR_READ_VALUE_FAILED';
  PROFILE_ERR_CONFIG_NAME_EXISTS             : result:='PROFILE_ERR_CONFIG_NAME_EXISTS';
  PROFILE_ERR_DELETE_INI_SECTION_FAILED      : result:='PROFILE_ERR_DELETE_INI_SECTION_FAILED';
  PROFILE_ERR_INVALID_CONFIG_INDEX           : result:='PROFILE_ERR_INVALID_CONFIG_INDEX';
  PROFILE_ERR_DELETE_CONFIG_FILE_FAILED      : result:='PROFILE_ERR_DELETE_CONFIG_FILE_FAILED';
  PROFILE_ERR_DB_FILENAME_NOT_FOUND          : result:='PROFILE_ERR_DB_FILENAME_NOT_FOUND';
  PROFILE_ERR_GET_MEMORY_FOR_DB_DATA_FAILED  : result:='PROFILE_ERR_GET_MEMORY_FOR_DB_DATA_FAILED';
  PROFILE_ERR_PASSWORD_NOT_FOUND             : result:='PROFILE_ERR_PASSWORD_NOT_FOUND';
  PROFILE_ERR_PROFILE_NAME_NOT_FOUND         : result:='PROFILE_ERR_PROFILE_NAME_NOT_FOUND';
  PROFILE_ERR_TARGET_CONFIG_NOT_FOUND        : result:='PROFILE_ERR_TARGET_CONFIG_NOT_FOUND';
  PROFILE_ERR_ADD_RECORD_TO_DATA_FAILED      : result:='PROFILE_ERR_ADD_RECORD_TO_DATA_FAILED';
  PROFILE_ERR_DELETE_DB_FILE_FAILED          : result:='PROFILE_ERR_DELETE_DB_FILE_FAILED';
  PROFILE_ERR_WRITE_DB_FILE_FAILED           : result:='PROFILE_ERR_WRITE_DB_FILE_FAILED';
  PROFILE_ERR_CREATE_DB_FILE_FAILED          : result:='PROFILE_ERR_CREATE_DB_FILE_FAILED';
  PROFILE_ERR_CONFIG_NAME_TOO_LONG           : result:='PROFILE_ERR_CONFIG_NAME_TOO_LONG';
  PROFILE_ERR_OPEN_CONFIG_FILE_FAILED        : result:='PROFILE_ERR_OPEN_CONFIG_FILE_FAILED';
  PROFILE_ERR_CONFIG_FILE_IS_EMPTY           : result:='PROFILE_ERR_CONFIG_FILE_IS_EMPTY';
  PROFILE_ERR_GET_MEM_FOR_READ_CONFIG_FAILED : result:='PROFILE_ERR_GET_MEM_FOR_READ_CONFIG_FAILED';
  PROFILE_ERR_READ_CONFIG_FILE_FAILED        : result:='PROFILE_ERR_READ_CONFIG_FILE_FAILED';
  PROFILE_ERR_GET_MEM_FOR_CONFIG_DATA_FAILED : result:='PROFILE_ERR_GET_MEM_FOR_CONFIG_DATA_FAILED';
  PROFILE_ERR_DB_FILE_NOT_FOUND              : result:='PROFILE_ERR_DB_FILE_NOT_FOUND';
  PROFILE_ERR_OPEN_DB_FILE_FAILED            : result:='PROFILE_ERR_OPEN_DB_FILE_FAILED';
  PROFILE_ERR_DB_FILE_TOO_SMALL              : result:='PROFILE_ERR_DB_FILE_TOO_SMALL';
  PROFILE_ERR_GET_MEM_FOR_READ_DB_FAILED     : result:='PROFILE_ERR_GET_MEM_FOR_READ_DB_FAILED';
  PROFILE_ERR_READ_DB_FILE_FAILED            : result:='PROFILE_ERR_READ_DB_FILE_FAILED';
  PROFILE_ERR_DECRYPT_DB_FAILED              : result:='PROFILE_ERR_DECRYPT_DB_FAILED';
  PROFILE_ERR_UNSUPPORTED_VERSION            : result:='PROFILE_ERR_UNSUPPORTED_VERSION';
  PROFILE_ERR_INVALID_DATA_SIGN              : result:='PROFILE_ERR_INVALID_DATA_SIGN';
  PROFILE_ERR_DELETE_FILE_FAILED             : result:='PROFILE_ERR_DELETE_FILE_FAILED';
  PROFILE_ERR_WRITE_FILE_FAILED              : result:='PROFILE_ERR_WRITE_FILE_FAILED';
  PROFILE_ERR_CREATE_FILE_FAILED             : result:='PROFILE_ERR_CREATE_FILE_FAILED';

  else                                        result:=' # ' + IntToStr(dwErrCode);
  end;

if dwSysError <> ERROR_SUCCESS then result:=result + #13#10#13#10 + GetSysErrorText(dwSysError);
end;



procedure TProfile.FreeConfigData(const nIndex: Integer);
begin
if NOT (nIndex in [Low(FConfigs)..High(FConfigs)]) then Exit;
ZeroWideString(FConfigs[nIndex].CfgName);
ZeroMemory(@FConfigs[nIndex].PlainCfgHash, SizeOf(FConfigs[nIndex].PlainCfgHash));
if FConfigs[nIndex].pData <> nil then
  begin
  ZeroMemory(FConfigs[nIndex].pData, FConfigs[nIndex].dwDataSize);
  LocalFree(HLOCAL(FConfigs[nIndex].pData));
  end;
end;



procedure TProfile.ZeroData;
var
i: Integer;
begin
if FpDBData <> nil then LocalFree(HLOCAL(FpDBData));
FpDBData:=nil;
SetLength(FDBFileName, 0);
SetLength(FPassword, 0);
SetLength(FTargetConfigFileName, 0);
SetLength(FAppPath, 0);
SetLength(FAppArgs, 0);
ZeroMemory(@FIconData, SizeOf(FIconData));
FbLaunchApplication:=false;
FbUpdateConfigAfterAppEnded:=false;
FbDeleteConfigAfterAppEnded:=false;
FAfterLaunchAppAction:=0;
FAfterEndingAppAction:=0;
ZeroWideStringArray(FBeforeLaunchAppSysActions);
ZeroWideStringArray(FAfterEndingAppSysActions);
for i:=Low(FConfigs) to High(FConfigs) do FreeConfigData(i);
SetLength(FConfigs, 0);
end;




constructor TProfile.Create;
begin
ZeroData;
end;




destructor TProfile.Destroy;
begin
ZeroData;
inherited;
end;


function TProfile.CheckData: DWORD;
begin
if FDbFileName = '' then
  begin
  result:=PROFILE_ERR_DB_FILENAME_NOT_FOUND;
  Exit;    
  end;
if FProfileName = '' then
  begin
  result:=PROFILE_ERR_PROFILE_NAME_NOT_FOUND;
  Exit;
  end;
if FPassword = '' then
  begin
  result:=PROFILE_ERR_PASSWORD_NOT_FOUND;
  Exit;
  end;
if FTargetConfigFileName = '' then
  begin
  result:=PROFILE_ERR_TARGET_CONFIG_NOT_FOUND;
  Exit;
  end;
result:=PROFILE_ERR_SUCCESS;
end;



function TProfile.WriteDbData: DWORD;
var
hDB: THandle;
dwBytes: DWORD;
begin
if FileExistsW(FDbFileName) then
  begin
  EraseFileW(FDbFileName);
  if FileExistsW(FDbFileName) then
    begin
    result:=PROFILE_ERR_DELETE_PROFILE_FILE_FAILED;
    Exit;
    end;
  end;

hDB:=CreateFileW(PWideChar(FDbFileName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
                 FILE_ATTRIBUTE_NORMAL, 0);
if hDB <> INVALID_HANDLE_VALUE then
  begin
  if WriteFile(hDB, FpDBData^, FdwDBDataSize, dwBytes, nil) AND
              (dwBytes = FdwDBDataSize)
    then result:=PROFILE_ERR_SUCCESS
    else result:=PROFILE_ERR_WRITE_DB_FILE_FAILED;
  CloseHandle(hDB);
  end
else result:=PROFILE_ERR_CREATE_DB_FILE_FAILED;
end;




function TProfile.AddRecordToDbData(const RecordType: Byte; const pData: Pointer;
                                    const dwDataSize: DWORD): Boolean;
var
pRec: PDbRecord;
begin
result:=(FpDBData <> nil);
if NOT result then Exit;
if (pData = nil) OR (dwDataSize = 0) then Exit;
FpDBData:=Pointer(LocalRealloc(HLOCAL(FpDBData),
                               FdwDBDataSize + dwDataSize + SizeOf(TDbRecord) - 1,
                               LMEM_MOVEABLE));
result:=FpDBData <> nil;
if result then
  begin
  pRec:=Pointer(NativeUINT(FpDBData) + FdwDBDataSize);
  pRec^.RecordType:=RecordType;
  pRec^.dwDataSize:=dwDataSize;
  CopyMemory(@pRec^.Data, pData, dwDataSize);
  inc(FdwDBDataSize, dwDataSize + SizeOf(TDbRecord) - 1);
  end;
end;



//function TProfile.AddBooleanToDbData(const RecordType: Byte; const bValue: Boolean): Boolean;
//var
//bBoolData: Boolean;
//begin
//bBoolData:=bValue;
//result:=AddRecordToDbData(RecordType, @bBoolData, SizeOf(Boolean));
//end;

//function TProfile.AddByteToDbData(const RecordType: Byte; const Value: Byte): Boolean;
//var
//ByteData: Byte;
//begin
//ByteData:=Value;
//result:=AddRecordToDbData(RecordType, @ByteData, SizeOf(Byte));
//end;



function TProfile.AddWideStringToDbData(const RecordType: Byte; const StrW: WideString): Boolean;
begin
result:=length(StrW) = 0;
if result then Exit; // если пустая строка, то ничего не добавляется и возвращается true
result:=AddRecordToDbData(RecordType, PWideChar(StrW), length(StrW) shl 1);
end;



function TProfile.AddConfigToDbData(const nIndex: Integer): Boolean;
var
pBinDBCfg: PBinDBConfig;
begin
result:=nIndex in [Low(FConfigs)..High(FConfigs)];
if NOT result then Exit;

pBinDBCfg:=PBinDBConfig(LocalAlloc(LMEM_FIXED,
                                   SizeOf(pBinDBCfg^) - 1 + FConfigs[nIndex].dwDataSize));
result:=pBinDBCfg <> nil;
if NOT result then Exit;

ZeroMemory(@pBinDBCfg^.CfgName, SizeOf(pBinDBCfg^.CfgName));
CopyMemory(@pBinDBCfg^.CfgName,
           PWideChar(FConfigs[nIndex].CfgName),
           length(FConfigs[nIndex].CfgName) shl 1);

pBinDBCfg^.dwDataSize:=FConfigs[nIndex].dwDataSize;

pBinDBCfg^.PlainCfgHash[0]:=FConfigs[nIndex].PlainCfgHash[0];
pBinDBCfg^.PlainCfgHash[0]:=FConfigs[nIndex].PlainCfgHash[1];
pBinDBCfg^.PlainCfgHash[0]:=FConfigs[nIndex].PlainCfgHash[2];
pBinDBCfg^.PlainCfgHash[0]:=FConfigs[nIndex].PlainCfgHash[3];

if FConfigs[nIndex].CfgName <> '-'
  then CopyMemory(@pBinDBCfg^.Data, FConfigs[nIndex].pData, FConfigs[nIndex].dwDataSize);

result:=AddRecordToDbData(R_CONFIG_DATA , pBinDBCfg,
                          SizeOf(pBinDBCfg^) - 1 + FConfigs[nIndex].dwDataSize);

LocalFree(HLOCAL(pBinDBCfg));
end;



function TProfile.PrepareDbData: DWORD;
var
i: Integer;
pProfileData: PBinDBProfileData;
pRecord: PDbRecord;
begin
if FpDBData <> nil then LocalFree(HLOCAL(FpDBData));
FdwDBDataSize:=SizeOf(TBinDBHeader) + SizeOf(TBinDBProfileData) +
               SizeOf(pRecord^.RecordType) + SizeOf(pRecord^.dwDataSize);
FpDBData:=Pointer(LocalAlloc(LMEM_FIXED, FdwDBDataSize));

if FpDBData = nil then
  begin
  FdwDBDataSize:=0;
  result:=PROFILE_ERR_GET_MEMORY_FOR_DB_DATA_FAILED;
  Exit;
  end;

ZeroMemory(FpDBData, FdwDBDataSize);

PBinDBHeader(FpDBData)^.Sign:=CFG_MGR_DB_SIGN;
PBinDBHeader(FpDBData)^.wBinDbVersion:=CFG_MGR_DB_VESRION;

pRecord:=PDbRecord(NativeUINT(FpDBData) + SizeOf(TBinDBHeader));
pRecord^.RecordType:=R_PROFILE_DATA;
pRecord^.dwDataSize:=SizeOf(TBinDBProfileData);

pProfileData:=PBinDBProfileData(NativeUINT(FpDBData) + SizeOf(TBinDBHeader) +
                                SizeOf(pRecord^.RecordType) + SizeOf(pRecord^.dwDataSize));

CopyMemory(@pProfileData^.ProfileName, PWideChar(FProfileName), length(FProfileName) shl 1);
CopyMemory(@pProfileData^.TargetConfig, PWideChar(FTargetConfigFileName), length(FTargetConfigFileName) shl 1);
CopyMemory(@pProfileData^.AppPath, PWideChar(FAppPath), length(FAppPath) shl 1);
CopyMemory(@pProfileData^.AppArgs, PWideChar(FAppArgs), length(FAppArgs) shl 1);
pProfileData^.bLaunchApp:=FbLaunchApplication;
pProfileData^.bUpdateConfigAfterAppEnded:=FbUpdateConfigAfterAppEnded;
pProfileData^.bDeleteConfigAfterAppEnded:=FbDeleteConfigAfterAppEnded;
pProfileData^.AfterLaunchAppAction:=FAfterLaunchAppAction;
pProfileData^.AfterEndAppAction:=FAfterEndingAppAction;
pProfileData^.bIconPresented:=FbIconPresented;
if FbIconPresented then CopyMemory(@pProfileData^.IconData, @FIconData, SizeOf(FIconData));

if length(FBeforeLaunchAppSysActions) > 0 then
  begin
  for i:=Low(FBeforeLaunchAppSysActions) to High(FBeforeLaunchAppSysActions) do
    begin
    if NOT AddWideStringToDbData(R_BEFORE_LAUNCH_APP_SYS_ACTION, FBeforeLaunchAppSysActions[i]) then
      begin
      result:=PROFILE_ERR_ADD_BEFORE_LAUNCH_APP_ACTION_FAILED;
      Exit;
      end;
    end;
  end;

if length(FAfterEndingAppSysActions) > 0 then
  begin
  for i:=Low(FAfterEndingAppSysActions) to High(FAfterEndingAppSysActions) do
    begin
    if NOT AddWideStringToDbData(R_AFTER_ENDING_APP_SYS_ACTION, FAfterEndingAppSysActions[i]) then
      begin
      result:=PROFILE_ERR_ADD_AFTER_LAUNCH_APP_ACTION_FAILED;
      Exit;
      end;
    end;
  end;

if length(FConfigs) > 0 then
  begin
  for i:=Low(FConfigs) to High(FConfigs) do
    begin
    if NOT AddConfigToDbData(i) then
      begin
      result:=PROFILE_ERR_ADD_CONFIG_FAILED;
      Exit;
      end;
    end;
  end;

result:=PROFILE_ERR_SUCCESS;
end;



procedure TProfile.EncryptDbData;
var
pHdr: PBinDBHeader;
SaltStrW: WideString;
begin
pHdr:=PBinDBHeader(FpDBData);

Crypt_GenerateRandom128bit(@pHdr^.RandomBlock);

Crypt_Xor128bit(@pHdr^.RandomBlock,
                @CHECKING_BLOCK_CONTROL_VALUE,
                @pHdr^.CheckingBlock);

Crypt_GenerateSalt(@pHdr^.Salt); // 12 WideChars
SetString(SaltStrW, PWideChar(@pHdr^.Salt), length(pHdr^.Salt));

Crypt_GenerateRandom128bit(@pHdr^.IV);

Crypt_SetKey(FPassword, SaltStrW);

// Шифруются данные, начиная с RandomBlock заголовка.
// B открытом виде остается Sign, wBinDbVersion, Salt и IV
Crypt_CryptMemory_CTR(@pHdr^.RandomBlock,
                      FdwDBDataSize - (SizeOf(pHdr^.Sign) + SizeOf(pHdr^.wBinDbVersion) + SizeOf(pHdr^.Salt) + SizeOf(pHdr^.IV)),
                      @pHdr^.IV);   
end;



function TProfile.DecryptDbData: DWORD;
var
pHdr: PBinDBHeader;
SaltStrW: WideString;
CheckingValue: T128bit;
begin
pHdr:=PBinDBHeader(FpDBData);

SetString(SaltStrW, PWideChar(@pHdr^.Salt), length(pHdr^.Salt));

Crypt_SetKey(FPassword, SaltStrW);

// Дешифруются данные, начиная с RandomBlock заголовка.
Crypt_CryptMemory_CTR(@pHdr^.RandomBlock,
                      FdwDBDataSize - (SizeOf(pHdr^.Sign) + SizeOf(pHdr^.wBinDbVersion) + SizeOf(pHdr^.Salt) + SizeOf(pHdr^.IV)),
                      @pHdr^.IV);

// Проверка правильности дешифрования
Crypt_Xor128bit(@pHdr^.RandomBlock[0],
                @pHdr^.CheckingBlock,
                @CheckingValue);

if Crypt_CompareMem128(@CheckingValue, @CHECKING_BLOCK_CONTROL_VALUE)
  then result:=PROFILE_ERR_SUCCESS
  else result:=PROFILE_ERR_DECRYPT_DB_FAILED;
end;



procedure TProfile.FreeDbData;
begin
if (FpDBData = nil) OR (FdwDBDataSize = 0) then Exit;
ZeroMemory(FpDBData, FdwDBDataSize);
LocalFree(HLOCAL(FpDBData));
end;



function TProfile.SaveProfile: DWORD;
begin
result:=CheckData;
if result = PROFILE_ERR_SUCCESS then
  begin
  result:=PrepareDbData;
  if result = PROFILE_ERR_SUCCESS then
    begin
    EncryptDbData;
    result:=WriteDbData;
    FreeDbData;
    end;
  end;

if result <> PROFILE_ERR_SUCCESS then EraseFileW(FDbFileName);
end;




function TProfile.ReadDbFile: DWORD;
var
hDB: HFILE;
dwBytes: DWORD;
begin
hDB:=CreateFileW(PWideChar(FDbFileName), GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
if hDB <> INVALID_HANDLE_VALUE then
  begin
  FdwDBDataSize:=GetFileSize(hDB, nil);
  if FdwDBDataSize > SizeOf(TBinDBHeader) then
    begin
    FpDBData:=Pointer(LocalAlloc(LMEM_FIXED, FdwDBDataSize));
    if FpDBData <> nil then
      begin
      if ReadFile(hDB, FpDBData^, FdwDBDataSize, dwBytes, nil) AND
                 (dwBytes = FdwDBDataSize)
        then result:=PROFILE_ERR_SUCCESS
        else result:=PROFILE_ERR_READ_DB_FILE_FAILED;
      end
    else result:=PROFILE_ERR_GET_MEM_FOR_READ_DB_FAILED;
    end
  else result:=PROFILE_ERR_DB_FILE_TOO_SMALL;
  CloseHandle(hDB);
  end
else result:=PROFILE_ERR_OPEN_DB_FILE_FAILED;
end;





function TProfile.CheckDBDataVersion: DWORD;
begin
if PBinDBHeader(FpDBData)^.Sign = CFG_MGR_DB_SIGN  then
  begin
  if PBinDBHeader(FpDBData)^.wBinDbVersion = CFG_MGR_DB_VESRION
    then result:=PROFILE_ERR_SUCCESS
    else result:=PROFILE_ERR_UNSUPPORTED_VERSION;
  end
else result:=PROFILE_ERR_INVALID_DATA_SIGN;
end;




function TProfile.InternalAddConfig(const NewConfigName: WideString;
                                    const pData: Pointer;
                                    const dwSize: DWORD;
                                    const pPlainHash: P128bit): DWORD;
var
h: Integer;
begin
SetLength(FConfigs, length(FConfigs) + 1);
h:=High(FConfigs);
FConfigs[h].CfgName:=NewConfigName;
FConfigs[h].dwDataSize:=dwSize;

if NewConfigName = '-' then
  begin
  FConfigs[h].PlainCfgHash[0]:=0;
  FConfigs[h].PlainCfgHash[1]:=0;
  FConfigs[h].PlainCfgHash[2]:=0;
  FConfigs[h].PlainCfgHash[3]:=0;
  FConfigs[h].pData:=nil;
  result:=PROFILE_ERR_SUCCESS;
  end
else
  begin
  FConfigs[h].PlainCfgHash[0]:=pPlainHash^[0];
  FConfigs[h].PlainCfgHash[1]:=pPlainHash^[1];
  FConfigs[h].PlainCfgHash[2]:=pPlainHash^[2];
  FConfigs[h].PlainCfgHash[3]:=pPlainHash^[3];

  FConfigs[h].pData:=Pointer(LocalAlloc(LMEM_FIXED, dwSize));
  if FConfigs[h].pData <> nil then
    begin
    CopyMemory(FConfigs[h].pData, pData, dwSize);
    result:=PROFILE_ERR_SUCCESS;
    end
  else
    begin
    SetLength(FConfigs, length(FConfigs) - 1);
    result:=PROFILE_ERR_GET_MEM_FOR_CONFIG_DATA_FAILED;
    end;
  end;
end;




function TProfile.AddConfig(const NewConfigName, NewConfigFileName: WideString): DWORD;
var
hConfig: HFILE;
pData: Pointer;
dwSize, dwBytes: DWORD;
PlainHash: T128bit;
begin
result:=PROFILE_ERR_SUCCESS;

if NewConfigName = '-' then
  begin
  result:=InternalAddConfig(NewConfigName, nil, 0, nil);
  Exit;
  end;

if length(NewConfigName) > MAX_CONFIG_NAME_LEN then
  begin
  result:=PROFILE_ERR_CONFIG_NAME_TOO_LONG;
  Exit;
  end;

if NOT FileExistsW(NewConfigFileName) then
  begin
  result:=PROFILE_ERR_CONFIG_FILE_NOT_FOUND;
  Exit;
  end;

hConfig:=CreateFileW(PWideChar(NewConfigFileName), GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
if hConfig = INVALID_HANDLE_VALUE then
  begin
  result:=PROFILE_ERR_OPEN_CONFIG_FILE_FAILED;
  Exit;
  end;

dwSize:=GetFileSize(hConfig, nil);
if dwSize = 0 then
  begin
  CloseHandle(hConfig);
  result:=PROFILE_ERR_CONFIG_FILE_IS_EMPTY;
  Exit;
  end;

pData:=Pointer(LocalAlloc(LMEM_FIXED, dwSize));
if pData = nil then
  begin
  CloseHandle(hConfig);
  result:=PROFILE_ERR_GET_MEM_FOR_READ_CONFIG_FAILED;
  Exit;
  end;

if NOT (ReadFile(hConfig, pData^, dwSize, dwBytes, nil) AND (dwBytes = dwSize))
  then result:=PROFILE_ERR_READ_CONFIG_FILE_FAILED;

CloseHandle(hConfig);

if result = PROFILE_ERR_SUCCESS then
  begin
  Crypt_Hash128(pData, dwSize, 1, @PlainHash);
  result:=InternalAddConfig(NewConfigName, pData, dwSize, @PlainHash);
  end;
LocalFree(HLOCAL(pData));
end;



function TProfile.ImportConfigFromDb(const pBinDbCfg: PBinDBConfig;
                                     const dwSize: DWORD): DWORD;
var
ConfigName: WideString;
begin
ConfigName:=PWideChar(@pBinDbCfg^.CfgName);
result:=InternalAddConfig(ConfigName, @pBinDbCfg^.Data, pBinDbCfg^.dwDataSize,
                          @pBinDbCfg^.PlainCfgHash);
end;


procedure TProfile.ProceedRecord(const RecordType: Byte; const pData: Pointer; const dwSize: DWORD);
var
sw: WideString;
begin
if (pData = nil) OR (dwSize = 0) then Exit;

case RecordType of
  R_CONFIG_DATA                 : ImportConfigFromDb(PBinDBConfig(pData), dwSize);
  R_PROFILE_DATA                : begin
                                  SetString(FProfileName, PWideChar(@PBinDBProfileData(pData)^.ProfileName),
                                            length(PWideChar(@PBinDBProfileData(pData)^.ProfileName)));
                                  SetString(FTargetConfigFileName, PWideChar(@PBinDBProfileData(pData)^.TargetConfig),
                                            length(PWideChar(@PBinDBProfileData(pData)^.TargetConfig)));
                                  SetString(FAppPath, PWideChar(@PBinDBProfileData(pData)^.AppPath),
                                            length(PWideChar(@PBinDBProfileData(pData)^.AppPath)));
                                  SetString(FAppArgs, PWideChar(@PBinDBProfileData(pData)^.AppArgs),
                                            length(PWideChar(@PBinDBProfileData(pData)^.AppArgs)));
                                  FbLaunchApplication:=PBinDBProfileData(pData)^.bLaunchApp;
                                  FbUpdateConfigAfterAppEnded:=PBinDBProfileData(pData)^.bUpdateConfigAfterAppEnded;
                                  FbDeleteConfigAfterAppEnded:=PBinDBProfileData(pData)^.bDeleteConfigAfterAppEnded;
                                  FAfterLaunchAppAction:=PBinDBProfileData(pData)^.AfterLaunchAppAction;
                                  FAfterEndingAppAction:=PBinDBProfileData(pData)^.AfterEndAppAction;
                                  FbIconPresented:=PBinDBProfileData(pData)^.bIconPresented;
                                  if FbIconPresented then CopyMemory(@FIconData, @PBinDBProfileData(pData)^.IconData, SizeOf(FIconData));
                                  end;

  R_BEFORE_LAUNCH_APP_SYS_ACTION: begin
                                  SetString(sw, PWideChar(pData), dwSize shr 1);
                                  SetLength(FBeforeLaunchAppSysActions, length(FBeforeLaunchAppSysActions) + 1);
                                  FBeforeLaunchAppSysActions[High(FBeforeLaunchAppSysActions)]:=sw;
                                  end;

  R_AFTER_ENDING_APP_SYS_ACTION : begin
                                  SetString(sw, PWideChar(pData), dwSize shr 1);
                                  SetLength(FAfterEndingAppSysActions, length(FAfterEndingAppSysActions) + 1);
                                  FAfterEndingAppSysActions[High(FAfterEndingAppSysActions)]:=sw;
                                  end;
  else                            ;
  end;
end;



procedure TProfile.ParseDbData;
var
pCurrRecord, pEnd: PDbRecord;
begin
if (FpDBData = nil) OR (FdwDBDataSize < SizeOf(TBinDBHeader) + SizeOf(TDbRecord)) then Exit;

pEnd:=PDbRecord(NativeUINT(FpDBData) + FdwDBDataSize);
pCurrRecord:=PDbRecord(NativeUINT(FpDBData) + SizeOf(TBinDBHeader));

while NativeUINT(pCurrRecord) < NativeUINT(pEnd) do
  begin
  ProceedRecord(pCurrRecord^.RecordType, @pCurrRecord^.Data, pCurrRecord^.dwDataSize);
  inc(PByte(pCurrRecord), pCurrRecord^.dwDataSize + SizeOf(TDbRecord) - 1);
  end;
end;




function TProfile.Load(const FileName, Password: WideString): DWORD;
begin
if NOT FileExistsW(FileName) then
  begin
  result:=PROFILE_ERR_DB_FILE_NOT_FOUND;
  Exit;
  end;

ZeroData;

FDbFileName:=FileName;
FPassword:=Password;

result:=ReadDbFile;
if (result = PROFILE_ERR_SUCCESS) AND (FpDBData <> nil) then
  begin
  if CheckDBDataVersion = PROFILE_ERR_SUCCESS then
    begin
    result:=DecryptDbData;
    if result = PROFILE_ERR_SUCCESS then
      begin
      ParseDbData;
      end;
    end;
  end;

if result <> PROFILE_ERR_SUCCESS then ZeroData;
end;



procedure TProfile.AddBeforeLaunchAppAction(const ActionStr: WideString);
begin
SetLength(FBeforeLaunchAppSysActions, length(FBeforeLaunchAppSysActions) + 1);
FBeforeLaunchAppSysActions[High(FBeforeLaunchAppSysActions)]:=ActionStr;
end;



procedure TProfile.AddAfterEndingAppAction(const ActionStr: WideString);
begin
SetLength(FAfterEndingAppSysActions, length(FAfterEndingAppSysActions) + 1);
FAfterEndingAppSysActions[High(FAfterEndingAppSysActions)]:=ActionStr;
end;



procedure TProfile.ClearBeforeLaunchAppActions;
begin
ZeroWideStringArray(FBeforeLaunchAppSysActions);
end;


procedure TProfile.ClearAfterEndingAppActions;
begin
ZeroWideStringArray(FAfterEndingAppSysActions);
end;



function TProfile.MoveConfigUp(const Index: Integer): DWORD;
var
TmpConfig: TConfig;
begin
if (Index > length(FConfigs) - 1) OR (Index < 1) then
  begin
  result:=PROFILE_ERR_INVALID_CONFIG_INDEX;
  Exit;
  end;

TmpConfig:=FConfigs[Index - 1];
FConfigs[Index - 1]:=FConfigs[Index];
FConfigs[Index]:=TmpConfig;

result:=PROFILE_ERR_SUCCESS;
end;



function TProfile.MoveConfigDown(const Index: Integer): DWORD;
var
TmpConfig: TConfig;
begin
if (Index > length(FConfigs) - 1) OR (Index > length(FConfigs) - 1) then
  begin
  result:=PROFILE_ERR_INVALID_CONFIG_INDEX;
  Exit;
  end;

TmpConfig:=FConfigs[Index + 1];
FConfigs[Index + 1]:=FConfigs[Index];
FConfigs[Index]:=TmpConfig;

result:=PROFILE_ERR_SUCCESS;
end;



function TProfile.DeleteConfig(const Index: Integer): DWORD;
var
i: Integer;
begin
if Index > length(FConfigs) - 1 then
  begin
  result:=PROFILE_ERR_INVALID_CONFIG_INDEX;
  Exit;
  end;

ZeroMemory(@FConfigs[Index].PlainCfgHash, SizeOf(FConfigs[Index].PlainCfgHash));
ZeroWideString(FConfigs[Index].CfgName);
if FConfigs[Index].pData <> nil then LocalFree(HLOCAL(FConfigs[Index].pData));
FConfigs[Index].dwDataSize:=0;

for i:=Index to High(FConfigs) - 1 do FConfigs[i]:=FConfigs[i + 1];
SetLength(FConfigs, length(FConfigs) - 1);

result:=PROFILE_ERR_SUCCESS;
end;



function TProfile.ExportConfig(const Index: Integer; const FileName: WideString): DWORD;
var
hDB: THandle;
dwBytes: DWORD;
begin
if FileExistsW(FileName) then
  begin
  EraseFileW(FileName);
  if FileExistsW(FileName) then
    begin
    result:=PROFILE_ERR_DELETE_FILE_FAILED;
    Exit;
    end;
  end;
                             
hDB:=CreateFileW(PWideChar(FileName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
                 FILE_ATTRIBUTE_NORMAL, 0);
if hDB <> INVALID_HANDLE_VALUE then
  begin
  if WriteFile(hDB, FConfigs[Index].pData^, FConfigs[Index].dwDataSize, dwBytes, nil) AND
              (dwBytes = FConfigs[Index].dwDataSize)
    then result:=PROFILE_ERR_SUCCESS
    else result:=PROFILE_ERR_WRITE_FILE_FAILED;
  CloseHandle(hDB);
  end
else result:=PROFILE_ERR_CREATE_FILE_FAILED;
end;


function TProfile.UpdateConfigFromTarget(const Index: Integer): DWORD;
var
hConfig: HFILE;
pData: Pointer;
dwSize, dwBytes: DWORD;
ConfigFileName: WideString;
begin
ConfigFileName:=ExpandVars(FTargetConfigFileName);

if NOT FileExistsW(ConfigFileName) then
  begin
  result:=PROFILE_ERR_CONFIG_FILE_NOT_FOUND;
  Exit;
  end;

hConfig:=CreateFileW(PWideChar(ConfigFileName), GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
if hConfig = INVALID_HANDLE_VALUE then
  begin
  result:=PROFILE_ERR_OPEN_CONFIG_FILE_FAILED;
  Exit;
  end;

dwSize:=GetFileSize(hConfig, nil);
if dwSize = 0 then
  begin
  CloseHandle(hConfig);
  result:=PROFILE_ERR_CONFIG_FILE_IS_EMPTY;
  Exit;
  end;

pData:=Pointer(LocalAlloc(LMEM_FIXED, dwSize));
if pData = nil then
  begin
  CloseHandle(hConfig);
  result:=PROFILE_ERR_GET_MEM_FOR_READ_CONFIG_FAILED;
  Exit;
  end;

if ReadFile(hConfig, pData^, dwSize, dwBytes, nil) AND (dwBytes = dwSize)
  then result:=PROFILE_ERR_SUCCESS
  else result:=PROFILE_ERR_READ_CONFIG_FILE_FAILED;

CloseHandle(hConfig);

if result = PROFILE_ERR_SUCCESS then
  begin
  Crypt_Hash128(pData, dwSize, 1, @FConfigs[Index].PlainCfgHash);
  if FConfigs[Index].pData <> nil then LocalFree(HLOCAL(FConfigs[Index].pData));
  FConfigs[Index].pData:=Pointer(LocalAlloc(LMEM_FIXED, dwSize));
  if FConfigs[Index].pData <> nil then
    begin
    CopyMemory(FConfigs[Index].pData, pData, dwSize);
    FConfigs[Index].dwDataSize:=dwSize;
    result:=PROFILE_ERR_SUCCESS;
    end
  else
    begin
    FConfigs[Index].dwDataSize:=0;
    result:=PROFILE_ERR_GET_MEM_FOR_CONFIG_DATA_FAILED;
    end;
  end;

LocalFree(HLOCAL(pData));
end;




function TProfile.ExpandVars(const SrcStr: WideString): WideString;
var
Str: WideString;
begin
result:=SrcStr;
repeat
  Str:=result;
  result:=StringReplaceW(result, '%PROFILE_DIR%', ExtractFilePathW(FDbFileName));
  result:=StringReplaceW(result, '%TARGET_CONFIG%', FTargetConfigFileName);
  result:=StringReplaceW(result, '%TARGET_CONFIG_DIR%', ExtractFilePathW(FTargetConfigFileName));
  result:=StringReplaceW(result, '%APP_FILE%', FAppPath);
  result:=StringReplaceW(result, '%APP_DIR%', ExtractFilePathW(FAppPath));
  result:=ExpandPathW(result);
until result = Str;
end;



end.
