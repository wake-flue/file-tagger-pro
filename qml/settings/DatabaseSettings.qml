import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    required property QtObject style
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 标题
    Label {
        text: qsTr("数据库管理")
        font {
            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
            bold: true
        }
        color: style?.textColor ?? settingsStyle.defaultTextColor
    }
    
    // 说明文本
    Label {
        text: qsTr("查看和管理数据库中的标签、统计信息和最近文件")
        font {
            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
        }
        color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
        opacity: settingsStyle.defaultOpacity
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
    
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        Button {
            text: qsTr("备份数据库")
            icon.source: "qrc:/resources/images/backup.svg"
            icon.width: 14
            icon.height: 14
            padding: 6
            
            background: Rectangle {
                implicitWidth: 100
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
            
            contentItem: RowLayout {
                spacing: 4
                Image {
                    source: parent.parent.icon.source
                    sourceSize.width: parent.parent.icon.width
                    sourceSize.height: parent.parent.icon.height
                    Layout.alignment: Qt.AlignVCenter
                }
                Label {
                    text: parent.parent.text
                    font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    color: style?.textColor ?? settingsStyle.defaultTextColor
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            onClicked: {
                // TODO: 实现数据库备份功能
            }
        }
        
        Button {
            text: qsTr("恢复数据库")
            icon.source: "qrc:/resources/images/restore.svg"
            icon.width: 14
            icon.height: 14
            padding: 6
            
            background: Rectangle {
                implicitWidth: 100
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
            
            contentItem: RowLayout {
                spacing: 4
                Image {
                    source: parent.parent.icon.source
                    sourceSize.width: parent.parent.icon.width
                    sourceSize.height: parent.parent.icon.height
                    Layout.alignment: Qt.AlignVCenter
                }
                Label {
                    text: parent.parent.text
                    font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    color: style?.textColor ?? settingsStyle.defaultTextColor
                    Layout.alignment: Qt.AlignVCenter
                }
            }
            
            onClicked: {
                // TODO: 实现数据库恢复功能
            }
        }
        
        Item { Layout.fillWidth: true }
    }
    
    TabBar {
        id: tabBar
        Layout.fillWidth: true
        
        background: Rectangle {
            color: "transparent"
            border {
                width: 1
                color: style?.borderColor ?? settingsStyle.defaultBorderColor
            }
        }
        
        TabButton {
            text: qsTr("标签")
            font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
            
            background: Rectangle {
                color: parent.checked ? (style?.selectedColor ?? "#E5F3FF") :
                       parent.hovered ? (style?.hoverColor ?? "#F0F0F0") : "transparent"
                border.width: 0
            }
        }
        TabButton {
            text: qsTr("统计")
            font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
            
            background: Rectangle {
                color: parent.checked ? (style?.selectedColor ?? "#E5F3FF") :
                       parent.hovered ? (style?.hoverColor ?? "#F0F0F0") : "transparent"
                border.width: 0
            }
        }
        TabButton {
            text: qsTr("最近文件")
            font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
            
            background: Rectangle {
                color: parent.checked ? (style?.selectedColor ?? "#E5F3FF") :
                       parent.hovered ? (style?.hoverColor ?? "#F0F0F0") : "transparent"
                border.width: 0
            }
        }
    }
    
    StackLayout {
        currentIndex: tabBar.currentIndex
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        // 标签表视图
        ListView {
            model: TagManager.getAllTags()
            delegate: ItemDelegate {
                width: parent.width
                contentItem: RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: modelData.color
                    }
                    Label {
                        text: modelData.name
                        Layout.fillWidth: true
                        font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                    Label {
                        text: modelData.description || "-"
                        opacity: 0.7
                        font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                    
                    ToolButton {
                        icon.source: "qrc:/resources/images/tag-edit.svg"
                        icon.width: 14
                        icon.height: 14
                        onClicked: {
                            // TODO: 打开标签编辑对话框
                        }
                    }
                    
                    ToolButton {
                        icon.source: "qrc:/resources/images/remove.svg"
                        icon.width: 14
                        icon.height: 14
                        onClicked: {
                            // TODO: 删除标签确认对话框
                        }
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {}
        }
        
        // 统计视图
        ListView {
            model: TagManager.getTagStats()
            delegate: ItemDelegate {
                width: parent.width
                contentItem: RowLayout {
                    Label {
                        text: Array.isArray(modelData) && modelData.length > 0 ? 
                              String(modelData[0] || "") : ""
                        Layout.fillWidth: true
                        font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                    Label {
                        text: Array.isArray(modelData) && modelData.length > 1 ? 
                              String(modelData[1] || "") : ""
                        opacity: 0.7
                        font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {}
        }
        
        // 最近文件视图
        ListView {
            model: TagManager.getRecentFiles(10)
            delegate: ItemDelegate {
                width: parent.width
                contentItem: Label {
                    text: modelData
                    elide: Text.ElideMiddle
                    font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
            }
            
            ScrollBar.vertical: ScrollBar {}
        }
    }
} 