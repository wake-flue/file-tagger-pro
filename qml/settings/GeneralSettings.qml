import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0
import "../utils" as Utils

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
                settings.iconSize = iconSizeSlider.value
                settings.setValue("iconSize", iconSizeSlider.value)
                if (fileManager && fileManager.fileModel) {
                    fileManager.fileModel.iconSize = iconSizeSlider.value
                }
            }
        }
    }
    
    // 标题和说明
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        Label {
            text: qsTr("常规设置")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.titleFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("调整应用程序的基本显示和行为")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
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
                pixelSize: settingsStyle.defaultFontSize
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
                font.pixelSize: settingsStyle.defaultFontSize
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
                    color: settingsStyle.defaultBorderColor
                    
                    Rectangle {
                        width: iconSizeSlider.visualPosition * parent.width
                        height: parent.height
                        color: settingsStyle.defaultAccentColor
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
                           Qt.darker(settingsStyle.defaultAccentColor, 1.1) : 
                           settingsStyle.defaultAccentColor
                    
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
            
            // 提示文本
            Label {
                id: restartHint
                text: qsTr("修改图标大小需要重启应用后生效")
                font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                font.pixelSize: settingsStyle.descriptionFontSize
                color: "#FF6B6B"
                opacity: 0
                
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }
            
            // 显示当前值
            Label {
                text: Math.round(iconSizeSlider.value) + " px"
                font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                font.pixelSize: settingsStyle.defaultFontSize
                color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
                Layout.minimumWidth: 50
            }
        }
        
        // 重置按钮
        Button {
            text: qsTr("重置为默认值")
            Layout.topMargin: settingsStyle.defaultSpacing
            
            background: Rectangle {
                implicitWidth: 120
                implicitHeight: settingsStyle.defaultButtonHeight
                color: parent.down ? settingsStyle.defaultButtonPressedColor :
                       parent.hovered ? settingsStyle.defaultButtonHoverColor :
                       settingsStyle.defaultButtonNormalColor
                border.color: parent.down ? settingsStyle.defaultButtonPressedBorderColor :
                            parent.hovered ? settingsStyle.defaultButtonHoverBorderColor :
                            settingsStyle.defaultButtonNormalBorderColor
                border.width: 1
                radius: settingsStyle.defaultRadius
            }
            
            contentItem: Text {
                text: parent.text
                font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                font.pixelSize: settingsStyle.defaultFontSize
                color: style?.textColor ?? settingsStyle.defaultTextColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                iconSizeSlider.value = 128
            }
        }
    }
    
    Item { Layout.fillHeight: true }
    
    // 组件初始化检查
    Component.onCompleted: {
        if (settings) {
            iconSizeSlider.value = settings.iconSize
        }
    }
    
    // 属性变化监听
    Connections {
        target: settings
        function onIconSizeChanged() {
            iconSizeSlider.value = settings.iconSize
        }
    }
    
    Timer {
        id: hideTimer
        interval: 3000
        onTriggered: restartHint.opacity = 0
    }
    
    Connections {
        target: settings
        
        function onValueChanged(key, value) {
            Utils.Logger.logOperation(fileManager, "更新设置", key + " = " + value)
        }
    }
    
    Button {
        text: qsTr("重置设置")
        onClicked: {
            Utils.Logger.logOperation(fileManager, "重置所有设置", "")
            if (settings) {
                settings.reset()
            }
        }
    }
} 