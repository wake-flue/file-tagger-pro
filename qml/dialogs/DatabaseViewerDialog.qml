import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

Dialog {
    id: root
    title: "数据库查看器"
    width: 600
    height: 400
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {
                text: "标签"
            }
            TabButton {
                text: "统计"
            }
            TabButton {
                text: "最近文件"
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
                        }
                        Label {
                            text: modelData.description || "-"
                            opacity: 0.7
                        }
                    }
                }
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
                        }
                        Label {
                            text: Array.isArray(modelData) && modelData.length > 1 ? 
                                  String(modelData[1] || "") : ""
                            opacity: 0.7
                        }
                    }
                }
            }
            
            // 最近文件视图
            ListView {
                model: TagManager.getRecentFiles(10)
                delegate: ItemDelegate {
                    width: parent.width
                    contentItem: Label {
                        text: modelData
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }
} 