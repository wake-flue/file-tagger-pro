import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    required property QtObject style
    required property var fileManager
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 添加设置保存延迟
    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (settings) {
                console.log("保存新的图标大小:", iconSizeSlider.value)
                settings.iconSize = iconSizeSlider.value  // 直接设置属性
                settings.setValue("iconSize", iconSizeSlider.value)  // 同时调用方法保存
                if (fileManager && fileManager.fileModel) {
                    fileManager.fileModel.iconSize = iconSizeSlider.value
                }
            }
        }
    }
    
    // 标题
    Label {
        text: qsTr("常规设置")
        font {
            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
            bold: true
        }
        color: style?.textColor ?? settingsStyle.defaultTextColor
    }
    
    // 说明文本
    Label {
        text: qsTr("调整应用程序的基本显示和行为")
        font {
            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
        }
        color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
        opacity: settingsStyle.defaultOpacity
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
    
    // 图标大小设置
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: settingsStyle.defaultSpacing
        spacing: settingsStyle.defaultItemSpacing
        
        Label {
            text: qsTr("大图标视图设置")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        // 图标大小滑块
        RowLayout {
            Layout.fillWidth: true
            spacing: settingsStyle.defaultSpacing
            
            Label {
                text: qsTr("图标大小")
                font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                color: style?.textColor ?? settingsStyle.defaultTextColor
            }
            
            Slider {
                id: iconSizeSlider
                Layout.fillWidth: true
                from: 48
                to: 256
                stepSize: 16
                value: settings.iconSize || 128
                
                background: Rectangle {
                    x: iconSizeSlider.leftPadding
                    y: iconSizeSlider.topPadding + iconSizeSlider.availableHeight / 2 - height / 2
                    width: iconSizeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: style?.borderColor ?? settingsStyle.defaultBorderColor
                    
                    Rectangle {
                        width: iconSizeSlider.visualPosition * parent.width
                        height: parent.height
                        color: style?.accentColor ?? settingsStyle.defaultAccentColor
                        radius: 2
                    }
                }
                
                handle: Rectangle {
                    x: iconSizeSlider.leftPadding + iconSizeSlider.visualPosition 
                       * (iconSizeSlider.availableWidth - width)
                    y: iconSizeSlider.topPadding + iconSizeSlider.availableHeight / 2 - height / 2
                    width: 16
                    height: 16
                    radius: 8
                    color: iconSizeSlider.pressed ? 
                           Qt.darker(style?.accentColor ?? settingsStyle.defaultAccentColor, 1.1) : 
                           style?.accentColor ?? settingsStyle.defaultAccentColor
                    
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }
                
                onValueChanged: {
                    if (settings) {
                        saveTimer.restart()
                    }
                }
            }
            
            // 添加提示文本
            Label {
                id: restartHint
                text: qsTr("修改图标大小需要重启应用后生效")
                font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                font.pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 2
                color: "#FF6B6B"  // 使用醒目的红色
                opacity: 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
            
            // 显示当前值
            Label {
                text: Math.round(iconSizeSlider.value) + " px"
                font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
                Layout.minimumWidth: 50
            }
        }
        
        // 重置按钮
        Button {
            text: qsTr("重置为默认值")
            Layout.topMargin: settingsStyle.defaultSpacing
            
            onClicked: {
                iconSizeSlider.value = 128
            }
            
            background: Rectangle {
                implicitWidth: 120
                implicitHeight: settingsStyle.defaultInputHeight
                color: parent.pressed ? 
                       style?.buttonPressedColor ?? settingsStyle.defaultButtonPressedColor :
                       parent.hovered ? 
                       style?.buttonHoverColor ?? settingsStyle.defaultButtonHoverColor :
                       style?.buttonNormalColor ?? settingsStyle.defaultButtonNormalColor
                border.color: parent.pressed ?
                            style?.buttonPressedBorderColor ?? settingsStyle.defaultButtonPressedBorderColor :
                            parent.hovered ?
                            style?.buttonHoverBorderColor ?? settingsStyle.defaultButtonHoverBorderColor :
                            style?.buttonNormalBorderColor ?? settingsStyle.defaultButtonNormalBorderColor
                border.width: 1
                radius: settingsStyle.defaultRadius
            }
            
            contentItem: Text {
                text: parent.text
                font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                color: style?.textColor ?? settingsStyle.defaultTextColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    
    Item { Layout.fillHeight: true }
    
    // 添加组件初始化检查
    Component.onCompleted: {
        // 确保设置值正确加载
        if (settings) {
            iconSizeSlider.value = settings.iconSize
        }
    }
    
    // 添加属性变化监听
    Connections {
        target: settings
        function onIconSizeChanged() {
            iconSizeSlider.value = settings.iconSize
        }
    }
    
    // 在Slider后面添加
    Connections {
        target: fileListModel
        function onRestartRequired() {
            restartHint.opacity = 1  // 显示提示文本
            
            // 3秒后自动隐藏提示
            hideTimer.restart()
        }
    }
    
    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: restartHint.opacity = 0
    }
} 