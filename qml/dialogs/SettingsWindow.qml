import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0
import "../settings" as Settings

Window {
    id: root
    title: qsTr("设置")
    width: 800
    height: 600
    minimumWidth: 600
    minimumHeight: 400
    
    required property QtObject style
    required property QtObject settings
    required property var fileManager
    
    color: style.backgroundColor
    
    // 添加当前页面索引属性
    property alias currentIndex: settingsList.currentIndex
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // 左侧设置项列表
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "#f5f5f5"
            border.width: 0
            border.color: style.borderColor
            
            ListView {
                id: settingsList
                anchors.fill: parent
                currentIndex: 0
                model: ListModel {
                    ListElement { name: "常规" }
                    ListElement { name: "播放器" }
                    ListElement { name: "文件类型" }
                    ListElement { name: "标签" }
                    ListElement { name: "数据库" }
                    ListElement { name: "日志" }
                }
                
                delegate: ItemDelegate {
                    width: parent.width
                    height: 40
                    
                    background: Rectangle {
                        color: settingsList.currentIndex === index ? 
                               (style?.selectedColor || "#E5F3FF") : "transparent"
                        
                        Rectangle {
                            width: 3
                            height: parent.height
                            color: style?.accentColor || "#0078D4"
                            visible: settingsList.currentIndex === index
                        }
                    }
                    
                    contentItem: Label {
                        text: name
                        font.family: style?.fontFamily || "Microsoft YaHei"
                        font.pixelSize: style?.defaultFontSize || 12
                        color: style?.textColor || "#202020"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 16
                    }
                    
                    onClicked: settingsList.currentIndex = index
                }
            }
        }
        
        // 右侧设置详情
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: style?.backgroundColor || "#ffffff"
            
            StackLayout {
                anchors {
                    fill: parent
                    margins: 20
                }
                currentIndex: settingsList.currentIndex
                
                // 常规设置
                ColumnLayout {
                    spacing: 16
                    
                    Label {
                        text: qsTr("常规设置")
                        font {
                            family: style?.fontFamily || "Microsoft YaHei"
                            pixelSize: (style?.defaultFontSize || 12) + 2
                            bold: true
                        }
                        color: style?.textColor || "#202020"
                    }
                    
                    // 添加常规设置项
                }
                
                // 播放器设置（复用现有的播放器设置组件）
                Item {
                    id: playerSettingsContainer
                    
                    Settings.PlayerSettings {
                        anchors.fill: parent
                        settings: root.settings
                        style: root.style
                    }
                }
                
                // 文件类型设置
                Item {
                    Settings.FileTypeSettings {
                        anchors.fill: parent
                        settings: root.settings
                        style: root.style
                        fileManager: root.fileManager
                    }
                }
                
                // 标签设置
                Item {
                    // TODO: 添加标签设置内容
                }
                
                // 数据库设置
                Item {
                    Settings.DatabaseSettings {
                        anchors.fill: parent
                        settings: root.settings
                        style: root.style
                    }
                }
                
                // 日志设置
                Item {
                    Settings.LogSettings {
                        anchors.fill: parent
                        settings: root.settings
                        style: root.style
                        fileManager: root.fileManager
                    }
                }
            }
        }
    }
} 