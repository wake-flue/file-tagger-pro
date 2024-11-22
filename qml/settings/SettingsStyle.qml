import QtQuick

QtObject {
    id: root
    
    readonly property color defaultTextColor: "#202020"
    readonly property color defaultBorderColor: "#E5E5E5"
    readonly property color defaultAccentColor: "#0078D4"
    readonly property string defaultFontFamily: "Microsoft YaHei"
    readonly property int defaultFontSize: 12
    
    // 组件尺寸
    readonly property int defaultInputHeight: 32
    readonly property int defaultButtonWidth: 70
    readonly property int defaultButtonHeight: 32
    readonly property int defaultSpacing: 16
    readonly property int defaultItemSpacing: 4
    
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
} 