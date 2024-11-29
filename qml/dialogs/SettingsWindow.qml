import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0
import "../settings" as Settings
import ".." 1.0

Window {
    id: root
    title: qsTr("设置")
    width: 800
    height: 600
    minimumWidth: 600
    minimumHeight: 400
    
    required property QtObject settings
    required property var fileManager
    
    color: Style.backgroundColor
    
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
            border.color: Style.borderColor
            
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
                    width: 200
                    height: 40
                    
                    background: Rectangle {
                        color: settingsList.currentIndex === index ? 
                               (Style.selectedColor || "#E5F3FF") : "transparent"
                        
                        Rectangle {
                            width: 3
                            height: parent.height
                            color: Style.accentColor
                            visible: settingsList.currentIndex === index
                        }
                    }
                    
                    contentItem: Label {
                        text: name
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeNormal
                        color: Style.textColor
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
            color: Style.backgroundColor
            
            StackLayout {
                anchors {
                    fill: parent
                    margins: 20
                }
                currentIndex: settingsList.currentIndex
                
                // 常规设置
                Item {
                    Settings.GeneralSettings {
                        anchors.fill: parent
                        settings: root.settings
                        fileManager: root.fileManager
                    }
                }
                
                // 播放器设置（复用现有的播放器设置组件）
                Item {
                    id: playerSettingsContainer
                    
                    Settings.PlayerSettings {
                        anchors.fill: parent
                        settings: root.settings
                    }
                }
                
                // 文件类型设置
                Item {
                    Settings.FileTypeSettings {
                        anchors.fill: parent
                        settings: root.settings
                        fileManager: root.fileManager
                    }
                }
                
                // 标签设置
                Item {
                    Settings.TagSettings {
                        anchors.fill: parent
                        settings: root.settings
                    }
                }
                
                // 数据库设置
                Item {
                    Settings.DatabaseSettings {
                        anchors.fill: parent
                        settings: root.settings
                    }
                }
                
                // 日志设置
                Item {
                    Settings.LogSettings {
                        anchors.fill: parent
                        settings: root.settings
                        fileManager: root.fileManager
                    }
                }
            }
        }
    }
} 