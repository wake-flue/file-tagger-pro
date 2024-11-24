import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic  // 添加 Basic 样式
import QtQuick.Layouts
import FileManager 1.0
import "./components" as Components  // 修改导入方式
import "./dialogs" as Dialogs
import "./settings" as Settings  // 添加这行

Window {
    width: 960
    height: 680
    visible: true
    title: qsTr("FileTaggerPro")

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
        
        // 添加防抖动定时器
        property var rescanTimer: Timer {
            interval: 1000  // 1秒防抖动
            repeat: false
            onTriggered: {
                let currentFilter = settings.value("fileFilter", "")
                let filters = currentFilter ? currentFilter.split(';') : []
                if (fileManager.currentPath) {
                    console.log("执行目录扫描:", fileManager.currentPath)
                    fileManager.scanDirectory(fileManager.currentPath, filters)
                }
            }
        }
        
        // 添加文件操作日志记录
        onFileChanged: function(path) {
            console.log("检测到文件变更:", path)
            fileManager.addLogMessage("检测到文件变更: " + path)
            rescanTimer.restart()
        }
        
        onDirectoryChanged: function(path) {
            console.log("检测到目录变更:", path)
            fileManager.addLogMessage("检测到目录变更: " + path)
            rescanTimer.restart()
        }
        
        // 监控扫描状态变化
        onIsScanningChanged: {
            if (isScanning) {
                console.log("开始扫描目录...")
                fileManager.addLogMessage("开始扫描目录...")
            } else {
                console.log("目录扫描完成")
                fileManager.addLogMessage("目录扫描完成")
            }
        }
        
        onError: function(errorMessage) {
            console.error("文件系统错误:", errorMessage)
            fileManager.addLogMessage("错误: " + errorMessage)
        }
    }

    Dialogs.FolderPickerDialog {
        id: folderDialog
        onFolderSelected: function(path) {
            if (!path) {
                console.warn("未选择有效路径")
                return
            }
            
            try {
                fileManager.setWatchPath(path)
                let currentFilter = settings.value("fileFilter", "")
                let filters = currentFilter ? currentFilter.split(';') : []
                fileManager.scanDirectory(path, filters)
            } catch (error) {
                console.error("设置监视路径失败:", error)
                // 可以添加错误提示对话框
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        
        // TopToolBar
        Components.TopToolBar {
            Layout.fillWidth: true
            style: style
            settings: settings
            fileManager: fileManager
            folderDialog: folderDialog
            settingsWindow: settingsWindow
        }
        
        // TagToolBar
        Components.TagToolBar {
            Layout.fillWidth: true
            style: style
            settings: settings
            fileManager: fileManager
            settingsWindow: settingsWindow
            fileList: fileList
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
                    fileManager: fileManager
                    style: style
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
        Components.StatusBar {
            Layout.fillWidth: true
            style: style
            fileManager: fileManager
            fileList: fileList
            logDialog: logDialog
            settingsWindow: settingsWindow
        }

    } // 这里是 ColumnLayout 的结束括号

    // 直接使用 settings 中的值
    Component.onCompleted: {
        fileManager.fileModel.filterPattern = settings.fileFilter
    }

    Dialogs.FileTagDialog {
        id: fileTagDialog
        style: style
    }

    // 添加设置窗口
    Dialogs.SettingsWindow {
        id: settingsWindow
        style: style
        settings: settings
        fileManager: fileManager
    }

    // 添加 Settings 实例
    Components.Settings {
        id: settings
    }
} // 这里是 Window 的结束括号
