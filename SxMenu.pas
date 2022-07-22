
  {********************************************************************}
  {                                                                    }
  {     SxMenu                                                         }
  {     version 1.0 beta                                               }
  {                                                                    }
  {     by K10                                                         }
  {                                                                    }
  {     based on TRyMenu v1.10 by Алексей Румянцев (skitl@mail.ru)     }
  {                                                                    }
  {********************************************************************}

unit SxMenu;

interface

uses Windows, SysUtils, Classes, Messages, Graphics, ImgList, Menus,
     Forms, Controls, Commctrl;

type
  PComponent = ^TComponent;

  procedure SxMenu_Initialize(AParent: PComponent);
  procedure SxMenu_Finalize;
  procedure SxMenu_SetDefaultColors;
  procedure SxMenu_AddMenu(Menu: TMenu);
  
  function GetLightColor(const Color: TColor; const Light: Byte) : TColor;
  function GetShadowColor(const BaseColor: TColor; Shadow: Integer): TColor;

var
  SxmFont: TFont;
  SxmGutterColor, SxmMenuColor, SxmSelectedColor, SxmSelectedBorderColor,
  SxmSelLightColor, SxmShadowColor: TColor;

implementation

const
  ITEM_HEIGHT          = 22;
  ITEM_HEIGHT_2        = 18;
  SEPARATOR_HEIGHT     = 5;
  SEPARATOR_HEIGHT_2   = 5;
  GUTTER_WIDTH         = 25;

var
  FMonoBitmap : TBitmap;
  BmpCheck: Array[Boolean] of Array[Boolean] of TBitmap;

procedure InitBmpCheck(ARadio, AEnabled: Boolean);
const
  pc : Array[0..13] of Array[0..1] of Byte = (
    (3,5), (3,6), (4,6), (4,7), (5,7), (5,8), (6,7), (6,6), (7,6),
    (7,5), (8,5), (8,4), (9,4), (9,3));
  pr : Array[0..15] of Array[0..1] of Byte = (
     (4,4), (4,5), (4,6), (4,7), (5,4), (5,5), (5,6), (5,7),
     (6,4), (6,5), (6,6), (6,7), (7,4), (7,5), (7,6), (7,7));
  bc: Array[Boolean] of TColor = (clBtnShadow, clBlack);
var
i: Byte;
begin
with BmpCheck[ARadio][AEnabled], Canvas do
  begin
  Width:=12;
  Height:=12;
  //Monochrome:=True;
  Transparent:=True;
  Pen.Color:=clBlack;
  Brush.Color:=clWhite;
  FillRect(Rect(0, 0, Width, Height));
  if ARadio then
    for i:=Low(pc) to High(pr) do Pixels[pr[i, 0], pr[i, 1]]:=bc[AEnabled]
  else
    for i:=Low(pr) to High(pc) do Pixels[pc[i, 0], pc[i, 1]]:=bc[AEnabled];
  end;
end;

function GetLightColor(const Color: TColor; const Light: Byte) : TColor;
var
R, G, B: Byte;
iColor: TColor;
begin
iColor:=ColorToRGB(Color);
R:=Byte(iColor);
G:=Byte(iColor shr 8);
B:=Byte(iColor shr 16);
Result:=
   Round(R + ((255 - R) * Light * 0.01))         OR
  (Round(G + ((255 - G) * Light * 0.01)) shl  8) OR
  (Round(B + ((255 - B) * Light * 0.01)) shl 16);
end;

function Max(a, b: Longint): Longint;
begin
if a > b then Result := a else Result := b;
end;

function GetShadowColor(const BaseColor: TColor; Shadow: Integer): TColor;
begin
  Result := RGB(Max(GetRValue(ColorToRGB(BaseColor)) - Shadow, 0),
    Max(GetGValue(ColorToRGB(BaseColor)) - Shadow, 0),
    Max(GetBValue(ColorToRGB(BaseColor)) - Shadow, 0));
end;

procedure SxMenu_Finalize;
begin
FMonoBitmap.Free;
BmpCheck[false][false].Free;
BmpCheck[false][true].Free;
BmpCheck[true][false].Free;
BmpCheck[true][true].Free;
end;

procedure SxMenu_SetDefaultColors;
begin
SxmGutterColor:=clBtnFace;
SxmMenuColor:=GetLightColor(clBtnFace, 85);
SxmSelectedColor:=GetLightColor(clHighlight, 75{65});{выделенный пункт меню}
SxmSelectedBorderColor:=clHighLight;
SxmSelLightColor:=GetLightColor(clHighlight, 75);
SxmShadowColor:=clBtnShadow;
end;

procedure SxMenu_MeasureItem(Self: Pointer; Sender: TObject; ACanvas: TCanvas;
          var Width, Height: Integer);
begin
Width:=ACanvas.TextWidth(TMenuItem(Sender).Caption) + 32;
if TMenuItem(Sender).IsLine then Height:=SEPARATOR_HEIGHT else Height:=ITEM_HEIGHT;
end;

procedure SxMenu_Initialize(AParent: PComponent);
begin
//SxMenu_SetDefaultColors;
if Assigned(AParent) then SxmFont:=(AParent^ as TForm).Font
  else SxmFont:=Screen.MenuFont;
BmpCheck[false][false]:=TBitmap.Create;
BmpCheck[false][true]:=TBitmap.Create;
BmpCheck[true][false]:=TBitmap.Create;
BmpCheck[true][true]:=TBitmap.Create;
InitBmpCheck(false, false);
InitBmpCheck(false, true);
InitBmpCheck(true, false);
InitBmpCheck(true, true);
FMonoBitmap:=TBitmap.Create;
end;


procedure SxMenu_AdvancedDrawItem(Self: Pointer; Sender: TObject; ACanvas: TCanvas;
          ARect: TRect; State: TOwnerDrawState);

type
  PCustomImageList = ^TCustomImageList;

  procedure GetBmpFromImgList(var ABmp: TBitmap; AImgList: PCustomImageList;
            const ImageIndex: Word);
  begin
  ABmp.Width:=AImgList^.Width;
  ABmp.Height:=AImgList^.Height;
  ABmp.Canvas.Brush.Color:=clWhite;
  ABmp.Canvas.FillRect(Rect(0, 0, ABmp.Width, ABmp.Height));
  ImageList_DrawEx(AImgList.Handle, ImageIndex, ABmp.Canvas.Handle, 0, 0, 0, 0, CLR_DEFAULT, 0, ILD_NORMAL);
  end;

  procedure DoDrawMonoBmp(var BMP: TBitmap; var ACanvas: TCanvas; const AMonoColor: TColor;
            const ALeft, ATop: Integer);
  const
    ROP_DSPDxax = $00E20746;{<-- скопировано из ImgList.TCustomImageList.DoDraw()}
    RMask = $0000FF;
    RAMask = $FFFF00;
    GMask = $00FF00;
    GAMask = $FF00FF;
    BMask = $FF0000;
    BAMask = $00FFFF;
  var
    R, C: integer;
    Color: LongWord;
  begin
  BMP.Monochrome:=false;
  with Bmp.Canvas do
    begin
    for C := 0 to Bmp.Height - 1 do
      for R := 0 to Bmp.Width - 1 do
        begin
        Color := Pixels[R, C];
        if ((Color = 0) OR (Color = $FFFFFF)) then Continue;
        if (((Color AND RMask > $7F) AND (Color AND RAMask > $0)) or
          ((Color AND GMask > $7F00) AND (Color AND GAMask > $0)) or
          ((Color AND BMask > $7F000) AND (Color AND BAMask > $0))// or
           ) then Pixels[R, C] := $FFFFFF // light
             else Pixels[R, C] := 0;      // shadow
        end;
    end;
    BitBlt(BMP.Canvas.Handle, 0, 0, BMP.Width, BMP.Height,
           BMP.Canvas.Handle, 0, 0, DSTINVERT);
    ACanvas.Brush.Color:=AMonoColor;
    Windows.SetTextColor(ACanvas.Handle, clWhite);
    Windows.SetBkColor(ACanvas.Handle, clBlack);
    BitBlt(ACanvas.Handle, ALeft, ATop, BMP.Width, BMP.Height,
           BMP.Canvas.Handle, 0, 0, ROP_DSPDxax);
  end;

const
  {текстовые флаги}
//  _Flags: LongInt = DT_NOCLIP or DT_VCENTER or DT_END_ELLIPSIS or DT_SINGLELINE;
  _FlagsTopLevel: Array[Boolean] of Longint = (DT_LEFT, DT_CENTER);
  _FlagsShortCut: {array[Boolean] of} Longint = (DT_RIGHT);
  _RectEl: Array[Boolean] of Byte = (0, 6);{закругленный прямоугольник}
var
  TopLevel: Boolean;
begin
  {.$DEFINE TOPMENU_OPEN_BTNFACE}
  {$DEFINE BORDER_DISABLE_ITEMS}

with TMenuItem(Sender), ACanvas do
  begin
  TopLevel:=GetParentComponent is TMainMenu;

  {$IFDEF BORDER_DISABLE_ITEMS}
    if NOT Enabled then Pen.Color:=SxmShadowColor  else
  {$ENDIF}
    Pen.Color:=SxmSelectedBorderColor;

  if (odSelected in State) then // если пункт меню выделен
    begin
    if NOT (Enabled{ OR TopLevel}) then Brush.Color:=SxmMenuColor else
    {$IFDEF TOPMENU_OPEN_BTNFACE}
    if TopLevel then
      begin
      Pen.Color:=SxmShadowColor;
      Brush.Color:=SxmGutterColor;
      end
    else {$ENDIF}
      Brush.Color:=SxmSelectedColor;

    if Enabled {$IFDEF BORDER_DISABLE_ITEMS} OR (NOT TopLevel) {$ENDIF}
      then
       Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);

    end
  else
    if TopLevel then {если это полоска основного меню}
      begin
      if (odHotLight in State) then {если мышь над пунктом меню}
        begin
        Pen.Color:=SxmSelectedBorderColor;
        Brush.Color:=SxmSelectedColor;
        Rectangle(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
        end
      else
        begin
        Brush.Color:=SxmGutterColor; // фон главного меню
        FillRect(ARect);
        end
      end
    else
      begin {ничем не примечательный пункт меню}
      Brush.Color:=SxmGutterColor;
      FillRect(Rect(ARect.Left, ARect.Top, GUTTER_WIDTH, ARect.Bottom)); // Область полоски
      Brush.Color:=SxmMenuColor;
      FillRect(Rect(GUTTER_WIDTH, ARect.Top, ARect.Right, ARect.Bottom)); // Область пункта
      end;

  if Checked then
    begin {подсвечиваем чекнутый пункт меню}
    if Enabled then
      Brush.Color:=SxmSelLightColor
    else
      begin
      Pen.Color:=SxmShadowColor;
      {$IFDEF BORDER_DISABLE_ITEMS}
        if (odSelected in State) then Brush.Color:=SxmMenuColor else
      {$ENDIF}
        Brush.Color:=SxmGutterColor;
      end;
     RoundRect(ARect.Left + 1, ARect.Top + 1, GUTTER_WIDTH - 2,  // рамка вокруг чекнутого пункта
          ARect.Bottom - 1, _RectEl[RadioItem], _RectEl[RadioItem]);
    if NOT (Assigned(TMenuItem(Sender).GetParentMenu.Images) AND // если у чекнутого пункта нет картинки,
       (TMenuItem(Sender).ImageIndex > -1)) then                 // то рисуется дефолтная
      Draw((ARect.Left + 2 + GUTTER_WIDTH - 1 - 2 - BmpCheck[RadioItem][Enabled].Width) shr 1,
        (ARect.Top + ARect.Bottom - BmpCheck[RadioItem][Enabled].Height) shr 1,
        BmpCheck[RadioItem][Enabled]);
    end;

  if Assigned(TMenuItem(Sender).GetParentMenu.Images) AND
       (TMenuItem(Sender).ImageIndex > -1) AND
       (NOT TopLevel) then
    if Enabled then
        TMenuItem(Sender).GetParentMenu.Images.Draw(ACanvas, ARect.Left + 4,
          (ARect.Top + ARect.Bottom - TMenuItem(Sender).GetParentMenu.Images.Height) shr 1,
          ImageIndex, True) {рисуем цветную картинку}
    else
      begin {рисуем погасшую картинку}
      GetBmpFromImgList(FMonoBitmap, @TMenuItem(Sender).GetParentMenu.Images, ImageIndex);
      DoDrawMonoBmp(FMonoBitmap, ACanvas, SxmShadowColor, ARect.Left + 4,
        (ARect.Top + ARect.Bottom - TMenuItem(Sender).GetParentMenu.Images.Height) shr 1);
      end;

  Font:=SxmFont;
  with Font do
    begin
    if (odDefault in State) then Style:=[fsBold];
    if (odDisabled in State) then Color:=SxmShadowColor;
    end;

    Brush.Style:=bsClear;
    if TopLevel then {пусто}
    else Inc(ARect.Left, GUTTER_WIDTH + 8); {отступ для текста}

    if IsLine then {если разделитель}
      begin
      Pen.Color:=SxmShadowColor;
      MoveTo(ARect.Left, ARect.Top + (ARect.Bottom - ARect.Top) shr 1);
      LineTo(ARect.Right, ARect.Top + (ARect.Bottom - ARect.Top) shr 1);
      end
    else
      begin // текст меню
      {$IFNDEF BORDER_DISABLE_ITEMS}
        if NOT (Enabled OR TopLevel) then Brush.Color:=SxmMenuColor; // чтобы не мигал disabled текст при НЕ EMPTY_DISABLE_ITEMS
      {$ENDIF}
      Windows.DrawText(Handle, PChar(Caption), Length(Caption), ARect,
        DT_NOCLIP OR DT_VCENTER OR DT_END_ELLIPSIS OR DT_SINGLELINE OR _FlagsTopLevel[TopLevel]);
      if ShortCut <> 0 then {разпальцовка}
        begin
        Dec(ARect.Right, 5);
        Windows.DrawText(Handle, PChar(ShortCutToText(ShortCut)),
          Length(ShortCutToText(ShortCut)), ARect,
          DT_NOCLIP OR DT_VCENTER OR DT_END_ELLIPSIS OR DT_SINGLELINE OR _FlagsShortCut);
        end
      end
    end
end;

procedure SxMenu_AddMenu(Menu: TMenu);

procedure InitItems(Item : TMenuItem);
var
  I: Word;
begin
  I := 0;
  while I < Item.Count do
  begin
    @Item[I].OnAdvancedDrawItem:=@SxMenu_AdvancedDrawItem;
    @Item[I].OnMeasureItem:=@SxMenu_MeasureItem;
    if Item[I].Count > 0 then InitItems(Item[I]);
    Inc(I);
  end;
end;

begin
if Assigned(Menu) then
  begin
  InitItems(Menu.Items);
  Menu.OwnerDraw:=True;
  end;
end;



end.
