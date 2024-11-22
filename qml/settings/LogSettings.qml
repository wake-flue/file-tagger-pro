import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    required property QtObject style
    required property var fileManager
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 标题和说明
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        
        Label {
            text: qsTr("日志设置")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("查看和管理应用程序运行日志")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
            opacity: settingsStyle.defaultOpacity
        }
    }
    
    // 日志列表
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: settingsStyle.defaultSpacing
        color: "white"
        border.color: style?.borderColor ?? settingsStyle.defaultBorderColor
        border.width: 1
        radius: settingsStyle.defaultRadius
        
        ListView {
            id: logListView
            anchors.fill: parent
            anchors.margins: 1
            clip: true
            model: fileManager.logMessages
            spacing: 1
            
            onCountChanged: {
                if (atYEnd || count === 1) {
                    positionViewAtEnd()
                }
            }
            
            delegate: Rectangle {
                width: ListView.view.width
                height: logText.height + 12
                color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: style?.borderColor ?? "#f0f0f0"
                    visible: index > 0
                }
                
                Text {
                    id: logText
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: 12
                    }
                    text: modelData
                    color: {
                        if (modelData.toLowerCase().includes("错误") || 
                            modelData.toLowerCase().includes("失败")) {
                            return "#dc3545"
                        } else if (modelData.toLowerCase().includes("警告")) {
                            return "#ffc107"
                        } else if (modelData.toLowerCase().includes("成功") ||
                                 modelData.toLowerCase().includes("完成")) {
                            return "#28a745"
                        }
                        return style?.textColor ?? "#495057"
                    }
                    font {
                        family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                    wrapMode: Text.Wrap
                    
                    Component.onCompleted: {
                        let timestamp = modelData.match(/\[(.*?)\]/);
                        if (timestamp) {
                            let parts = modelData.split("] ");
                            text = "<font color='#999999'>" + timestamp[0] + "]</font> " + 
                                  parts.slice(1).join("] ");
                        }
                    }
                    textFormat: Text.RichText
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                visible: logListView.contentHeight > logListView.height
                
                contentItem: Rectangle {
                    implicitWidth: 8
                    radius: width / 2
                    color: parent.pressed ? "#606060" :
                           parent.hovered ? "#909090" : "#c0c0c0"
                }
            }
            
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                visible: logListView.contentWidth > logListView.width
                
                contentItem: Rectangle {
                    implicitHeight: 8
                    radius: height / 2
                    color: parent.pressed ? "#606060" :
                           parent.hovered ? "#909090" : "#c0c0c0"
                }
            }
        }
    }
    
    // 底部按钮区域
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: settingsStyle.defaultSpacing
        Layout.bottomMargin: 8
        spacing: 8
        
        Item { Layout.fillWidth: true }
        
        Button {
            id: clearButton
            text: qsTr("清除日志")
            icon.source: "qrc:/resources/images/clear.svg"
            icon.width: 14
            icon.height: 14
            padding: 6
            
            background: Rectangle {
                implicitWidth: settingsStyle.defaultButtonWidth + 20
                implicitHeight: settingsStyle.defaultButtonHeight
                color: clearButton.pressed ? settingsStyle.defaultButtonPressedColor :
                       clearButton.hovered ? settingsStyle.defaultButtonHoverColor :
                       settingsStyle.defaultButtonNormalColor
                border.color: clearButton.pressed ? settingsStyle.defaultButtonPressedBorderColor :
                            clearButton.hovered ? settingsStyle.defaultButtonHoverBorderColor :
                            settingsStyle.defaultButtonNormalBorderColor
                border.width: 1
                radius: settingsStyle.defaultRadius
            }
            
            contentItem: RowLayout {
                spacing: 4
                Image {
                    source: clearButton.icon.source
                    sourceSize.width: clearButton.icon.width
                    sourceSize.height: clearButton.icon.height
                    Layout.alignment: Qt.AlignVCenter
                }
                Label {
                    text: clearButton.text
                    font {
                        family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                    color: style?.textColor ?? settingsStyle.defaultTextColor
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            onClicked: fileManager.clearLogs()
        }
    }
} 