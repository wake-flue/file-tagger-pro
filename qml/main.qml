import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import FileManager 1.0
import "./components" as Components
import "./dialogs" as Dialogs
import "./settings" as Settings
import "./utils" as Utils

Window {
    id: mainWindow
    width: 960
    height: 680
    visible: true
    title: qsTr("FileTaggerPro")
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    // 添加全局字体和颜色定义
    QtObject {
        id: style
        readonly property color accentColor: "#0078D4"
        readonly property color backgroundColor: "#FFFFFF"
        readonly property color borderColor: "#E5E5E5"
        readonly property color textColor: "#202020"
        readonly property color secondaryTextColor: "#666666"
        readonly property color hoverColor: "#F0F0F0"
        readonly property color selectedColor: "#E5F3FF"
        readonly property int defaultFontSize: 12
        readonly property string fontFamily: {
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

    // 添加属性来存储窗口状态
    property rect previousWindowState: Qt.rect(0, 0, 960, 680)
    property size dragStartSize: Qt.size(960, 680)  // 添加这个属性到Window对象中
    
    onVisibilityChanged: {
        // 进入全屏时保存当前状态
        if (visibility === Window.Maximized) {
            if (previousWindowState.width === 0) {
                previousWindowState = Qt.rect(x, y, width, height)
            }
        }
    }

    // 监听窗口尺寸变化
    onWidthChanged: {
        if (width >= minimumWidth && visibility !== Window.Maximized) {
            dragStartSize.width = width
        }
    }
    
    onHeightChanged: {
        if (height >= minimumHeight && visibility !== Window.Maximized) {
            dragStartSize.height = height
        }
    }

    // 主容器
    Rectangle {
        id: rootContainer
        anchors.fill: parent
        color: style.backgroundColor
        border.color: style.borderColor
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 1
        }

        // 标题栏
        Utils.WindowTitleBar {
            id: titleBar
            window: mainWindow
            style: style
            title: mainWindow.title
        }

        // 原有内容容器
        ColumnLayout {
            anchors {
                top: titleBar.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: 1
            }
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
                fileList: mainContainer.fileList
            }
            
            // 主内容区域
            Components.MainContainer {
                id: mainContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                style: style
                settings: settings
                fileManager: fileManager
                
                onFileListVisibilityChanged: function(visible) {
                    console.log("文件列表可见性改变:", visible)
                }
                
                onDetailPanelVisibilityChanged: function(visible) {
                    console.log("详情面板可见性改变:", visible)
                }
            }
            
            // 底部状态栏
            Components.StatusBar {
                Layout.fillWidth: true
                style: style
                fileManager: fileManager
                fileList: mainContainer.fileList
                logDialog: logDialog
                settingsWindow: settingsWindow
            }
        }

        // 窗口缩放区域
        Utils.WindowResizer {
            id: resizeArea
            window: mainWindow
            anchors.right: parent.right
            anchors.bottom: parent.bottom
        }
    }

    // 设置最小窗口大小
    minimumWidth: 800
    minimumHeight: 600

    // 其他组件
    FileSystemManager {
        id: fileManager
        
        // 添加必要的信号处理
        onFileChanged: function(path) {
            console.log("文件变更:", path)
            rescanTimer.restart()
        }
        
        onDirectoryChanged: function(path) {
            console.log("目录变更:", path)
            rescanTimer.restart()
        }
        
        // 添加扫描完成的处理
        onIsScanningChanged: {
            if (!isScanning) {
                console.log("扫描完成，文件数:", fileModel.rowCount())
            }
        }
    }

    Dialogs.FolderPickerDialog {
        id: folderDialog
        
        onFolderSelected: function(path) {
            if (!path) {
                console.log("未选择有效路径")
                return
            }
            
            try {
                // 设置监视路径
                fileManager.setWatchPath(path)
                
                // 获取当前过滤器设置
                let currentFilter = settings.value("fileFilter", "")
                let filters = currentFilter ? currentFilter.split(';') : []
                
                // 扫描目录
                console.log("开始扫描目录:", path)
                fileManager.scanDirectory(path, filters)
            } catch (error) {
                console.error("设置目录失败:", error)
            }
        }
    }

    Dialogs.FileTagDialog {
        id: fileTagDialog
        style: style
    }

    Dialogs.SettingsWindow {
        id: settingsWindow
        style: style
        settings: settings
        fileManager: fileManager
    }

    Components.Settings {
        id: settings
    }

    Component.onCompleted: {
        if (settings && settings.fileFilter) {
            fileManager.fileModel.filterPattern = settings.fileFilter
        }
    }
}
