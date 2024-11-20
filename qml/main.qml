import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic  // 添加 Basic 样式
import QtQuick.Layouts
import FileManager 1.0
import "components" as Components  // 修改导入路径
import "dialogs" as Dialogs

Window {
    width: 800
    height: 600
    visible: true
    title: qsTr("文件标签应用")

    // 添加全局字体和颜色定义
    QtObject {
        id: style
        readonly property color accentColor: "#0078D4"  // Windows 10/11 主题色
        readonly property color backgroundColor: "#FFFFFF"
        readonly property color borderColor: "#E5E5E5"
        readonly property color textColor: "#202020"
        readonly property color secondaryTextColor: "#666666"
        readonly property color hoverColor: "#F0F0F0"
        readonly property color selectedColor: "#E5F3FF"
        readonly property int defaultFontSize: 12
        readonly property string fontFamily: {
            // 根据系统选择合适的字体
            switch (Qt.platform.os) {
                case "windows":
                    return "Microsoft YaHei"
                case "osx":
                    return "PingFang SC"
                default:
                    return "Sans-serif"
            }
        }
    }

    FileSystemManager {
        id: fileManager
        
        // 删除 onFileListChanged 处理器，因为现在由 C++ 模型直接处理
        
        onFileChanged: function(path) {
            console.log("检测到文件变更:", path)
            fileManager.scanDirectory(fileManager.currentPath, ["*.txt", "*.jpg", "*.png"])
        }
        
        onDirectoryChanged: function(path) {
            console.log("检测到目录变更:", path)
            fileManager.scanDirectory(fileManager.currentPath, ["*.txt", "*.jpg", "*.png"])
        }
    }

    Dialogs.FolderPickerDialog {
        id: folderDialog
        onFolderSelected: function(path) {
            fileManager.setWatchPath(path)
            let currentFilter = settings.value("fileFilter", "")
            let filters = currentFilter ? currentFilter.split(';') : []
            fileManager.scanDirectory(path, filters)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // 顶部功能栏
        Rectangle {
            Layout.fillWidth: true
            height: 40  // 减小高度
            color: style.backgroundColor
            border.color: style.borderColor
            border.width: 1
            radius: 4

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
                            color: selectFolderButton.down ? Qt.darker(style.backgroundColor, 1.1) : 
                                   selectFolderButton.hovered ? style.hoverColor : style.backgroundColor
                            border.color: selectFolderButton.down ? style.accentColor : 
                                        selectFolderButton.hovered ? style.accentColor : style.borderColor
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
                                color: style.textColor
                                font.family: style.fontFamily
                                font.pixelSize: style.defaultFontSize - 1  // 减小字体
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        
                        onClicked: folderDialog.open()
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
                            color: refreshButton.down ? Qt.darker(style.backgroundColor, 1.1) : 
                                   refreshButton.hovered ? style.hoverColor : style.backgroundColor
                            border.color: refreshButton.down ? style.accentColor : 
                                        refreshButton.hovered ? style.accentColor : style.borderColor
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
                                color: style.textColor
                                font.family: style.fontFamily
                                font.pixelSize: style.defaultFontSize - 1
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        
                        onClicked: {
                            if (fileManager.currentPath) {
                                let currentFilter = settings.value("fileFilter", "")
                                let filters = currentFilter ? currentFilter.split(';') : []
                                fileManager.scanDirectory(fileManager.currentPath, filters)
                            }
                        }
                    }
                }

                // 中间路径显示
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28  // 减小高度
                    color: "#f5f5f5"
                    radius: 3
                    border.color: style.borderColor
                    border.width: 1
                    
                    Text {
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 8
                        }
                        text: fileManager.currentPath || "未选择目录"
                        elide: Text.ElideMiddle
                        font.family: style.fontFamily
                        font.pixelSize: style.defaultFontSize - 1
                        color: style.textColor
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // 右侧按钮组
                Row {
                    spacing: 4
                    Layout.alignment: Qt.AlignVCenter

                    // 筛选按钮
                    Button {
                        id: filterButton
                        icon.source: "qrc:/resources/images/filter.svg"
                        icon.width: 14
                        icon.height: 14
                        padding: 0
                        
                        background: Rectangle {
                            implicitWidth: 32  // 减小宽度，只显示图标
                            implicitHeight: 28
                            color: filterButton.down ? Qt.darker(style.backgroundColor, 1.1) : 
                                   filterButton.hovered ? style.hoverColor : style.backgroundColor
                            border.color: filterButton.down ? style.accentColor : 
                                        filterButton.hovered ? style.accentColor : style.borderColor
                            border.width: 1
                            radius: 3
                        }
                        
                        contentItem: Image {
                            source: filterButton.icon.source
                            sourceSize.width: 14
                            sourceSize.height: 14
                            width: filterButton.icon.width
                            height: filterButton.icon.height
                            anchors.centerIn: parent
                        }
                        
                        ToolTip {
                            visible: filterButton.hovered
                            text: "筛选"
                            delay: 500
                            font.family: style.fontFamily
                            font.pixelSize: style.defaultFontSize - 1
                        }
                        
                        onClicked: filterDialog.open()
                    }

                    // 播放器设置按钮
                    Button {
                        id: playerSettingsButton
                        icon.source: "qrc:/resources/images/player.svg"
                        icon.width: 14
                        icon.height: 14
                        padding: 0
                        
                        background: Rectangle {
                            implicitWidth: 32  // 减小宽度，只显示图标
                            implicitHeight: 28
                            color: playerSettingsButton.down ? Qt.darker(style.backgroundColor, 1.1) : 
                                   playerSettingsButton.hovered ? style.hoverColor : style.backgroundColor
                            border.color: playerSettingsButton.down ? style.accentColor : 
                                        playerSettingsButton.hovered ? style.accentColor : style.borderColor
                            border.width: 1
                            radius: 3
                        }
                        
                        contentItem: Image {
                            source: playerSettingsButton.icon.source
                            sourceSize.width: 14
                            sourceSize.height: 14
                            width: playerSettingsButton.icon.width
                            height: playerSettingsButton.icon.height
                            anchors.centerIn: parent
                        }
                        
                        ToolTip {
                            visible: playerSettingsButton.hovered
                            text: "播放器"
                            delay: 500
                            font.family: style.fontFamily
                            font.pixelSize: style.defaultFontSize - 1
                        }
                        
                        onClicked: playerSettingsDialog.open()
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
                            color: fileManager.fileModel.viewMode === FileListModel.ListView ? 
                                   Qt.darker(style.backgroundColor, 1.1) : 
                                   (listViewButton.hovered ? style.hoverColor : style.backgroundColor)
                            border.color: fileManager.fileModel.viewMode === FileListModel.ListView ? 
                                         style.accentColor : 
                                         (listViewButton.hovered ? style.accentColor : style.borderColor)
                            border.width: 1
                            radius: 3
                        }
                        
                        onClicked: fileManager.fileModel.viewMode = FileListModel.ListView
                        
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
                            color: fileManager.fileModel.viewMode === FileListModel.LargeIconView ? 
                                   Qt.darker(style.backgroundColor, 1.1) : 
                                   (largeIconViewButton.hovered ? style.hoverColor : style.backgroundColor)
                            border.color: fileManager.fileModel.viewMode === FileListModel.LargeIconView ? 
                                         style.accentColor : 
                                         (largeIconViewButton.hovered ? style.accentColor : style.borderColor)
                            border.width: 1
                            radius: 3
                        }
                        
                        onClicked: fileManager.fileModel.viewMode = FileListModel.LargeIconView
                        
                        ToolTip {
                            visible: parent.hovered
                            text: "大图标视图"
                            delay: 500
                        }
                    }
                }
            }
        }

        // 主内容区域
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: style.backgroundColor
            border.color: style.borderColor
            border.width: 1
            radius: 4

            // 使用 Row 替换 RowLayout，以便更好地控制分割
            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 0  // 移除间距，分割线控制

                // 左侧文件表
                Components.FileList {
                    id: fileList
                    model: fileManager.fileModel
                    width: parent.width * splitter.position  // 使用分割线位置
                    height: parent.height
                }

                // 分割线
                Components.Splitter {
                    id: splitter
                    height: parent.height
                    position: 0.7  // 初始位置设为70%
                    minimumPosition: 0.3  // 最小30%
                    maximumPosition: 0.8  // 最大80%

                    // 添加拖动时的视觉反馈
                    Rectangle {
                        visible: parent.dragging
                        color: "#80000000"
                        width: 1
                        height: parent.parent.height
                        x: parent.width / 2
                    }
                }

                // 右侧详情面板
                Components.DetailPanel {
                    width: parent.width * (1 - splitter.position) - splitter.width
                    height: parent.height
                    style: style
                    selectedItem: fileList.selectedItem
                    settings: settings
                }
            }
        }

        // 底部状态栏
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: style.backgroundColor
            border.color: style.borderColor
            border.width: 1
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                // 文件统计信息
                RowLayout {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter  // 垂直居中
                    Image {
                        source: "qrc:/resources/images/file.svg"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        width: 14
                        height: 14
                        opacity: 0.7
                    }
                    Text {
                        text: "总文件数: " + (fileList.model ? fileList.model.count : 0)
                        font.family: style.fontFamily
                        font.pixelSize: style.defaultFontSize - 1
                        color: style.secondaryTextColor
                    }
                }

                // 分隔符
                Rectangle {
                    width: 1
                    height: 16
                    color: Qt.alpha(style.borderColor, 0.8)
                    Layout.alignment: Qt.AlignVCenter  // 垂直居中
                }

                // 最后一条日志消息
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter  // 垂直居中
                    Image {
                        source: "qrc:/resources/images/log.svg"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        width: 14
                        height: 14
                        opacity: 0.7
                    }
                    Text {
                        Layout.fillWidth: true
                        text: fileManager.logMessages.length > 0 ? 
                              fileManager.logMessages[0].replace(/\[.*?\] /, '') : "就绪"
                        elide: Text.ElideRight
                        font.family: style.fontFamily
                        font.pixelSize: style.defaultFontSize - 1
                        color: style.secondaryTextColor
                    }
                }

                // 查看日志按钮
                Button {
                    id: viewLogButton
                    icon.source: "qrc:/resources/images/log.svg"
                    icon.width: 16
                    icon.height: 16
                    padding: 6
                    implicitWidth: 28
                    implicitHeight: 28
                    Layout.alignment: Qt.AlignVCenter  // 垂直居中
                    
                    ToolTip {
                        visible: parent.hovered
                        text: "查看日志"
                        delay: 500
                        font.family: style.fontFamily
                        font.pixelSize: style.defaultFontSize - 1
                    }
                    
                    background: Rectangle {
                        color: viewLogButton.down ? Qt.alpha(style.accentColor, 0.15) : 
                               viewLogButton.hovered ? Qt.alpha(style.accentColor, 0.1) : "transparent"
                        radius: 4
                        
                        // 添加边框效果
                        border.color: viewLogButton.down || viewLogButton.hovered ? 
                                    Qt.alpha(style.accentColor, 0.3) : "transparent"
                        border.width: 1
                    }
                    
                    onClicked: logDialog.open()
                }
            }
        }

    } // 这里是 ColumnLayout 的结束括号

    Dialogs.LogViewerDialog {
        id: logDialog
        logMessages: fileManager.logMessages
    }

    // 在窗口底部添加 FilterDialog
    Components.FilterDialog {
        id: filterDialog
        width: 400
        height: 200
        anchors.centerIn: parent
        settings: settings
        style: style  // 传递 style 对象
        
        onAccepted: {
            fileManager.fileModel.filterPattern = currentFilter
        }
        
        Component.onCompleted: {
            fileManager.fileModel.filterPattern = currentFilter
        }
    }

    // 添加 Settings 实例
    Components.Settings {
        id: settings
    }

    // 在 Window 的底部添加对话框组件
    Dialogs.PlayerSettingsDialog {
        id: playerSettingsDialog
        settings: settings
        style: style
    }
} // 这里是 Window 的结束括号
