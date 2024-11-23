import QtQuick

QtObject {
    id: root
    
    // 文本颜色
    readonly property color defaultTextColor: "#202020"
    readonly property color defaultSecondaryTextColor: "#666666"
    readonly property color defaultBorderColor: "#E5E5E5"
    readonly property color defaultAccentColor: "#0078D4"
    
    // 字体
    readonly property string defaultFontFamily: "Microsoft YaHei"
    readonly property int defaultFontSize: 12
    readonly property int titleFontSize: defaultFontSize + 1
    readonly property int descriptionFontSize: defaultFontSize - 1
    
    // 组件尺寸
    readonly property int defaultInputHeight: 32
    readonly property int defaultButtonWidth: 70
    readonly property int defaultButtonHeight: 32
    readonly property int defaultSpacing: 16
    readonly property int defaultItemSpacing: 8
    
    // 组件样式
    readonly property int defaultRadius: 4
    readonly property real defaultOpacity: 0.7
    
    // 状态颜色
    readonly property color defaultButtonPressedColor: "#e0e0e0"
    readonly property color defaultButtonHoverColor: "#f5f5f5"
    readonly property color defaultButtonNormalColor: "#ffffff"
    readonly property color defaultButtonPressedBorderColor: "#cccccc"
    readonly property color defaultButtonHoverBorderColor: "#d1d1d1"
    readonly property color defaultButtonNormalBorderColor: "#e0e0e0"
    
    // 背景颜色
    readonly property color defaultBackgroundColor: "#ffffff"
    readonly property color defaultSectionBackgroundColor: "#f5f5f5"
    
    // 输入框样式
    readonly property color defaultInputBackgroundColor: "#ffffff"
    readonly property color defaultInputBorderColor: "#d1d1d1"
    readonly property color defaultInputFocusBorderColor: defaultAccentColor
    
    // 列表样式
    readonly property color defaultListItemHoverColor: "#f5f5f5"
    readonly property color defaultListItemSelectedColor: "#e5f3ff"
    
    // 日志相关样式
    readonly property color logErrorColor: "#dc3545"
    readonly property color logWarningColor: "#ffc107"
    readonly property color logDebugColor: "#6c757d"
    readonly property color logInfoColor: defaultTextColor
    
    // 日志列表样式
    readonly property color logListBackgroundColor: "#ffffff"
    readonly property color logListAlternateColor: "#f8f9fa"
    readonly property int logItemHeight: 32
    readonly property int logItemPadding: 8
    
    // 工具栏样式
    readonly property color toolbarBackgroundColor: "#f8f9fa"
    readonly property int toolbarHeight: 40
    
    // 下拉框样式
    readonly property int comboBoxHeight: 32
    readonly property int comboBoxPopupItemHeight: 32
    readonly property int comboBoxIndicatorSize: 12
    readonly property int comboBoxLeftPadding: 12
    readonly property int comboBoxRightPadding: 36
    
    // 下拉框颜色
    readonly property color comboBoxNormalColor: "#ffffff"
    readonly property color comboBoxHoverColor: "#f5f5f5"
    readonly property color comboBoxPressedColor: "#e0e0e0"
    readonly property color comboBoxBorderColor: "#d1d1d1"
    readonly property color comboBoxFocusBorderColor: defaultAccentColor
    
    // 下拉框弹出项样式
    readonly property color comboBoxPopupBackgroundColor: "#ffffff"
    readonly property color comboBoxPopupBorderColor: "#d1d1d1"
    readonly property color comboBoxItemNormalColor: "transparent"
    readonly property color comboBoxItemHoverColor: "#f5f5f5"
    readonly property color comboBoxItemHighlightColor: "#e5f3ff"
    readonly property color comboBoxItemTextColor: defaultTextColor
    readonly property color comboBoxItemHighlightedTextColor: defaultAccentColor
} 