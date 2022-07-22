object PasswordForm: TPasswordForm
  Left = 602
  Top = 294
  BorderStyle = bsDialog
  Caption = 'Keyword'
  ClientHeight = 139
  ClientWidth = 352
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 20
    Top = 16
    Width = 3
    Height = 13
  end
  object SpeedButton1: TSpeedButton
    Left = 16
    Top = 66
    Width = 33
    Height = 17
    Caption = '0'
    OnClick = SpeedButton1Click
  end
  object SpeedButton2: TSpeedButton
    Left = 48
    Top = 66
    Width = 33
    Height = 17
    Caption = '1'
    OnClick = SpeedButton2Click
  end
  object SpeedButton3: TSpeedButton
    Left = 80
    Top = 66
    Width = 33
    Height = 17
    Caption = '2'
    OnClick = SpeedButton3Click
  end
  object SpeedButton4: TSpeedButton
    Left = 112
    Top = 66
    Width = 33
    Height = 17
    Caption = '3'
    OnClick = SpeedButton4Click
  end
  object SpeedButton5: TSpeedButton
    Left = 144
    Top = 66
    Width = 33
    Height = 17
    Caption = '4'
    OnClick = SpeedButton5Click
  end
  object SpeedButton6: TSpeedButton
    Left = 176
    Top = 66
    Width = 33
    Height = 17
    Caption = '5'
    OnClick = SpeedButton6Click
  end
  object SpeedButton7: TSpeedButton
    Left = 208
    Top = 66
    Width = 33
    Height = 17
    Caption = '6'
    OnClick = SpeedButton7Click
  end
  object SpeedButton8: TSpeedButton
    Left = 240
    Top = 66
    Width = 33
    Height = 17
    Caption = '7'
    OnClick = SpeedButton8Click
  end
  object SpeedButton9: TSpeedButton
    Left = 272
    Top = 66
    Width = 33
    Height = 17
    Caption = '8'
    OnClick = SpeedButton9Click
  end
  object SpeedButton10: TSpeedButton
    Left = 304
    Top = 66
    Width = 33
    Height = 17
    Caption = '9'
    OnClick = SpeedButton10Click
  end
  object Edit1: TEdit
    Left = 16
    Top = 42
    Width = 321
    Height = 21
    TabOrder = 0
  end
  object Button1: TButton
    Left = 180
    Top = 100
    Width = 75
    Height = 23
    Caption = 'OK'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 264
    Top = 100
    Width = 75
    Height = 23
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
