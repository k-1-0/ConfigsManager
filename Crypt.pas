unit Crypt;

interface

uses Windows, SysUtils;


const

  PASSWORD_EXPAND_ITERATIONS = 500000;   // 500k - 5 per sec; 300k - 8 per sec;

  HARDCODED_SALT             = 'TWXRzlkgNjxNnHJ';

  SALT_SIZE                  = 12;

  CRYPT_ERR_SUCCESS                                     = 0;
  CRYPT_ERR_UNKNOWN                                     = 1;
  CRYPT_ERR_FILE_NOT_FOUND                              = 2;
  CRYPT_ERR_DELETE_OUTPUT_FILE_FAILED                   = 3;
  CRYPT_ERR_OPEN_INPUT_FILE_FAILED                      = 4;
  CRYPT_ERR_CREATE_OUTPUT_FILE_FAILED                   = 5;
  CRYPT_ERR_INPUT_FILE_IS_EMPTY                         = 6;
  CRYPT_ERR_READ_FILE_FAILED                            = 7;
  CRYPT_ERR_WRITE_FILE_FAILED                           = 8;
  CRYPT_ERR_FILE_MAPPING_FAILED                         = 9;
  CRYPT_ERR_FILE_MAP_VIEW_FAILED                        = 10;

type

  TByteArray = Array [0..0] of Byte;
  PByteArray = ^TByteArray;

  T128bit = packed Array[0..3] of DWORD; // 128 bits
  P128bit = ^T128bit;

  TSaltData = Array[0..SALT_SIZE - 1] of WideChar;
  PSaltData = ^TSaltData;

function Crypt_ErrToStr(const dwErrorCode: DWORD): string;

procedure Crypt_GenRandom(const pData: Pointer; const dwSize: DWORD);

procedure Crypt_GenerateRandom128bit(const pValue: P128bit);

procedure Crypt_GenerateSalt(const pSalt: PSaltData);

function Crypt_CompareMem128(const pMem1, pMem2: P128Bit): Boolean;

procedure Crypt_Xor128bit(const pValue0, pValue1, pResult: P128bit);

procedure Crypt_Copy128bit(const pDest, pSrc: P128bit);

procedure Crypt_SetKey(const Password, Salt: WideString);

procedure Crypt_CryptMemory_CTR(const pData: Pointer; const dwSize: DWORD;
                                const pIV: P128bit);

procedure Crypt_Hash128(const pData: Pointer;
                        const dwSize, dwIterationsCount: LongWord;
                        const pHash: P128bit);

function Crypt_GenerateRndStrW(const Len: Integer): WideString;

implementation

uses Tiger, RC6;



function Crypt_ErrToStr(const dwErrorCode: DWORD): string;
begin
case dwErrorCode of
  CRYPT_ERR_SUCCESS                   : result:='CRYPT_ERR_SUCCESS';
  CRYPT_ERR_UNKNOWN                   : result:='CRYPT_ERR_UNKNOWN';
  CRYPT_ERR_FILE_NOT_FOUND            : result:='CRYPT_ERR_FILE_NOT_FOUND';
  CRYPT_ERR_DELETE_OUTPUT_FILE_FAILED : result:='CRYPT_ERR_DELETE_OUTPUT_FILE_FAILED';
  CRYPT_ERR_OPEN_INPUT_FILE_FAILED    : result:='CRYPT_ERR_OPEN_INPUT_FILE_FAILED';
  CRYPT_ERR_CREATE_OUTPUT_FILE_FAILED : result:='CRYPT_ERR_CREATE_OUTPUT_FILE_FAILED';
  CRYPT_ERR_INPUT_FILE_IS_EMPTY       : result:='CRYPT_ERR_INPUT_FILE_IS_EMPTY';
  CRYPT_ERR_READ_FILE_FAILED          : result:='CRYPT_ERR_READ_FILE_FAILED';
  CRYPT_ERR_WRITE_FILE_FAILED         : result:='CRYPT_ERR_WRITE_FILE_FAILED';
  CRYPT_ERR_FILE_MAPPING_FAILED       : result:='CRYPT_ERR_FILE_MAPPING_FAILED';
  CRYPT_ERR_FILE_MAP_VIEW_FAILED      : result:='CRYPT_ERR_FILE_MAP_VIEW_FAILED';
  else                                  result:='# ' + IntToStr(dwErrorCode);
  end;
end;



function RtlGenRandom(RandomBuffer: PBYTE;
                      RandomBufferLength: ULONG): Boolean; stdcall; external advapi32 name 'SystemFunction036';


procedure Crypt_GenRandom(const pData: Pointer; const dwSize: DWORD);
begin
RtlGenRandom(pData, dwSize);
end;


procedure Crypt_GenerateRandom128bit(const pValue: P128bit);
begin
RtlGenRandom(Pointer(pValue), SizeOf(pValue^));
Hash_128(pValue, SizeOf(pValue^), 1, pValue);
end;


procedure Crypt_Xor128bit(const pValue0, pValue1, pResult: P128bit);
begin
pResult^[0]:=pValue0^[0] XOR pValue1^[0];
pResult^[1]:=pValue0^[1] XOR pValue1^[1];
pResult^[2]:=pValue0^[2] XOR pValue1^[2];
pResult^[3]:=pValue0^[3] XOR pValue1^[3];
end;

procedure Crypt_Copy128bit(const pDest, pSrc: P128bit);
begin
pDest^[0]:=pSrc^[0];
pDest^[1]:=pSrc^[1];
pDest^[2]:=pSrc^[2];
pDest^[3]:=pSrc^[3];
end;


procedure Crypt_GenerateSalt(const pSalt: PSaltData);
const
  CHARSET: Array[0..86] of WideChar =
    ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
     'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
     '1','2','3','4','5','6','7','8','9','0',
     '_',')','(','*','&','^','%','$','#','@','!','~','?','>','<',',','.','/','[',']','{','}',';','"',':');
var
i, j: DWORD;
begin
i:=0;
while i < SALT_SIZE do
  begin
  RtlGenRandom(@j, SizeOf(j));
  j:=j AND $000000FF;
  if j <= High(CHARSET) then
    begin
    pSalt^[i]:=CHARSET[j];
    inc(i);
    end;
  end;
end;


function Crypt_CompareMem128(const pMem1, pMem2: P128Bit): Boolean;
begin
result:=(PDWORD(pMem1)^ = PDWORD(pMem2)^) AND
        (PDWORD(Cardinal(pMem1) +  4)^ = PDWORD(Cardinal(pMem2) +  4)^) AND
        (PDWORD(Cardinal(pMem1) +  8)^ = PDWORD(Cardinal(pMem2) +  8)^) AND
        (PDWORD(Cardinal(pMem1) + 12)^ = PDWORD(Cardinal(pMem2) + 12)^);
end;



procedure Crypt_SetKey(const Password, Salt: WideString);
var
_Password: WideString;
Hash: T128bit;
len: Integer;
begin
_Password:=Password + Salt + HARDCODED_SALT;
len:=length(_Password);
while len < 128 do
  begin
  _Password:=_Password + IntToStr(len) + WChar(len) + _Password;
  len:=length(_Password);
  end;

Hash_128(PWideChar(_Password), length(_Password) shl 1, PASSWORD_EXPAND_ITERATIONS, @Hash);

RC6_Init(@Hash);
end;


procedure Crypt_CryptMemory_CTR(const pData: Pointer; const dwSize: DWORD;
                                const pIV: P128bit);
const
  BLOCK_SIZE = 16;
var
pBlock: PByte;
dwInSize, i: DWORD;
Counter: T128bit;
begin
if (pData = nil) OR (dwSize = 0) then Exit;

Counter[0]:=pIV^[0];
Counter[1]:=pIV^[1];
Counter[2]:=pIV^[2];
Counter[3]:=pIV^[3];

pBlock:=pData;
dwInSize:=dwSize;
i:=0;
while dwInSize > 0 do
  begin
  if i mod BLOCK_SIZE = 0 then // generating new gamma block, every 128 bits input data
    begin
    Hash_128(@Counter, SizeOf(Counter), 1, @Counter);
    RC6_EncryptBlock(@Counter);
    end;

  pBlock^:=pBlock^ XOR PByte(Cardinal(@Counter) + (i mod 16))^;

  inc(i);
  inc(pBlock);
  dec(dwInSize);
  end;
end;



procedure Crypt_Hash128(const pData: Pointer;
                        const dwSize, dwIterationsCount: LongWord;
                        const pHash: P128bit);
begin
Hash_128(pData, dwSize, dwIterationsCount, pHash);
end;


function Crypt_GenerateRndStrW(const Len: Integer): WideString;
const
  CHARSET: Array[0..61] of WideChar =
    ('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
     'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
     '1','2','3','4','5','6','7','8','9','0');
var
i, j: Integer;
begin
SetLength(result, Len);
i:=1;
while i <= Len do
  begin
  RtlGenRandom(@j, SizeOf(j));
  j:=j AND $000000FF;
  if j <= High(CHARSET) then
    begin
    result[i]:=CHARSET[j];
    inc(i);
    end;
  end;
end;


end.
