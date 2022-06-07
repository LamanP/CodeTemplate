object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Code templates'
  ClientHeight = 574
  ClientWidth = 805
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 241
    Width = 805
    Height = 3
    Cursor = crVSplit
    Align = alTop
    Beveled = True
    ExplicitWidth = 257
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 805
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      805
      41)
    object LabelTemplateFileName: TLabel
      Left = 112
      Top = 14
      Width = 681
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
    end
    object Button1: TButton
      Left = 16
      Top = 9
      Width = 75
      Height = 25
      Action = ActionOpenTemplate
      TabOrder = 0
    end
  end
  object ScrollBoxParameters: TScrollBox
    Left = 0
    Top = 41
    Width = 805
    Height = 200
    Align = alTop
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 1
  end
  object PageControlTemplate: TPageControl
    Left = 0
    Top = 244
    Width = 805
    Height = 330
    ActivePage = TabSheetTemplate
    Align = alClient
    TabOrder = 2
    object TabSheetTemplate: TTabSheet
      Caption = 'Template'
      OnShow = TabSheetTemplateShow
      object RETemplate: TRichEdit
        Left = 0
        Top = 0
        Width = 797
        Height = 261
        Align = alClient
        BevelInner = bvNone
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssBoth
        TabOrder = 0
        Zoom = 100
        OnChange = RETemplateChange
      end
      object Panel2: TPanel
        Left = 0
        Top = 261
        Width = 797
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 1
        DesignSize = (
          797
          41)
        object LabelModified: TLabel
          Left = 454
          Top = 16
          Width = 40
          Height = 13
          Caption = 'Modified'
          Visible = False
        end
        object Button2: TButton
          Left = 539
          Top = 9
          Width = 117
          Height = 25
          Action = ActionApplyEdits
          Anchors = [akTop, akRight]
          TabOrder = 0
        end
        object Button3: TButton
          Left = 671
          Top = 9
          Width = 117
          Height = 25
          Action = ActionSaveTemplate
          Anchors = [akTop, akRight]
          TabOrder = 1
        end
      end
    end
  end
  object ActionList: TActionList
    Left = 152
    object ActionOpenTemplate: TAction
      Caption = 'Open...'
      OnExecute = ActionOpenTemplateExecute
    end
    object ActionSaveTemplate: TAction
      Caption = 'Save template...'
      OnExecute = ActionSaveTemplateExecute
      OnUpdate = ActionSaveTemplateUpdate
    end
    object ActionApplyEdits: TAction
      Caption = 'Apply edits'
      OnExecute = ActionApplyEditsExecute
      OnUpdate = ActionApplyEditsUpdate
    end
  end
  object OpenDialogTemplate: TOpenDialog
    DefaultExt = 'tpl'
    Filter = 'Code template|*.tpl|Any file|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 192
  end
  object SaveDialogTemplate: TSaveDialog
    DefaultExt = 'tpl'
    Filter = 'Code template|*.tpl|Any file|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 304
    Top = 9
  end
  object TimerSyntaxHighlight: TTimer
    Enabled = False
    Interval = 500
    OnTimer = TimerSyntaxHighlightTimer
    Left = 448
    Top = 8
  end
end
