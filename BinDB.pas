unit BinDB;

interface

uses Windows, Crypt, SysUtils, Utils;


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

  AFTER_ENDING_APP_ACTION_NONE                 = 0;
  AFTER_ENDING_APP_ACTION_RESTORE              = 1;
  AFTER_ENDING_APP_ACTION_EXIT                 = 2;


  BINDB_ERR_SUCCESS                             = 0;
  BINDB_ERR_DB_FILENAME_NOT_FOUND               = 100;
  BINDB_ERR_GET_MEMORY_FOR_DB_DATA_FAILED       = 101;
  BINDB_ERR_GET_MEMORY_FOR_PROFILE_DATA_FAILED  = 102;
  BINDB_ERR_PASSWORD_NOT_FOUND                  = 103;
  BINDB_ERR_PROFILE_NAME_NOT_FOUND              = 104;
  BINDB_ERR_TARGET_CONFIG_NOT_FOUND             = 105;
  BINDB_ERR_ADD_RECORD_TO_DATA_FAILED           = 106;
  BINDB_ERR_ADD_PROFILE_DATA_FAILED             = 107;
  BINDB_ERR_ADD_BEFORE_LAUNCH_APP_ACTION_FAILED = 108;
  BINDB_ERR_ADD_AFTER_LAUNCH_APP_ACTION_FAILED  = 109;
  BINDB_ERR_ADD_CONFIG_FAILED                   = 110;
  BINDB_ERR_DELETE_DB_FILE_FAILED               = 111;
  BINDB_ERR_WRITE_DB_FILE_FAILED                = 112;
  BINDB_ERR_CREATE_DB_FILE_FAILED               = 113;
  BINDB_ERR_CONFIG_NAME_TOO_LONG                = 114;
  BINDB_ERR_CONFIG_FILE_NOT_FOUND               = 115;
  BINDB_ERR_OPEN_CONFIG_FILE_FAILED             = 116;
  BINDB_ERR_CONFIG_FILE_IS_EMPTY                = 117;
  BINDB_ERR_GET_MEM_FOR_READ_CONFIG_FAILED      = 118;
  BINDB_ERR_READ_CONFIG_FILE_FAILED             = 119;
  BINDB_ERR_GET_MEM_FOR_CONFIG_DATA_FAILED      = 120;
  BINDB_ERR_DB_FILE_NOT_FOUND                   = 121;
  BINDB_ERR_OPEN_DB_FILE_FAILED                 = 122;
  BINDB_ERR_DB_FILE_TOO_SMALL                   = 123;
  BINDB_ERR_GET_MEM_FOR_READ_DB_FAILED          = 124;
  BINDB_ERR_READ_DB_FILE_FAILED                 = 125;
  BINDB_ERR_DECRYPT_DB_FAILED                   = 126;
  BINDB_ERR_UNSUPPORTED_VERSION                 = 127;
  BINDB_ERR_INVALID_DATA_SIGN                   = 128;


  R_CONFIG_DATA                      = 1;
  R_PROFILE_DATA                     = 2;
  R_BEFORE_LAUNCH_APP_SYS_ACTION     = 3;
  R_AFTER_ENDING_APP_SYS_ACTION      = 4;



var

  CHECKING_BLOCK_CONTROL_VALUE: T128bit = ($71A41E23, $33C3B9C9, $21765406, $EC3E42D1);


type

  // структура для хранения данных конфига в экземпляре класса
  TConfig = record
    CfgName: WideString;
    PlainCfgHash: T128bit;
    dwDataSize: DWORD;
    pData: Pointer;
    end;
  PConfig = ^TConfig;

  // структура для хранения данных конфига в файле БД
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
    RandomBlock: packed Array[0..3] of T128bit;
    CheckingBlock: packed Array[0..2] of T128bit;
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



{ TBinDB }

  TBinDB = class
  private
    FProfileName: WideString;
    FDBFileName: WideString;
    FpDBData: Pointer;
    FdwDBDataSize: DWORD;
    FTargetConfig: WideString;
    FbIconPresented: Boolean;
    FIconData: TIconData;
    FPassword: WideString;
    FAppPath: WideString;
    FAppArgs: WideString;
    FbLaunchApplication: Boolean;
    FbUpdateConfigAfterAppEnded: Boolean;
    FbDeleteConfigAfterAppEnded: Boolean;
    FAfterLaunchAppAction: Byte;
    FAfterEndingAppAction: Byte;
    FBeforeLaunchAppSysActions: TWideStringArray;
    FAfterEndingAppSysActions: TWideStringArray;
    FConfigs: TCfgList;
    function AddRecordToDbData(const RecordType: Byte; const pData: Pointer;
                               const dwDataSize: DWORD): Boolean;
    //function AddBooleanToDbData(const RecordType: Byte; const bValue: Boolean): Boolean;
    function AddWideStringToDbData(const RecordType: Byte; const StrW: WideString): Boolean;
    //function AddByteToDbData(const RecordType: Byte; const Value: Byte): Boolean;
    function AddConfigToDbData(const nIndex: Integer): Boolean;
    function CheckData: DWORD;
    function CheckBinDBDataVersion: DWORD;
    procedure FreeConfigData(const nIndex: Integer);
    function PrepareBinDBData: DWORD;
    procedure ParseBinDBData;
    procedure EncryptBinDBData;
    function DecryptBinDBData: DWORD;
    function WriteBinDBData: DWORD;
    function ReadDbFile: DWORD;
    procedure FreeBinDBData;                           
    procedure ZeroData;
    procedure ProceedRecord(const RecordType: Byte; const pData: Pointer; const dwSize: DWORD);
    function InternalAddConfig(const NewConfigName: WideString;
                               const pData: Pointer;
                               const dwSize: DWORD;
                               const pPlainHash: P128bit): DWORD;
    function ImportConfigFromBinDB(const pBinDbCfg: PBinDBConfig;
                                   const dwSize: DWORD): DWORD;
  public
    property ProfileName: WideString read FProfileName write FProfileName;
    property DBFileName: WideString read FDBFileName write FDBFileName;
    property TargetConfig: WideString read FTargetConfig write FTargetConfig;
    property bIconPresented: Boolean read FbIconPresented write FbIconPresented;
    property IconData: TIconData read FIconData write FIconData;
    property AppPath: WideString read FAppPath write FAppPath;
    property AppArgs: WideString read FAppArgs write FAppArgs;
    property Password: WideString read FPassword write FPassword;
    property bLaunchApplication: Boolean read FbLaunchApplication write FbLaunchApplication;
    property bUpdateConfigAfterAppEnded: Boolean read FbUpdateConfigAfterAppEnded write FbUpdateConfigAfterAppEnded;
    property bDeleteConfigAfterAppEnded: Boolean read FbDeleteConfigAfterAppEnded write FbDeleteConfigAfterAppEnded;
    property AfterLaunchAppAction: Byte read FAfterLaunchAppAction write FAfterLaunchAppAction;
    property AfterEndingAppAction: Byte read FAfterEndingAppAction write FAfterEndingAppAction;
    property BeforeLaunchAppSysActions: TWideStringArray read FBeforeLaunchAppSysActions write FBeforeLaunchAppSysActions;
    property AfterEndingAppSysActions: TWideStringArray read FAfterEndingAppSysActions write FAfterEndingAppSysActions;
    property Configs: TCfgList read FConfigs write FConfigs;
    procedure AddBeforeLaunchAppSysAction(const ActionStr: WideString);
    procedure AddAfterEndingAppSysAction(const ActionStr: WideString);
    constructor Create;
    destructor Destroy; override;
//    function UpdateProfileFile: DWORD;
//    function SaveNewProfile: DWORD;
    function Load(const FileName, Password: WideString): DWORD;
    function AddConfig(const NewConfigName, NewConfigFileName: WideString): DWORD;
//    function UpdateConfigsInProfileFile: DWORD;
//    function DeleteConfig(const Index: Integer): DWORD;
//    function MoveConfigUp(const Index: Integer): DWORD;
//    function MoveConfigDown(const Index: Integer): DWORD;
    function Save: DWORD;
  published

  end;

  PBinDB = ^TBinDB;


implementation

uses ProfileClass;


{$I dbg.inc}


procedure TBinDB.FreeConfigData(const nIndex: Integer);
begin
if NOT (nIndex in [Low(FConfigs)..High(FConfigs)]) then Exit;
SetLength(FConfigs[nIndex].CfgName, 0);
ZeroMemory(@FConfigs[nIndex].PlainCfgHash, SizeOf(FConfigs[nIndex].PlainCfgHash));
if FConfigs[nIndex].pData <> nil then LocalFree(HLOCAL(FConfigs[nIndex].pData));
end;


procedure TBinDB.ZeroData;
var
i: Integer;
begin
FpDBData:=nil;
SetLength(FDBFileName, 0);
SetLength(FProfileName, 0);
SetLength(FPassword, 0);
SetLength(FTargetConfig, 0);
SetLength(FAppPath, 0);
SetLength(FAppArgs, 0);
ZeroMemory(@FIconData, SizeOf(FIconData));
FbLaunchApplication:=false;
FbUpdateConfigAfterAppEnded:=false;
FbDeleteConfigAfterAppEnded:=false;
FAfterLaunchAppAction:=0;
FAfterEndingAppAction:=0;
for i:=Low(FBeforeLaunchAppSysActions) to High(FBeforeLaunchAppSysActions) do
  SetLength(FBeforeLaunchAppSysActions[i], 0);
SetLength(FBeforeLaunchAppSysActions, 0);
for i:=Low(FAfterEndingAppSysActions) to High(FAfterEndingAppSysActions) do
  SetLength(FAfterEndingAppSysActions[i], 0);
SetLength(FAfterEndingAppSysActions, 0);
for i:=Low(FConfigs) to High(FConfigs) do FreeConfigData(i);
SetLength(FConfigs, 0);
end;


constructor TBinDB.Create;
begin
ZeroData;
end;


destructor TBinDB.Destroy;
begin
ZeroData;
inherited;
end;


procedure TBinDB.AddBeforeLaunchAppSysAction(const ActionStr: WideString);
begin
SetLength(FBeforeLaunchAppSysActions, length(FBeforeLaunchAppSysActions) + 1);
FBeforeLaunchAppSysActions[High(FBeforeLaunchAppSysActions)]:=ActionStr;
end;


procedure TBinDB.AddAfterEndingAppSysAction(const ActionStr: WideString);
begin
SetLength(FAfterEndingAppSysActions, length(FAfterEndingAppSysActions) + 1);
FAfterEndingAppSysActions[High(FAfterEndingAppSysActions)]:=ActionStr;
end;



function TBinDB.InternalAddConfig(const NewConfigName: WideString;
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

FConfigs[h].PlainCfgHash[0]:=pPlainHash^[0];
FConfigs[h].PlainCfgHash[1]:=pPlainHash^[1];
FConfigs[h].PlainCfgHash[2]:=pPlainHash^[2];
FConfigs[h].PlainCfgHash[3]:=pPlainHash^[3];

FConfigs[h].pData:=Pointer(LocalAlloc(LMEM_FIXED, dwSize));
if FConfigs[h].pData <> nil then
  begin
  CopyMemory(FConfigs[h].pData, pData, dwSize);
  result:=BINDB_ERR_SUCCESS;
  end
else
  begin
  SetLength(FConfigs, length(FConfigs) - 1);
  result:=BINDB_ERR_GET_MEM_FOR_CONFIG_DATA_FAILED;
  end;
end;




function TBinDB.AddConfig(const NewConfigName, NewConfigFileName: WideString): DWORD;
var
hConfig: HFILE;
pData: Pointer;
dwSize, dwBytes: DWORD;
PlainHash: T128bit;
begin
result:=BINDB_ERR_SUCCESS;

if length(NewConfigName) > MAX_CONFIG_NAME_LEN then
  begin
  result:=BINDB_ERR_CONFIG_NAME_TOO_LONG;
  Exit;
  end;

if NOT FileExistsW(NewConfigFileName) then
  begin
  result:=BINDB_ERR_CONFIG_FILE_NOT_FOUND;
  Exit;
  end;

hConfig:=CreateFileW(PWideChar(NewConfigFileName), GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
if hConfig = INVALID_HANDLE_VALUE then
  begin
  result:=BINDB_ERR_OPEN_CONFIG_FILE_FAILED;
  Exit;
  end;

dwSize:=GetFileSize(hConfig, nil);
if dwSize = 0 then
  begin
  CloseHandle(hConfig);
  result:=BINDB_ERR_CONFIG_FILE_IS_EMPTY;
  Exit;
  end;

pData:=Pointer(LocalAlloc(LMEM_FIXED, dwSize));
if pData = nil then
  begin
  CloseHandle(hConfig);
  result:=BINDB_ERR_GET_MEM_FOR_READ_CONFIG_FAILED;
  Exit;
  end;

if NOT (ReadFile(hConfig, pData^, dwSize, dwBytes, nil) AND (dwBytes = dwSize))
  then result:=BINDB_ERR_READ_CONFIG_FILE_FAILED;

CloseHandle(hConfig);

if result = BINDB_ERR_SUCCESS then
  begin
  Crypt_Hash128(pData, dwSize, 1, @PlainHash);
  result:=InternalAddConfig(NewConfigName, pData, dwSize, @PlainHash);
  end;
LocalFree(HLOCAL(pData));
end;




function TBinDB.ImportConfigFromBinDB(const pBinDbCfg: PBinDBConfig;
                                      const dwSize: DWORD): DWORD;
var
ConfigName: WideString;
begin
ConfigName:=PWideChar(@pBinDbCfg^.CfgName);
result:=InternalAddConfig(ConfigName, @pBinDbCfg^.Data, pBinDbCfg^.dwDataSize,
                          @pBinDbCfg^.PlainCfgHash);
end;



function TBinDB.CheckData: DWORD;
begin
if FDBFileName = '' then
  begin
  result:=BINDB_ERR_DB_FILENAME_NOT_FOUND;
  Exit;    
  end;
if FProfileName = '' then
  begin
  result:=BINDB_ERR_PROFILE_NAME_NOT_FOUND;
  Exit;
  end;
if FPassword = '' then
  begin
  result:=BINDB_ERR_PASSWORD_NOT_FOUND;
  Exit;
  end;
if FTargetConfig = '' then
  begin
  result:=BINDB_ERR_TARGET_CONFIG_NOT_FOUND;
  Exit;
  end;
result:=BINDB_ERR_SUCCESS;
end;




function TBinDB.AddRecordToDbData(const RecordType: Byte; const pData: Pointer;
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



//function TBinDB.AddBooleanToDbData(const RecordType: Byte; const bValue: Boolean): Boolean;
//var
//bBoolData: Boolean;
//begin
//bBoolData:=bValue;
//result:=AddRecordToDbData(RecordType, @bBoolData, SizeOf(Boolean));
//end;


function TBinDB.AddWideStringToDbData(const RecordType: Byte; const StrW: WideString): Boolean;
begin
result:=length(StrW) = 0;
if result then Exit; // если пустая строка, то ничего не добавляется и возвращается true
result:=AddRecordToDbData(RecordType, PWideChar(StrW), length(StrW) shl 1);
end;


//function TBinDB.AddByteToDbData(const RecordType: Byte; const Value: Byte): Boolean;
//var
//ByteData: Byte;
//begin
//ByteData:=Value;
//result:=AddRecordToDbData(RecordType, @ByteData, SizeOf(Byte));
//end;



function TBinDB.AddConfigToDbData(const nIndex: Integer): Boolean;
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

CopyMemory(@pBinDBCfg^.Data, FConfigs[nIndex].pData, FConfigs[nIndex].dwDataSize);

result:=AddRecordToDbData(R_CONFIG_DATA , pBinDBCfg,
                          SizeOf(pBinDBCfg^) - 1 + FConfigs[nIndex].dwDataSize);

LocalFree(HLOCAL(pBinDBCfg));
end;




function TBinDB.PrepareBinDBData: DWORD;
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
  result:=BINDB_ERR_GET_MEMORY_FOR_DB_DATA_FAILED;
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
CopyMemory(@pProfileData^.TargetConfig, PWideChar(FTargetConfig), length(FTargetConfig) shl 1);
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
      result:=BINDB_ERR_ADD_BEFORE_LAUNCH_APP_ACTION_FAILED;
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
      result:=BINDB_ERR_ADD_AFTER_LAUNCH_APP_ACTION_FAILED;
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
      result:=BINDB_ERR_ADD_CONFIG_FAILED;
      Exit;
      end;
    end;
  end;

result:=BINDB_ERR_SUCCESS;
end;


procedure TBinDB.EncryptBinDBData;
var
pHdr: PBinDBHeader;
SaltStrW: WideString;
begin
pHdr:=PBinDBHeader(FpDBData);

Crypt_GenerateRandom128bit(@pHdr^.RandomBlock[0]);
Crypt_GenerateRandom128bit(@pHdr^.RandomBlock[1]);
Crypt_GenerateRandom128bit(@pHdr^.RandomBlock[2]);
Crypt_GenerateRandom128bit(@pHdr^.RandomBlock[3]);

Crypt_GenerateRandom128bit(@pHdr^.CheckingBlock[0]);
Crypt_Xor128bit(@pHdr^.CheckingBlock[0],
                @CHECKING_BLOCK_CONTROL_VALUE,
                @pHdr^.CheckingBlock[1]);

Crypt_GenerateSalt(@pHdr^.Salt);
SetString(SaltStrW, PWideChar(@pHdr^.Salt), length(pHdr^.Salt));

Crypt_GenerateRandom128bit(@pHdr^.IV);

Crypt_SetKey(FPassword, SaltStrW);

// Шифруются данные, начиная с RandomBlock заголовка.
// B открытом виде остается Salt и IV
Crypt_CryptMemory_CTR(@pHdr^.RandomBlock,
                      FdwDBDataSize - (SizeOf(pHdr^.Salt) + SizeOf(pHdr^.IV)),
                      @pHdr^.IV);
end;



function TBinDB.WriteBinDBData: DWORD;
var
hDB: THandle;
dwBytes: DWORD;
begin
if FileExistsW(FDBFileName) then
  begin
  if NOT EraseFileW(FDBFileName) then
    begin
    result:=BINDB_ERR_DELETE_DB_FILE_FAILED;
    Exit;
    end;
  end;

hDB:=CreateFileW(PWideChar(FDBFileName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
                 FILE_ATTRIBUTE_NORMAL, 0);
if hDB <> INVALID_HANDLE_VALUE then
  begin
  if WriteFile(hDB, FpDBData^, FdwDBDataSize, dwBytes, nil) AND
              (dwBytes = FdwDBDataSize)
    then result:=BINDB_ERR_SUCCESS
    else result:=BINDB_ERR_WRITE_DB_FILE_FAILED;
  CloseHandle(hDB);
  end
else result:=BINDB_ERR_CREATE_DB_FILE_FAILED;
end;



procedure TBinDB.FreeBinDBData;
begin
if (FpDBData = nil) OR (FdwDBDataSize = 0) then Exit;
ZeroMemory(FpDBData, FdwDBDataSize);
LocalFree(HLOCAL(FpDBData));
end;



function TBinDB.Save: DWORD;
begin
result:=CheckData;
if result = BINDB_ERR_SUCCESS then
  begin
  //result:=NewDBData(SizeOf(TBinDBHeader) + SizeOf(TProfileData));
  //if result = BINDB_ERR_SUCCESS then
  //  begin
    result:=PrepareBinDBData;
    if result = BINDB_ERR_SUCCESS then
      begin
      //EncryptBinDBData;
      result:=WriteBinDBData;
      FreeBinDBData;
      end;

   // end;
  end;
end;



function TBinDB.ReadDbFile: DWORD;
var
hDB: HFILE;
dwBytes: DWORD;
begin
hDB:=CreateFileW(PWideChar(FDBFileName), GENERIC_READ, 0, nil, OPEN_EXISTING, 0, 0);
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
        then result:=BINDB_ERR_SUCCESS
        else result:=BINDB_ERR_READ_DB_FILE_FAILED;
      end
    else result:=BINDB_ERR_GET_MEM_FOR_READ_DB_FAILED;
    end
  else result:=BINDB_ERR_DB_FILE_TOO_SMALL;
  CloseHandle(hDB);
  end
else result:=BINDB_ERR_OPEN_DB_FILE_FAILED;
end;


function TBinDB.DecryptBinDBData: DWORD;
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
                      FdwDBDataSize - (SizeOf(pHdr^.Salt) + SizeOf(pHdr^.IV)),
                      @pHdr^.IV);

// Проверка правильности дешифрования
Crypt_Xor128bit(@pHdr^.CheckingBlock[0],
                @pHdr^.CheckingBlock[1],
                @CheckingValue);

if Crypt_CompareMem128(@CheckingValue, @CHECKING_BLOCK_CONTROL_VALUE)
  then result:=BINDB_ERR_SUCCESS
  else result:=BINDB_ERR_DECRYPT_DB_FAILED;
end;



function TBinDB.CheckBinDBDataVersion: DWORD;
begin
if PBinDBHeader(FpDBData)^.Sign = CFG_MGR_DB_SIGN  then
  begin
  if PBinDBHeader(FpDBData)^.wBinDbVersion = CFG_MGR_DB_VESRION
    then result:=BINDB_ERR_SUCCESS
    else result:=BINDB_ERR_UNSUPPORTED_VERSION;
  end
else result:=BINDB_ERR_INVALID_DATA_SIGN;
end;


procedure TBinDB.ProceedRecord(const RecordType: Byte; const pData: Pointer; const dwSize: DWORD);
var
sw: WideString;
begin
if (pData = nil) OR (dwSize = 0) then Exit;

case RecordType of
  R_CONFIG_DATA                 : ImportConfigFromBinDB(PBinDBConfig(pData), dwSize);
  R_PROFILE_DATA                : begin
                                  SetString(FProfileName, PWideChar(@PBinDBProfileData(pData)^.ProfileName),
                                            length(PWideChar(@PBinDBProfileData(pData)^.ProfileName)));
                                  SetString(FTargetConfig, PWideChar(@PBinDBProfileData(pData)^.TargetConfig),
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

procedure TBinDB.ParseBinDBData;
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




function TBinDB.Load(const FileName, Password: WideString): DWORD;
begin
if NOT FileExistsW(FileName) then
  begin
  result:=BINDB_ERR_DB_FILE_NOT_FOUND;
  Exit;
  end;

ZeroData;

FDBFileName:=FileName;
FPassword:=Password;

result:=ReadDbFile;
if (result = BINDB_ERR_SUCCESS) AND (FpDBData <> nil) then
  begin
  if CheckBinDBDataVersion = BINDB_ERR_SUCCESS then
    begin
    //result:=DecryptBinDBData;
    //if result = BINDB_ERR_SUCCESS then
    //  begin
      ParseBinDBData;
      result:=BINDB_ERR_SUCCESS;
    //  end;
    end;
  LocalFree(HLOCAL(FpDBData));
  end;
end;


end.
