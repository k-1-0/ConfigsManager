unit RC6;

interface

uses Windows, Crypt;



procedure RC6_Init(const pKey: P128bit);

procedure RC6_EncryptBlock(const pBlock: P128bit);

procedure RC6_DecryptBlock(const pBlock: P128bit);

function RC6_SelfTest: Boolean;




implementation



const
  NUMROUNDS   = 20; // number of rounds must be between 16-24
  NUMROUNDS_2 = NUMROUNDS shl 1;


var
  KeyD: Array[0..(NUMROUNDS_2 + 3)] of DWORD;

const
  SBOX: Array[0..51] of DWORD= (
    $B7E15163,$5618CB1C,$F45044D5,$9287BE8E,$30BF3847,$CEF6B200,
    $6D2E2BB9,$0B65A572,$A99D1F2B,$47D498E4,$E60C129D,$84438C56,
    $227B060F,$C0B27FC8,$5EE9F981,$FD21733A,$9B58ECF3,$399066AC,
    $D7C7E065,$75FF5A1E,$1436D3D7,$B26E4D90,$50A5C749,$EEDD4102,
    $8D14BABB,$2B4C3474,$C983AE2D,$67BB27E6,$05F2A19F,$A42A1B58,
    $42619511,$E0990ECA,$7ED08883,$1D08023C,$BB3F7BF5,$5976F5AE,
    $F7AE6F67,$95E5E920,$341D62D9,$D254DC92,$708C564B,$0EC3D004,
    $ACFB49BD,$4B32C376,$E96A3D2F,$87A1B6E8,$25D930A1,$C410AA5A,
    $62482413,$007F9DCC,$9EB71785,$3CEE913E);


function LRot16(X: word; c: integer): word; assembler;
asm
  mov ecx,&c
  mov ax,&X
  rol ax,cl
  mov &Result,ax
end;

function RRot16(X: word; c: integer): word; assembler;
asm
  mov ecx,&c
  mov ax,&X
  ror ax,cl
  mov &Result,ax
end;

function LRot32(X: dword; c: integer): dword; assembler;
asm
  mov ecx,&c
  mov eax,&X
  rol eax,cl
  mov &Result,eax
end;

function RRot32(X: dword; c: integer): dword; assembler;
asm
  mov ecx,&c
  mov eax,&X
  ror eax,cl
  mov &Result,eax
end;

procedure XorBlock(I1, I2, O1: PByteArray; Len: integer);
var
  i: integer;
begin
  for i:= 0 to Len-1 do
    O1[i]:= I1[i] xor I2[i];
end;

procedure IncBlock(P: PByteArray; Len: integer);
begin
  Inc(P[Len-1]);
  if (P[Len-1]= 0) and (Len> 1) then
    IncBlock(P,Len-1);
end;



procedure RC6_Init(const pKey: P128bit);
var
xKeyD: Array[0..63] of DWORD;
i, j, k, n, xKeyLen: Integer;
A, B: DWord;
begin
ZeroMemory(@xKeyD, Sizeof(xKeyD));
xKeyD[0]:=pKey^[0];
xKeyD[1]:=pKey^[1];
xKeyD[2]:=pKey^[2];
xKeyD[3]:=pKey^[3];

//xKeyLen:=dwKeyLen shr 2;
//if (dwKeyLen mod 4) <> 0 then inc(xKeyLen);
xKeyLen:=4; // (4 DWORDs = 16 Bytes) / 4 = 4

Move(SBOX, KeyD, (NUMROUNDS_2 + 4) shl 2);
i:=0;
j:=0;
A:=0;
B:=0;
if xKeyLen > (NUMROUNDS_2 + 4) then k:=xKeyLen * 3 else k:=(NUMROUNDS_2 + 4) * 3;
for n:=1 to k do
  begin
  A:=LRot32(KeyD[i] + A + B, 3);
  KeyD[i]:=A;
  B:=LRot32(xKeyD[j] + A + B, A + B);
  xKeyD[j]:=B;
  i:=(i + 1) mod (NUMROUNDS_2 + 4);
  j:=(j + 1) mod xKeyLen;
  end;
ZeroMemory(@xKeyD, Sizeof(xKeyD));
end;



procedure RC6_EncryptBlock(const pBlock: P128bit);
var
A, B, C, D, t, u, i: DWORD;
begin
A:=PDWORD(pBlock)^;
B:=PDWORD(Cardinal(pBlock) + 4)^;
C:=PDWORD(Cardinal(pBlock) + 8)^;
D:=PDWORD(Cardinal(pBlock) + 12)^;

B:= B + KeyD[0];
D:= D + KeyD[1];
for i:=1 to NUMROUNDS do
  begin
  t:=Lrot32(B * ((B shl 1) + 1), 5);
  u:=Lrot32(D * ((D shl 1) + 1), 5);
  A:=Lrot32(A xor t, u) + KeyD[i shl 1];
  C:=Lrot32(C xor u, t) + KeyD[(i shl 1) + 1];
  t:=A; A:=B; B:=C; C:=D; D:=t;
  end;
A:=A + KeyD[NUMROUNDS_2 + 2];
C:=C + KeyD[NUMROUNDS_2 + 3];

PDWORD(pBlock)^:=A;
PDWORD(Cardinal(pBlock) + 4)^:=B;
PDWORD(Cardinal(pBlock) + 8)^:=C;
PDWORD(Cardinal(pBlock) + 12)^:=D;
end;


procedure RC6_DecryptBlock(const pBlock: P128bit);
var
A, B, C, D, t, u, i: DWord;
begin
A:=PDWORD(pBlock)^;
B:=PDWORD(Cardinal(pBlock) + 4)^;
C:=PDWORD(Cardinal(pBlock) + 8)^;
D:=PDWORD(Cardinal(pBlock) + 12)^;

C:=C - KeyD[NUMROUNDS_2 + 3];
A:=A - KeyD[NUMROUNDS_2 + 2];
for i:=NUMROUNDS downto 1 do
  begin
  t:=A; A:=D; D:=C; C:=B; B:=t;
  u:=Lrot32(D * ((D shl 1) + 1), 5);
  t:=Lrot32(B * ((B shl 1) + 1), 5);
  C:=Rrot32(C - KeyD[(i shl 1) + 1], t) xor u;
  A:=Rrot32(A - KeyD[i shl 1], u) xor t;
  end;
D:= D - KeyD[1];
B:= B - KeyD[0];

PDWORD(pBlock)^:=A;
PDWORD(Cardinal(pBlock) + 4)^:=B;
PDWORD(Cardinal(pBlock) + 8)^:=C;
PDWORD(Cardinal(pBlock) + 12)^:=D;
end;



function RC6_SelfTest: Boolean;
const
  Key: array[0..15] of Byte =
    ($01,$23,$45,$67,$89,$ab,$cd,$ef,$01,$12,$23,$34,$45,$56,$67,$78);
  InBlock: array[0..15] of Byte =
    ($02,$13,$24,$35,$46,$57,$68,$79,$8a,$9b,$ac,$bd,$ce,$df,$e0,$f1);
  OutBlock: array[0..15] of Byte =
    ($52,$4e,$19,$2f,$47,$15,$c6,$23,$1f,$51,$f6,$36,$7e,$a4,$3f,$18);
var
Block: Array[0..15] of Byte;
begin
RC6_Init(@Key);
CopyMemory(@Block, @InBlock, SizeOf(Block));
RC6_EncryptBlock(@Block);
result:=Crypt_CompareMem128(@Block, @OutBlock);
RC6_DecryptBlock(@Block);
result:=result AND Crypt_CompareMem128(@Block, @InBlock);
end;




end.
