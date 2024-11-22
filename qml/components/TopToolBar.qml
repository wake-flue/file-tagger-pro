import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

Rectangle {
    id: root
    color: style.backgroundColor
    border.color: style.borderColor
    border.width: 1
    radius: 4
    height: 40  // 减小高度

    // 必要的属性声明
    required property QtObject style
    required property QtObject settings
    required property QtObject fileManager
    required property QtObject folderDialog
    required property QtObject settingsWindow

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 8  // 减小边距
            rightMargin: 8
            topMargin: 4   // 减小边距
            bottomMargin: 4
        }
        spacing: 8  // 减小间距

        // 左侧按钮组
        Row {
            spacing: 4  // 减小按钮间距
            Layout.alignment: Qt.AlignVCenter

            Button {
                id: selectFolderButton
                text: "选择目录"
                icon.source: "qrc:/resources/images/folder.svg"
                icon.width: 14  // 减小图标
                icon.height: 14
                padding: 6     // 减小内边距
                
                background: Rectangle {
                    implicitWidth: 90  // 减小按钮宽度
                    implicitHeight: 28 // 减小按钮高度
                    color: selectFolderButton.down ? Qt.darker(root.style.backgroundColor, 1.1) : 
                           selectFolderButton.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: selectFolderButton.down ? root.style.accentColor : 
                                selectFolderButton.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 3
                    
                    Behavior on color {
                        ColorAnimation { duration: 50 }
                    }
                }
                
                contentItem: RowLayout {
                    spacing: 4  // 减小图标和文字间距
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
                        color: root.style.textColor
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize - 1  // 减小字体
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                onClicked: root.folderDialog.open()
            }

            Button {
                id: refreshButton
                text: "刷新"
                icon.source: "qrc:/resources/images/refresh.svg"
                icon.width: 14
                icon.height: 14
                padding: 6
                
                background: Rectangle {
                    implicitWidth: 70  // 减小按钮宽度
                    implicitHeight: 28
                    color: refreshButton.down ? Qt.darker(root.style.backgroundColor, 1.1) : 
                           refreshButton.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: refreshButton.down ? root.style.accentColor : 
                                refreshButton.hovered ? root.style.accentColor : root.style.borderColor
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
                    Text {
                        text: refreshButton.text
                        color: root.style.textColor
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize - 1
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                onClicked: {
                    if (root.fileManager.currentPath) {
                        // 清除现有的预览缓存
                        if (root.fileManager.fileModel) {
                            root.fileManager.fileModel.clearPreviews()  // 需要在 FileListModel 中添加此方法
                        }
                        
                        // 使用当前的过滤器设置重新扫描
                        let currentFilter = root.settings.fileFilter
                        let filters = currentFilter ? currentFilter.split(';') : []
                        root.fileManager.scanDirectory(root.fileManager.currentPath, filters)
                    }
                }
            }
        }

        // 中间路径显示
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            Layout.rightMargin: 8  // 添加右边距
            color: "#f5f5f5"
            radius: 3
            border.color: root.style.borderColor
            border.width: 1
            
            Text {
                anchors {
                    fill: parent
                    leftMargin: 8
                    rightMargin: 8
                }
                text: root.fileManager.currentPath || "未选择目录"
                elide: Text.ElideMiddle
                font.family: root.style.fontFamily
                font.pixelSize: root.style.defaultFontSize - 1
                color: root.style.textColor
                verticalAlignment: Text.AlignVCenter
            }
        }

        // 添加搜索框
        Rectangle {
            Layout.preferredWidth: 200
            Layout.preferredHeight: 28
            Layout.rightMargin: 8
            color: "#f5f5f5"
            radius: 3
            border.color: searchInput.activeFocus ? root.style.accentColor : root.style.borderColor
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
                    font.family: root.style.fontFamily
                    font.pixelSize: root.style.defaultFontSize - 1
                    color: root.style.textColor
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
            Layout.alignment: Qt.AlignVCenter

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
                    color: settingsButton.down ? Qt.darker(root.style.backgroundColor, 1.1) : 
                           settingsButton.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: settingsButton.down ? root.style.accentColor : 
                                settingsButton.hovered ? root.style.accentColor : root.style.borderColor
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
                    font.family: root.style.fontFamily
                    font.pixelSize: root.style.defaultFontSize - 1
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
                           Qt.darker(root.style.backgroundColor, 1.1) : 
                           (listViewButton.hovered ? root.style.hoverColor : root.style.backgroundColor)
                    border.color: root.fileManager.fileModel.viewMode === FileListModel.ListView ? 
                                 root.style.accentColor : 
                                 (listViewButton.hovered ? root.style.accentColor : root.style.borderColor)
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
                           Qt.darker(root.style.backgroundColor, 1.1) : 
                           (largeIconViewButton.hovered ? root.style.hoverColor : root.style.backgroundColor)
                    border.color: root.fileManager.fileModel.viewMode === FileListModel.LargeIconView ? 
                                 root.style.accentColor : 
                                 (largeIconViewButton.hovered ? root.style.accentColor : root.style.borderColor)
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