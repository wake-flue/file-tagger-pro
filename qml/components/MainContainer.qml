import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import Qt.labs.platform
import FileManager 1.0
import "." as Components
import ".." 1.0

Item {
    id: root
    
    // 必要的属性声明
    required property QtObject settings
    required property QtObject fileManager
    
    // 内部属性
    property bool showFileList: true
    property bool showDetailPanel: false
    property var selectedItem: null
    property bool showSidebar: true
    
    // 暴露fileList接口
    property alias fileList: fileList
    
    // 信号声明
    signal fileListVisibilityChanged(bool visible)
    signal detailPanelVisibilityChanged(bool visible)
    signal sidebarVisibilityChanged(bool visible)
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Style.spacingSmall

        // 主内容区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Style.backgroundColor
            border.width: Style.noneBorderWidth

            SplitView {
                id: mainSplitView
                anchors.fill: parent
                anchors.margins: Style.spacingSmall
                orientation: Qt.Horizontal
                handle: Rectangle {
                    implicitWidth: 4
                    color: "transparent"
                }

                // 左侧边栏
                Rectangle {
                    id: sidebar
                    implicitWidth: 200
                    SplitView.minimumWidth: 100
                    SplitView.maximumWidth: 300
                    color: Style.backgroundColor
                    visible: root.showSidebar
                    border.color: Style.borderColor
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.spacingSmall
                        spacing: Style.spacingSmall
                        
                        Components.FileTree {
                            id: fileTree
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            fileSystemManager: root.fileManager
                        }
                    }
                }

                // 主要内容区域
                Rectangle {
                    id: mainContent
                    SplitView.fillWidth: true
                    color: Style.backgroundColor

                    // 使用 Item 替代 Row
                    Item {
                        anchors.fill: parent

                        // 左侧文件表
                        Components.FileList {
                            id: fileList
                            width: detailPanel.visible ? parent.width * splitter.position : parent.width
                            height: parent.height
                            visible: root.showFileList
                            clip: true
                            
                            model: fileManager.fileModel
                            fileManager: root.fileManager
                            
                            onSelectedItemChanged: {
                                root.selectedItem = selectedItem
                            }
                        }

                        // 分割线
                        Components.Splitter {
                            id: splitter
                            height: parent.height
                            position: 0.7  // 初始位置设为70%
                            minimumPosition: 0.3  // 最小30%
                            maximumPosition: 0.8  // 最大80%
                            panelVisible: detailPanel.visible
                            x: fileList.width
                            visible: root.showFileList && root.showDetailPanel
                            
                            Connections {
                                target: splitter
                                function onPositionChanged() {
                                    fileList.width = parent.width * splitter.position
                                }
                            }
                        }

                        // 右侧详情面板
                        Components.DetailPanel {
                            id: detailPanel
                            x: splitter.x + splitter.width
                            width: visible ? parent.width - x : 0
                            height: parent.height
                            visible: root.showDetailPanel
                            clip: true
                            
                            settings: root.settings
                            selectedItem: root.selectedItem
                            isVisible: root.showDetailPanel
                            
                            // 添加阴影效果
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: "#40000000"
                                shadowBlur: 1.0
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 1
                            }
                        }

                        // 右侧触发器
                        Rectangle {
                            id: rightTrigger
                            width: 32
                            height: 32
                            radius: width / 2
                            color: rightTriggerArea.containsMouse ? Style.hoverColor : Style.backgroundColor
                            border.color: Style.borderColor
                            border.width: 1
                            z: 1
                            
                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                                margins: 16
                            }
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: "#40000000"
                                shadowBlur: 1.0
                                shadowHorizontalOffset: 0
                                shadowVerticalOffset: 1
                            }
                            
                            Item {
                                anchors.centerIn: parent
                                width: 16
                                height: 16

                                Image {
                                    id: leftArrowIcon
                                    anchors.fill: parent
                                    source: "qrc:/resources/images/chevron-left.svg"
                                    opacity: !detailPanel.visible ? (rightTriggerArea.containsMouse ? 0.9 : 0.7) : 0
                                }

                                Image {
                                    id: rightArrowIcon
                                    anchors.fill: parent
                                    source: "qrc:/resources/images/chevron-right.svg"
                                    opacity: detailPanel.visible ? (rightTriggerArea.containsMouse ? 0.9 : 0.7) : 0
                                }
                            }
                            
                            MouseArea {
                                id: rightTriggerArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.showDetailPanel = !root.showDetailPanel
                                    root.detailPanelVisibilityChanged(root.showDetailPanel)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 切换显示/隐藏方法
    function toggleFileList() {
        root.showFileList = !root.showFileList
        fileListVisibilityChanged(root.showFileList)
    }
    
    function toggleDetailPanel() {
        root.showDetailPanel = !root.showDetailPanel
        detailPanelVisibilityChanged(root.showDetailPanel)
    }

    function toggleSidebar() {
        root.showSidebar = !root.showSidebar
        sidebarVisibilityChanged(root.showSidebar)
    }
} 