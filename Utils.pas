unit Utils;

interface

uses Windows, SysUtils, CommDlg, ShellAPI, ShlObj, ActiveX, Crypt;



type
  TWideStringArray = Array of WideString;



procedure ZeroWideString(var Value: WideString);

procedure ZeroWideStringArray(var Arr: TWideStringArray);

procedure ShowModalError(const hParent: HWND; const ErrStr: WideString);
procedure ShowError(const ErrStr: WideString);
function GetSysErrorText(const dwErrCode: DWORD): WideString;

function GetFileNameW(const bOpenDialog: Boolean; const hParent: HWND;
                      var FileName: WideString; const Title, Filter, DefExtension,
                      InitialDirectory: WideString; FilterIndex: Byte): Boolean;

function SelectDir(const hParent: HWND; const Title: WideString; var Dir: WideString): Boolean;


function FileExistsW(const FileName: WideString): Boolean;
function DirectoryExistsW(const DirName: WideString): Boolean;
function ExtractFilePathW(const FilePath: WideString): WideString;
function ExtractFileExtW(const FilePath: WideString): WideString;

function EraseFileW(const FileName: WideString): Boolean;

procedure ClearDirectoryW(const Directory: WideString);
function RegClearKeyW(const KeyValueName: WideString): Boolean;
function RegEraseKeyW(const KeyValueName: WideString): Boolean;
function RegEraseValueW(const KeyValueName: WideString): Boolean;

function IniSetStrW(const FileName, Section, Key, Value: WideString): Boolean;
function IniGetStrW(const FileName, Section, Key, DefaultValue: WideString): WideString;
function IniSetInt(const FileName, Section, Key: WideString; const Value: Integer): Boolean;
function IniGetInt(const FileName, Section, Key: WideString; const DefaultValue: Integer): Integer;
function IniGetBool(const FileName, Section, Key: WideString): Boolean;
function IniSetBool(const FileName, Section, Key: WideString; const bValue: Boolean): Boolean;
function IniSectionExists(const FileName, Section: WideString): Boolean;
function IniDeleteSection(const FileName, Section: WideString): Boolean;
function IniSet128bit(const FileName, Section, Key: WideString; const pValue: P128bit): Boolean;
function IniGet128bit(const FileName, Section, Key: WideString; const pValue: P128bit): Boolean;
function IniDeleteValueW(const FileName, Section, Key: WideString): Boolean;

function StrWToHexW(const Str: WideString): WideString;
function StrAToHexA(const Str: AnsiString): AnsiString;
function HexStrAToStrA(const HexStr: AnsiString): AnsiString;
function HexStrWToStrW(const HexStr: WideString): WideString;
function HexToInt(Value:String): Integer;

function ExpandPathW(const Path: WideString): WideString;

function StringReplaceW(const SrcStr, OldPattern, NewPattern: WideString): WideString;

function GetSelfDir: WideString;

function NormalizeDirName(const DirName: WideString): WideString;

function StartProcess(const CmdLine: WideString; const wShow: WORD;
                      const dwWaitTime: DWORD; const lphProcess: PHandle): Boolean;


type

{$IFDEF CPUX64}
  NativeInt  = Int64;
  NativeUInt = UInt64;
{$ELSE}
  NativeInt  = Integer;
  NativeUInt = LongWord;
{$ENDIF}

var
  SelfDir: WideString;
  hMainForm: HWND = 0;
  MainFormActionProc: procedure (const dwAction: DWORD);

  LockSpeedButtons: Boolean;


{$I dbg.inc}


implementation

uses ProfileClass;


const
  KEY_WOW64_64KEY = $0100;


procedure ZeroWideString(var Value: WideString);
begin
if length(Value) > 0 then
  begin
  ZeroMemory(PWideChar(Value), length(Value) shl 1);
  SetLength(Value, 0);
  end;
end;



procedure ZeroWideStringArray(var Arr: TWideStringArray);
var
i: Integer;
begin
if length(Arr) > 0 then
  begin
  for i:=Low(Arr) to High(Arr) do ZeroWideString(Arr[i]);
  SetLength(Arr, 0);
  end;
end;



function GetSysErrorText(const dwErrCode: DWORD): WideString;
var
Buf: Array[0..512] of WideChar;
dwLen: DWORD;
begin
result:='';
ZeroMemory(@Buf, SizeOf(Buf));
if dwErrCode <> ERROR_SUCCESS then
  begin
  dwLen:=FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM OR FORMAT_MESSAGE_ARGUMENT_ARRAY,
                        nil, dwErrCode, 0, @Buf,
                        length(Buf), nil);
  if dwLen <> 0 then SetString(result, PWideChar(@Buf), dwLen);
  result:='0x' + LowerCase(IntToHex(dwErrCode, 8)) + ': ' + result;
  end;
end;


procedure ShowModalError(const hParent: HWND; const ErrStr: WideString);
var
dwFlags: DWORD;
begin
if hParent = 0 then dwFlags:=MB_OK OR MB_ICONERROR OR MB_SETFOREGROUND OR MB_SYSTEMMODAL
               else dwFlags:=MB_OK OR MB_ICONERROR OR MB_SETFOREGROUND;
MessageBoxW(hParent, PWideChar(ErrStr), 'Error', dwFlags);
end;


procedure ShowError(const ErrStr: WideString);
begin
ShowModalError(hMainForm, PWideChar(ErrStr));
end;



function IniDeleteValueW(const FileName, Section, Key: WideString): Boolean;
begin
result:=WritePrivateProfileStringW(PWideChar(Section), PWideChar(Key),
                                   nil, PWideChar(FileName));
end;


function IniSetStrW(const FileName, Section, Key, Value: WideString): Boolean;
begin
result:=WritePrivateProfileStringW(PWideChar(Section), PWideChar(Key),
                                   PWideChar(Value), PWideChar(FileName));
end;


function IniGetStrW(const FileName, Section, Key, DefaultValue: WideString): WideString;
const
  READ_BUFFER_SIZE = 10240;
var
pBuf: Pointer;
dwLen: DWORD;
begin
GetMem(pBuf, READ_BUFFER_SIZE);
try
  dwLen:=GetPrivateProfileStringW(PWideChar(Section), PWideChar(Key),
                                  PWideChar(DefaultValue), pBuf, READ_BUFFER_SIZE,
                                  PWideChar(FileName));
  SetString(result, PWideChar(pBuf), dwLen);
finally
  FreeMem(pBuf, READ_BUFFER_SIZE);
  end;
end;


function IniSetBool(const FileName, Section, Key: WideString; const bValue: Boolean): Boolean;
var
StrVal: WideString;
begin
if bValue then StrVal:='1' else StrVal:='0';
result:=WritePrivateProfileStringW(PWideChar(Section), PWideChar(Key),
                                   PWideChar(StrVal), PWideChar(FileName));
end;


function IniSetInt(const FileName, Section, Key: WideString; const Value: Integer): Boolean;
var
StrVal: WideString;
begin
StrVal:=IntToStr(Value);
result:=WritePrivateProfileStringW(PWideChar(Section), PWideChar(Key),
                                   PWideChar(StrVal), PWideChar(FileName));
end;


function IniGetInt(const FileName, Section, Key: WideString;
                   const DefaultValue: Integer): Integer;
begin
result:=GetPrivateProfileIntW(PWideChar(Section), PWideChar(Key), DefaultValue, PWideChar(FileName));
end;


function IniGetBool(const FileName, Section, Key: WideString): Boolean;
begin
result:=IniGetInt(FileName, Section, Key, 0) <> 0;
end;


function IniSectionExists(const FileName, Section: WideString): Boolean;
var
SectionA, Line: string;
f: TextFile;
begin
result:=false;
if NOT FileExistsW(FileName) then Exit;
SectionA:='[' + Section + ']';
AssignFile(f, FileName);
try
  Reset(f);
  while NOT EOF(f) do
    begin
    ReadLn(f, Line);
    result:=Line = SectionA;
    if result then Break;
    end;
finally
  CloseFile(f);
  end;
end;


function IniDeleteSection(const FileName, Section: WideString): Boolean;
begin
result:=WritePrivateProfileStringW(PWideChar(Section), nil, nil, PWideChar(FileName));
end;


function IniSet128bit(const FileName, Section, Key: WideString; const pValue: P128bit): Boolean;
var
StrVal: WideString;
begin
StrVal:=LowerCase(IntToHex(pValue[0], 8) + IntToHex(pValue[1], 8) +
                  IntToHex(pValue[2], 8) + IntToHex(pValue[3], 8));
result:=IniSetStrW(FileName, Section, Key, StrVal);
end;


function IniGet128bit(const FileName, Section, Key: WideString; const pValue: P128bit): Boolean;
var
HexStr: WideString;
begin
HexStr:=IniGetStrW(FileName, Section, Key, '');
result:=length(HexStr) = 32;
if NOT result then Exit;
pValue^[0]:=HexToInt(copy(HexStr, 1, 8));
pValue^[1]:=HexToInt(copy(HexStr, 9, 8));
pValue^[2]:=HexToInt(copy(HexStr, 17, 8));
pValue^[3]:=HexToInt(copy(HexStr, 25, 8));
end;



function FileExistsW(const FileName: WideString): Boolean;
begin
result:=GetFileAttributesW(PWideChar(FileName)) <> DWORD(-1);
end;


function DirectoryExistsW(const DirName: WideString): Boolean;
var
dwAttrs: DWORD;
begin
dwAttrs:=GetFileAttributesW(PWideChar(DirName));
result:=(dwAttrs <> DWORD(-1)) AND
        ((dwAttrs AND FILE_ATTRIBUTE_DIRECTORY) <> 0);
end;



function ExtractFilePathW(const FilePath: WideString): WideString;
var
i: Integer;
begin
i:=length(FilePath);
if i > 0 then
  begin
  while (FilePath[i] <> '\') AND (FilePath[i] <> ':') AND (i > 1) do dec(i);
  if (i > 1) then result:=copy(FilePath, 1, i) else result:='';
  end
else result:='';
end;



function ExtractFileExtW(const FilePath: WideString): WideString;
var
i, Len: Integer;
begin
Len:=length(FilePath);
if Len > 0 then
  begin
  i:=Len;
  while (FilePath[i] <> '.') AND (i > 1) do dec(i);
  if (i > 1) AND (i < Len) then result:=copy(FilePath, i + 1, Len - i) else result:='';
  end
else result:='';
end;




function GetFileNameW(const bOpenDialog: Boolean; const hParent: HWND;
                      var FileName: WideString; const Title, Filter, DefExtension,
                      InitialDirectory: WideString; FilterIndex: Byte): Boolean;
var
NameBuf: Array[0..MAX_PATH] of WideChar;
ofn: TOpenFileNameW;
begin
ZeroMemory(@ofn, SizeOf(ofn));
ZeroMemory(@NameBuf, SizeOf(NameBuf));
ofn.lStructSize:=SizeOf(ofn);
ofn.hWndOwner:=hParent;
ofn.hInstance:=hInstance;
ofn.nMaxFile:=MAX_PATH;
ofn.lpstrFilter:=PWideChar(Filter);
ofn.nFilterIndex:=FilterIndex + 1;
ofn.lpstrDefExt:=PWideChar(DefExtension);
ofn.lpstrTitle:=PWideChar(Title);
ofn.lpstrInitialDir:=PWideChar(InitialDirectory);
if bOpenDialog then
  ofn.Flags:=OFN_EXPLORER OR OFN_LONGNAMES else // OR OFN_FILEMUSTEXIST else
  ofn.Flags:=OFN_EXPLORER OR OFN_LONGNAMES OR OFN_OVERWRITEPROMPT OR OFN_HIDEREADONLY;
ofn.lpstrFile:=@NameBuf;
if length(FileName) > 0 then CopyMemory(@NameBuf, PWideChar(FileName), length(FileName) shl 1);
if bOpenDialog then result:=GetOpenFileNameW(ofn) else result:=GetSaveFileNameW(ofn);
if result then FileName:=PWideChar(@NameBuf);
end;




function SelectDir(const hParent: HWND; const Title: WideString; var Dir: WideString): Boolean;
const
BIF_USENEWUI = 28;
BIF_NOCREATEDIRS = $0200;
var
BrowseInfo: TBrowseInfoW;
lpItemID: PItemIDList;
Buf: Array[0..MAX_PATH - 1] of WideChar;
begin
CoInitialize(nil);
ZeroMemory(@BrowseInfo, SizeOf(TBrowseInfo));
ZeroMemory(@Buf[0], SizeOf(Buf));
BrowseInfo.hwndOwner:=hParent;
BrowseInfo.lpszTitle:=PWideChar(#13#10 + Title);
BrowseInfo.ulFlags:=BIF_USENEWUI OR BIF_NOCREATEDIRS OR BIF_RETURNONLYFSDIRS;
lpItemID:=SHBrowseForFolderW(BrowseInfo);
if lpItemId <> nil then
  begin
  result:=SHGetPathFromIDListW(lpItemID, @Buf[0]);
  GlobalFreePtr(lpItemID);
  SetString(Dir, PWideChar(@Buf), lstrlenW(Buf));
  if (length(Dir) > 0) AND (Dir[length(Dir)] <> '\') then Dir:=Dir + '\';
  end
else result:=false;
end;






function EraseFileW(const FileName: WideString): Boolean;
var
hTargetFile: HFILE;
dwSize: DWORD;
hMapping: THandle;
pData: Pointer;
NewFileName: WideString;
begin
result:=false;

if NOT FileExistsW(FileName) then Exit;

hTargetFile:=CreateFileW(PWideChar(FileName), GENERIC_ALL, 0, nil, OPEN_EXISTING, 0, 0);
if hTargetFile <> INVALID_HANDLE_VALUE then
  begin
  dwSize:=GetFileSize(hTargetFile, nil);
  hMapping:=CreateFileMappingW(hTargetFile, nil, PAGE_READWRITE, 0, 0, nil);
  if hMapping <> 0 then
    begin
    pData:=MapViewOfFile(hMapping, FILE_MAP_WRITE, 0, 0, 0);
    if pData <> nil then
      begin
      result:=true;
      Crypt_GenRandom(pData, dwSize);
      ZeroMemory(pData, dwSize);
      UnmapViewOfFile(pData);
      end;
    CloseHandle(hMapping);
    end;
  CloseHandle(hTargetFile);
  end;

NewFileName:=ExtractFilePathW(FileName);
while length(NewFileName) <= length(Filename) do
  NewFileName:=NewFileName + Crypt_GenerateRndStrW(10);

if MoveFileW(PWideChar(FileName), PWideChar(NewFileName))
  then DeleteFileW(PWideChar(NewFileName))
  else DeleteFileW(PWideChar(FileName));
end;



procedure _ClearDirectoryW(const Directory: WideString; const bTopLevel: Boolean);
var
FindData: WIN32_FIND_DATAW;
hFind: THandle;
bRes: Boolean;
begin
hFind:=Windows.FindFirstFileW(PWideChar(Directory + '\*.*'), FindData);
bRes:=hFind <> INVALID_HANDLE_VALUE;
if NOT bRes then Exit;
while bRes do
  begin
  if FindData.dwFileAttributes AND FILE_ATTRIBUTE_DIRECTORY <> 0 then
    begin
    if FindData.cFileName[0] <> '.'
      then _ClearDirectoryW(Directory + '\' +  PWideChar(@FindData.cFileName), false);
    end
  else EraseFileW(Directory + '\' +  PWideChar(@FindData.cFileName));
  bRes:=Windows.FindNextFileW(hFind, FindData);
  end;
Windows.FindClose(hFind);
if NOT bTopLevel then RemoveDirectoryW(PWideChar(Directory));
end;


procedure ClearDirectoryW(const Directory: WideString);
begin
_ClearDirectoryW(Directory, true);
end;


function RegStrToRootKey(var RegStr: WideString): HKEY;
var
RegStrLower: WideString;
begin
RegStrLower:=LowerCase(RegStr);
if pos(HKCU_SHORT_STR, RegStrLower) = 1 then
  begin
  delete(RegStr, 1, 5);
  result:=HKEY_CURRENT_USER;
  end
else if pos(HKLM_SHORT_STR, RegStrLower) = 1 then
  begin
  delete(RegStr, 1, 5);
  result:=HKEY_LOCAL_MACHINE;
  end
else if pos(HKCR_SHORT_STR, RegStrLower) = 1 then
  begin
  delete(RegStr, 1, 5);
  result:=HKEY_CLASSES_ROOT;
  end
else if pos(HKCU_LONG_STR, RegStrLower) = 1 then
  begin
  delete(RegStr, 1, 18);
  result:=HKEY_CURRENT_USER;
  end
else if pos(HKLM_LONG_STR, RegStrLower) = 1 then
  begin
  delete(RegStr, 1, 19);
  result:=HKEY_LOCAL_MACHINE;
  end
else if pos(HKCR_LONG_STR, RegStrLower) = 1 then
  begin
  delete(RegStr, 1, 18);
  result:=HKEY_CLASSES_ROOT;
  end
else result:=0;
end;



function RegStrToRootKeySubKeyValue(const KeyValueName: WideString;
                                    var SubKey, ValueName: WideString): HKEY;
var
_KeyValueName: WideString;
i: Integer;
begin
_KeyValueName:=KeyValueName;
result:=RegStrToRootKey(_KeyValueName);
if result <> 0 then
  begin
  i:=length(_KeyValueName);
  while (i > 2) AND (_KeyValueName[i] <> '\') do dec(i);
  if _KeyValueName[i] = '\' then
    begin
    SubKey:=copy(_KeyValueName, 1, i - 1);
    ValueName:=copy(_KeyValueName, i + 1, length(_KeyValueName) - i);
    end
  else result:=0;
  end;
end;


function _RegEraseValueW(const hParentKey: HKEY; const _ValueName: WideString): Boolean;
var
dwType, dwSize: DWORD;
pData: Pointer;
begin
result:=false;
dwSize:=0;
if RegQueryValueExW(hParentKey, PWideChar(_ValueName), nil, @dwType, nil, @dwSize) = ERROR_SUCCESS then
  begin
  if dwSize > 2 then
    begin
    pData:=Pointer(LocalAlloc(LMEM_FIXED OR LMEM_ZEROINIT, dwSize));
    if pData <> nil then
      begin
      RegSetValueExW(hParentKey, PWideChar(_ValueName), 0, dwType, pData, dwSize);
      LocalFree(HLOCAL(pData));
      end;
    end;
  result:=RegDeleteValueW(hParentKey, PWideChar(_ValueName)) = ERROR_SUCCESS;
  end;
end;



function RegEraseValueW(const KeyValueName: WideString): Boolean;
var
SubKey, ValueName: WideString;
hRootKey, hRegKey: HKEY;
begin
result:=false;
hRootKey:=RegStrToRootKeySubKeyValue(KeyValueName, SubKey, ValueName);
if hRootKey <> 0 then
  begin
  if RegOpenKeyExW(hRootKey, PWideChar(SubKey), REG_OPTION_NON_VOLATILE,
                   KEY_ALL_ACCESS OR KEY_WOW64_64KEY OR KEY_ENUMERATE_SUB_KEYS , hRegKey) = ERROR_SUCCESS then
    begin
    result:=_RegEraseValueW(hRegKey, ValueName);
    regCloseKey(hRegKey);
    end;
  end;
end;



function _RegClearKeyW(const hRootKey: HKEY; const SubKey: WideString;
                       const bTopLevel: Boolean): Boolean;
var
hRegKey: HKEY;
ObjName: Array[0..255] of WideChar;
dwObjNameLen, dwType, dwIndex: DWORD;
ValueName, KeyName: WideString;
begin
result:=false;

if RegOpenKeyExW(hRootKey, PWideChar(SubKey), REG_OPTION_NON_VOLATILE,
                 KEY_ALL_ACCESS OR KEY_WOW64_64KEY OR KEY_ENUMERATE_SUB_KEYS , hRegKey) = ERROR_SUCCESS then
  begin
  dwIndex:=0;
  dwObjNameLen:=length(ObjName);
  while RegEnumValueW(hRegKey, dwIndex, @ObjName, dwObjNameLen, nil, @dwType, nil, nil) = ERROR_SUCCESS do
    begin
    SetString(ValueName, PWideChar(@ObjName), dwObjNameLen);
    if NOT _RegEraseValueW(hRegKey, ValueName) then inc(dwIndex);
    dwObjNameLen:=length(ObjName);
    end;

  dwIndex:=0;
  dwObjNameLen:=length(ObjName);
  while RegEnumKeyW(hRegKey, dwIndex, @ObjName, length(ObjName)) = ERROR_SUCCESS do
    begin
    SetString(KeyName, PWideChar(@ObjName), dwObjNameLen);
    if NOT _RegClearKeyW(hRegKey, KeyName, false) then inc(dwIndex);
    dwObjNameLen:=length(ObjName);
    end;

  if (NOT bTopLevel) then result:=RegDeleteKeyW(hRootKey, PWideChar(SubKey)) = ERROR_SUCCESS
                     else result:=true;
  RegCloseKey(hRegKey);
  end;
end;




function _RegClearOrEraseKeyW(const KeyValueName: WideString; const bClear: Boolean): Boolean;
var
_KeyValueName: WideString;
hRootKey: HKEY;
begin
result:=false;
_KeyValueName:=KeyValueName;
hRootKey:=RegStrToRootKey(_KeyValueName);
if hRootKey <> 0 then result:=_RegClearKeyW(hRootKey, _KeyValueName, bClear);
end;



function RegClearKeyW(const KeyValueName: WideString): Boolean;
begin
result:=_RegClearOrEraseKeyW(KeyValueName, true);
end;


function RegEraseKeyW(const KeyValueName: WideString): Boolean;
begin
result:=_RegClearOrEraseKeyW(KeyValueName, false);
end;



function StrAToHexAWithXOR(const Str: AnsiString; const OptionalXorByte: Byte): AnsiString;
const
HEX_ORDS: Array[0..$F] of Byte =
  ($30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $61, $62, $63, $64, $65, $66);
var
i, Len: Integer;
b: Byte;
pOut: PWORD;
begin
Len:=length(Str) shl 1;
SetLength(result, Len);
if length(Str) = 0 then Exit;
pOut:=PWORD(result);
Len:=Len shr 1;
for i:=1 to Len do
  begin
  b:=ord(Str[i]) XOR OptionalXorByte;
  pOut^:=(HEX_ORDS[(b shr 4) and $F]) OR (HEX_ORDS[b and $F] shl 8);
  inc(pOut);
  end;
end;



function StrWToHexW(const Str: WideString): WideString;
var
Tmp: AnsiString;
begin
SetString(Tmp, PAnsiChar(Str), length(Str) shl 1);
if length(Str) = 0 then Exit;
result:=StrAToHexAWithXor(Tmp, 0);
end;



function StrAToHexA(const Str: AnsiString): AnsiString;
begin
result:=StrAToHexAWithXor(Str, 0);
end;


function HexWordAToByte(const wHex: WORD): Byte;
var
b: Byte;
begin
result:=0;
b:=HiByte(wHex);
     if (b > $2F) AND (b < $3A) then result:=result OR (b - $30)
else if (b > $40) AND (b < $5B) then result:=result OR (b - $37)
else result:=result OR (b - $57);
b:=LoByte(wHex);
     if (b > $2F) AND (b < $3A) then result:=result OR ((b - $30) shl 4)
else if (b > $40) AND (b < $5B) then result:=result OR ((b - $37) shl 4)
else result:=result OR ((b - $57) shl 4);
end;


function HexStrAToStrAWithXOR(const HexStr: AnsiString; const OptionalXorByte: Byte): AnsiString;
var
i, Len: Integer;    
pwIn: PWORD;
pbOut: PByte;
begin     
Len:=length(HexStr) shr 1;
SetLength(result, Len);
if Len = 0 then Exit;
pbOut:=PByte(result);
pwIn:=PWORD(HexStr);
for i:=1 to Len do
  begin
  pbOut^:=HexWordAToByte(pwIn^) XOR OptionalXorByte;
  inc(pwIn);
  inc(pbOut);
  end;
end;


function HexStrAToStrA(const HexStr: AnsiString): AnsiString;
begin
result:=HexStrAToStrAWithXOR(HexStr, 0);
end;


function HexStrWToStrWWithXOR(const HexStr: WideString; const OptionalXorByte: Byte): WideString;
begin
result:=HexStrAToStrAWithXOR(HexStr, OptionalXorByte);
end;


function HexStrWToStrW(const HexStr: WideString): WideString;
var
StrA: AnsiString;
begin
StrA:=HexStrAToStrAWithXOR(HexStr, 0);
if length(StrA) > 1 then SetString(result, PWideChar(@Stra[1]), length(StrA) shr 1)
                    else result:='';
end;


function HexToInt(Value:String): Integer;
var
 I : Integer;
begin
  Result := 0;
  i := 1;
  if Value = '' then Exit;
  if Value[1] = '$' then Inc(I);
  while i <= Length( Value ) do
  begin
    if Value[i] in ['0'..'9'] then
     Result := (Result shl 4) or (Ord(Value[I]) - Ord('0'))
    else
     if Value[i] in ['A'..'F'] then
      Result := (Result shl 4) or (Ord(Value[I]) - Ord('A') + 10)
     else
      if Value[i] in ['a'..'f'] then
       Result := (Result shl 4) or (Ord(Value[I]) - Ord('a') + 10)
      else
       Break;
    Inc(i);
  end;
end;



function ExpandPathW(const Path: WideString): WideString;
var
  Str: Array[0..511] of WideChar;
  dwLen: DWORD;
begin
result:='';
ZeroMemory(@Str, SizeOf(Str));
dwLen:=ExpandEnvironmentStringsW(PWideChar(Path), PWideChar(@Str), length(Str));
SetString(result, PWideChar(@Str), dwLen - 1);
end;


function StringReplaceW(const SrcStr, OldPattern, NewPattern: WideString): WideString;
var
i: Integer;
begin
result:=SrcStr;
if (length(result) = 0) OR (length(OldPattern) = 0) OR
   (length(result) < length(OldPattern)) then Exit;

i:=pos(OldPattern, result);
while i > 0 do
  begin
  result:=copy(result, 1, i - 1) +
          NewPattern +
          copy(result, i + length(OldPattern), length(result) - (i + length(OldPattern)) + 1);
  i:=pos(OldPattern, result);
  end;
end;


function GetSelfDir: WideString;
var
Buf: Array[0..MAX_PATH] of WideChar;
dwLen: DWORD;
begin
dwLen:=GetModuleFileNameW(hInstance, @Buf, MAX_PATH);
SetString(result, PWideChar(@Buf), dwLen);
result:=ExtractFilePathW(result);
end;



function NormalizeDirName(const DirName: WideString): WideString;
begin
if (length(DirName) <> 0) AND (DirName[length(DirName)] <> '\')
  then result:=DirName + '\'
  else result:=DirName;
end;


function StartProcess(const CmdLine: WideString; const wShow: WORD;
                      const dwWaitTime: DWORD; const lphProcess: PHandle): Boolean;
var
si: TStartupInfo;
pi: PROCESS_INFORMATION;
_CmdLine: WideString;
begin
ZeroMemory(@pi, sizeof(pi));
ZeroMemory(@si, sizeof(si));
si.wShowWindow:=wShow;
si.dwFlags:=STARTF_USESHOWWINDOW;
si.cb:=SizeOf(si);
_CmdLine:=CmdLine;
//UniqueString(_CmdLine);
result:=CreateProcessW(nil, PWideChar(_CmdLine), nil, nil, false, 0, nil, WChar(92), si, pi);
if result then
  begin
  if dwWaitTime <> 0 then WaitForSingleObject(pi.hProcess, dwWaitTime);
  if pi.hThread <> 0 then CloseHandle(pi.hThread);
  if pi.hProcess <> 0 then
    begin
    if lphProcess <> nil then lphProcess^:=pi.hProcess else CloseHandle(pi.hProcess);
    end;
  end;
end;




end.
