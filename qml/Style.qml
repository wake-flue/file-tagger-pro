pragma Singleton
import QtQuick 2.15

QtObject {
    // 主题颜色
    readonly property color primaryColor: "#2196F3"
    readonly property color secondaryColor: "#FFC107"
    readonly property color backgroundColor: "#FFFFFF"
    readonly property color textColor: "#333333"
    readonly property color lightTextColor: "#666666"
    readonly property color errorColor: "#F44336"
    
    // 界面特定颜色
    readonly property color accentColor: "#0078D4"
    readonly property color borderColor: "#E5E5E5"
    readonly property color hoverColor: "#F0F0F0"
    readonly property color selectedColor: "#E5F3FF"
    readonly property color shadowColor: "#40000000"
    readonly property color overlayColor: "#80000000"
    readonly property color successColor: "#4CAF50"
    readonly property color warningColor: "#FF9800"
    
    // 窗口控件颜色
    readonly property color windowBorderColor: "#E5E5E5"
    readonly property color windowBackgroundColor: "#FFFFFF"
    readonly property color titleBarColor: "transparent"
    readonly property color titleBarTextColor: "#202020"
    readonly property color controlButtonNormalColor: "transparent"
    readonly property color controlButtonHoverColor: "#F0F0F0"
    readonly property color controlButtonTextColor: "#202020"
    readonly property color controlButtonCloseHoverColor: "#E81123"
    readonly property color controlButtonCloseHoverTextColor: "#FFFFFF"
    
    // 字体设置
    readonly property string fontFamily: {
        switch (Qt.platform.os) {
            case "windows":
                return "Microsoft YaHei"
            case "osx":
                return "PingFang SC"
            default:
                return "Sans-serif"
        }
    }
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeNormal: 12
    readonly property int fontSizeLarge: 14
    readonly property int fontSizeTitle: 16
    
    // 窗口设置
    readonly property int defaultWindowWidth: 960
    readonly property int defaultWindowHeight: 680
    readonly property int minimumWindowWidth: 800
    readonly property int minimumWindowHeight: 600
    
    // 窗口控件尺寸
    readonly property int titleBarHeight: 32
    readonly property int controlButtonWidth: 46
    readonly property int controlButtonHeight: 32
    readonly property int controlButtonIconSize: 10
    readonly property int windowBorderWidth: 1
    readonly property int windowResizerSize: 8
    
    // 组件尺寸
    readonly property int toolBarHeight: 40
    readonly property int statusBarHeight: 28
    readonly property int sideBarWidth: 200
    readonly property int buttonHeight: 32
    readonly property int inputHeight: 32
    
    // 间距
    readonly property int spacingSmall: 4
    readonly property int spacingNormal: 8
    readonly property int spacingLarge: 16
    readonly property int spacingXLarge: 24
    readonly property int contentMargin: 16
    
    // 圆角
    readonly property int radiusSmall: 4
    readonly property int radiusNormal: 8
    readonly property int radiusLarge: 12
    
    // 边框
    readonly property int noneBorderWidth: 0
    readonly property int borderWidth: 1
    readonly property int focusBorderWidth: 2
    
    // 阴影
    readonly property string normalShadow: "0 2px 4px rgba(0, 0, 0, 0.1)"
    readonly property string largeShadow: "0 4px 8px rgba(0, 0, 0, 0.15)"
    readonly property string dropShadow: "0 2px 8px rgba(0, 0, 0, 0.15)"
    
    // 动画
    readonly property int animationDurationFast: 150
    readonly property int animationDurationNormal: 250
    readonly property int animationDurationSlow: 350
    
    // 图标
    readonly property int iconSizeMini: 14
    readonly property int iconSizeSmall: 16
    readonly property int iconSizeNormal: 24
    readonly property int iconSizeLarge: 32
    
    // 列表项
    readonly property int listItemHeight: 40
    readonly property int listItemPadding: 8
    
    // 工具提示
    readonly property int tooltipDelay: 500
    readonly property int tooltipTimeout: 5000
    
    // 滚动条
    readonly property int scrollBarWidth: 8
    readonly property int scrollBarMinLength: 40
    
    // 标签
    readonly property int tagHeight: 24
    readonly property int tagSpacing: 4
    readonly property int tagPadding: 8
    
    // 对话框
    readonly property real dialogOpacity: 0.95
    readonly property int dialogPadding: 24
    readonly property int dialogButtonSpacing: 8
    readonly property int dialogButtonWidth: 80
    readonly property int dialogButtonHeight: 32
} 