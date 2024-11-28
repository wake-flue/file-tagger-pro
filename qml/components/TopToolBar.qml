import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0
import "../utils" as Utils
import ".." 1.0

Rectangle {
    id: root
    color: Style.backgroundColor
    border.color: Style.borderColor
    border.width: 1
    radius: 4
    height: 40

    // 必要的属性声明
    required property QtObject settings
    required property QtObject fileManager
    required property QtObject folderDialog
    required property QtObject settingsWindow

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 8
            topMargin: 4
            bottomMargin: 4
        }
        spacing: 8

        // 左侧按钮组
        Row {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Button {
                id: selectFolderButton
                text: "选择目录"
                icon.source: "qrc:/resources/images/folder.svg"
                icon.width: 14
                icon.height: 14
                padding: 6
                
                background: Rectangle {
                    implicitWidth: 90
                    implicitHeight: 28
                    color: selectFolderButton.down ? Qt.darker(Style.backgroundColor, 1.1) : 
                           selectFolderButton.hovered ? Style.hoverColor : Style.backgroundColor
                    border.color: selectFolderButton.down ? Style.accentColor : 
                                selectFolderButton.hovered ? Style.accentColor : Style.borderColor
                    border.width: 1
                    radius: 3
                    
                    Behavior on color {
                        ColorAnimation { duration: 50 }
                    }
                }
                
                contentItem: RowLayout {
                    spacing: 4
                    Image {
                        source: selectFolderButton.icon.source
                        sourceSize.width: 14
                        sourceSize.height: 14
                        width: selectFolderButton.icon.width
                        height: selectFolderButton.icon.height
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: selectFolderButton.text
                        color: Style.textColor
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeNormal - 1
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                onClicked: root.folderDialog.open()
            }

            Button {
                id: refreshButton
                icon.source: "qrc:/resources/images/refresh.svg"
                icon.width: 14
                icon.height: 14
                padding: 6
                
                background: Rectangle {
                    implicitWidth: 24
                    implicitHeight: 28
                    color: refreshButton.down ? Qt.darker(Style.backgroundColor, 1.1) : 
                           refreshButton.hovered ? Style.hoverColor : Style.backgroundColor
                    border.color: refreshButton.down ? Style.accentColor : 
                                refreshButton.hovered ? Style.accentColor : Style.borderColor
                    border.width: 1
                    radius: 3
                    
                    Behavior on color {
                        ColorAnimation { duration: 50 }
                    }
                }
                
                contentItem: RowLayout {
                    spacing: 4
                    Image {
                        source: refreshButton.icon.source
                        sourceSize.width: 14
                        sourceSize.height: 14
                        width: refreshButton.icon.width
                        height: refreshButton.icon.height
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                onClicked: {
                    Utils.Logger.logOperation(fileManager, "手动刷新目录", "")
                    if (fileManager.currentPath) {
                        fileManager.scanDirectory(fileManager.currentPath)
                    }
                }
            }
        }

        // 添加弹性空间
        Item {
            Layout.fillWidth: true
        }

        // 添加搜索框
        Rectangle {
            Layout.preferredWidth: 200
            Layout.preferredHeight: 28
            Layout.alignment: Qt.AlignVCenter
            color: "#f5f5f5"
            radius: 3
            border.color: searchInput.activeFocus ? Style.accentColor : Style.borderColor
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4

                Image {
                    source: "qrc:/resources/images/search.svg"
                    sourceSize.width: 14
                    sourceSize.height: 14
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "搜索文件..."
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal - 1
                    color: Style.textColor
                    selectByMouse: true
                    background: null

                    // 添加防抖动定时器
                    Timer {
                        id: searchDebounceTimer
                        interval: 300
                        onTriggered: {
                            if (root.fileManager && root.fileManager.fileModel) {
                                root.fileManager.fileModel.searchPattern = searchInput.text
                            }
                        }
                    }

                    onTextChanged: {
                        searchDebounceTimer.restart()
                    }

                    // 清除按钮
                    Image {
                        visible: parent.text !== ""
                        source: "qrc:/resources/images/clear.svg"
                        sourceSize.width: 12
                        sourceSize.height: 12
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            rightMargin: 4
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchInput.clear()
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }

        // 右侧按钮组
        Row {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

            // 添加设置按钮
            Button {
                id: settingsButton
                icon.source: "qrc:/resources/images/setting.svg"
                icon.width: 14
                icon.height: 14
                padding: 0
                
                background: Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    color: settingsButton.down ? Qt.darker(Style.backgroundColor, 1.1) : 
                           settingsButton.hovered ? Style.hoverColor : Style.backgroundColor
                    border.color: settingsButton.down ? Style.accentColor : 
                                settingsButton.hovered ? Style.accentColor : Style.borderColor
                    border.width: 1
                    radius: 3
                }
                
                contentItem: Item {
                    implicitWidth: settingsButton.background.implicitWidth
                    implicitHeight: settingsButton.background.implicitHeight
                    
                    Image {
                        source: settingsButton.icon.source
                        sourceSize.width: settingsButton.icon.width
                        sourceSize.height: settingsButton.icon.height
                        width: settingsButton.icon.width
                        height: settingsButton.icon.height
                        anchors.centerIn: parent
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 100 }
                        }
                    }
                }
                
                ToolTip {
                    visible: settingsButton.hovered
                    text: "设置"
                    delay: 500
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal - 1
                }
                
                onClicked: root.settingsWindow.show()
            }

            // 列表视图按钮
            Button {
                id: listViewButton
                icon.source: "qrc:/resources/images/list.svg"
                icon.width: 14
                icon.height: 14
                padding: 0
                
                background: Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    color: root.fileManager.fileModel.viewMode === FileListModel.ListView ? 
                           Qt.darker(Style.backgroundColor, 1.1) : 
                           (listViewButton.hovered ? Style.hoverColor : Style.backgroundColor)
                    border.color: root.fileManager.fileModel.viewMode === FileListModel.ListView ? 
                                 Style.accentColor : 
                                 (listViewButton.hovered ? Style.accentColor : Style.borderColor)
                    border.width: 1
                    radius: 3
                }
                
                onClicked: root.fileManager.fileModel.viewMode = FileListModel.ListView
                
                ToolTip {
                    visible: parent.hovered
                    text: "列表视图"
                    delay: 500
                }
            }
            
            // 大图标视图按钮
            Button {
                id: largeIconViewButton
                icon.source: "qrc:/resources/images/large-icons.svg"
                icon.width: 14
                icon.height: 14
                padding: 0
                
                background: Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    color: root.fileManager.fileModel.viewMode === FileListModel.LargeIconView ? 
                           Qt.darker(Style.backgroundColor, 1.1) : 
                           (largeIconViewButton.hovered ? Style.hoverColor : Style.backgroundColor)
                    border.color: root.fileManager.fileModel.viewMode === FileListModel.LargeIconView ? 
                                 Style.accentColor : 
                                 (largeIconViewButton.hovered ? Style.accentColor : Style.borderColor)
                    border.width: 1
                    radius: 3
                }
                
                onClicked: root.fileManager.fileModel.viewMode = FileListModel.LargeIconView
                
                ToolTip {
                    visible: parent.hovered
                    text: "大图标视图"
                    delay: 500
                }
            }
        }
    }
} 