object FormProgress: TFormProgress
  Left = 378
  Top = 329
  BorderIcons = []
  BorderStyle = bsToolWindow
  ClientHeight = 82
  ClientWidth = 321
  Color = 12631988
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object LbProgress: TLabel
    Left = 4
    Top = 5
    Width = 312
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object ProgressBar: TProgressBar
    Left = 4
    Top = 25
    Width = 312
    Height = 20
    ParentShowHint = False
    Position = 33
    Smooth = True
    Step = 1
    ShowHint = False
    TabOrder = 0
  end
  object BtCancel: TButton
    Left = 123
    Top = 54
    Width = 75
    Height = 23
    Cancel = True
    Caption = 'Annuler'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    ModalResult = 2
    ParentFont = False
    TabOrder = 1
  end
  object TimerStart: TTimer
    Enabled = False
    Interval = 100
    OnTimer = TimerStartTimer
    Left = 284
    Top = 4
  end
end
