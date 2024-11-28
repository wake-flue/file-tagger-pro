import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 标题和说明
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        Label {
            text: qsTr("数据库管理")
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.titleFontSize
                bold: true
            }
            color: settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("查看和管理数据库中的标签、统计信息和最近文件")
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
    
    // 工具栏
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: settingsStyle.defaultItemSpacing
        spacing: 8
        
        Button {
            text: qsTr("备份数据库")
            icon.source: "qrc:/resources/images/backup.svg"
            icon.width: 14
            icon.height: 14
            
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
                }
                Label {
                    text: parent.parent.text
                    font.family: settingsStyle.defaultFontFamily
                    font.pixelSize: settingsStyle.defaultFontSize
                    color: settingsStyle.defaultTextColor
                }
            }
        }
        
        Button {
            text: qsTr("恢复数据库")
            icon.source: "qrc:/resources/images/restore.svg"
            icon.width: 14
            icon.height: 14
            
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
                }
                Label {
                    text: parent.parent.text
                    font.family: settingsStyle.defaultFontFamily
                    font.pixelSize: settingsStyle.defaultFontSize
                    color: settingsStyle.defaultTextColor
                }
            }
        }
        
        Item { Layout.fillWidth: true }
    }
    
    // 标签页
    TabBar {
        id: tabBar
        Layout.fillWidth: true
        Layout.topMargin: settingsStyle.defaultSpacing
        
        background: Rectangle {
            color: "transparent"
            border.width: 0
        }
        
        TabButton {
            text: qsTr("标签")
            font.family: settingsStyle.defaultFontFamily
            font.pixelSize: settingsStyle.defaultFontSize
            
            background: Rectangle {
                color: parent.checked ? settingsStyle.defaultListItemSelectedColor :
                       parent.hovered ? settingsStyle.defaultListItemHoverColor : 
                       "transparent"
            }
        }
        
        TabButton {
            text: qsTr("统计")
            font.family: settingsStyle.defaultFontFamily
            font.pixelSize: settingsStyle.defaultFontSize
            
            background: Rectangle {
                color: parent.checked ? settingsStyle.defaultListItemSelectedColor :
                       parent.hovered ? settingsStyle.defaultListItemHoverColor : 
                       "transparent"
            }
        }
        
        TabButton {
            text: qsTr("最近文件")
            font.family: settingsStyle.defaultFontFamily
            font.pixelSize: settingsStyle.defaultFontSize
            
            background: Rectangle {
                color: parent.checked ? settingsStyle.defaultListItemSelectedColor :
                       parent.hovered ? settingsStyle.defaultListItemHoverColor : 
                       "transparent"
            }
        }
    }
    
    // 内容区域
    StackLayout {
        currentIndex: tabBar.currentIndex
        Layout.fillWidth: true
        Layout.fillHeight: true
        
        // 标签列表
        ListView {
            model: TagManager.getAllTags()
            clip: true
            
            delegate: ItemDelegate {
                width: parent.width
                height: 48
                
                background: Rectangle {
                    color: parent.hovered ? settingsStyle.defaultListItemHoverColor : 
                           "transparent"
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: modelData.color
                    }
                    
                    Label {
                        text: modelData.name
                        font.family: settingsStyle.defaultFontFamily
                        font.pixelSize: settingsStyle.defaultFontSize
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: modelData.description || "-"
                        font.family: settingsStyle.defaultFontFamily
                        font.pixelSize: settingsStyle.defaultFontSize
                        opacity: settingsStyle.defaultOpacity
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
        
        // 统计视图
        ListView {
            model: TagManager.getTagStats()
            clip: true
            
            delegate: ItemDelegate {
                width: parent.width
                height: 48
                
                background: Rectangle {
                    color: parent.hovered ? settingsStyle.defaultListItemHoverColor : 
                           "transparent"
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Label {
                        text: Array.isArray(modelData) && modelData.length > 0 ? 
                              String(modelData[0] || "") : ""
                        font.family: settingsStyle.defaultFontFamily
                        font.pixelSize: settingsStyle.defaultFontSize
                        Layout.fillWidth: true
                    }
                    
                    Label {
                        text: Array.isArray(modelData) && modelData.length > 1 ? 
                              String(modelData[1] || "") : ""
                        font.family: settingsStyle.defaultFontFamily
                        font.pixelSize: settingsStyle.defaultFontSize
                        opacity: settingsStyle.defaultOpacity
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
        
        // 最近文件视图
        ListView {
            model: TagManager.getRecentFiles(10)
            clip: true
            
            delegate: ItemDelegate {
                width: parent.width
                height: 48
                
                background: Rectangle {
                    color: parent.hovered ? settingsStyle.defaultListItemHoverColor : 
                           "transparent"
                }
                
                Label {
                    anchors.fill: parent
                    anchors.margins: 8
                    text: modelData
                    elide: Text.ElideMiddle
                    font.family: settingsStyle.defaultFontFamily
                    font.pixelSize: settingsStyle.defaultFontSize
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }
} 