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
import "." 1.0

Window {
    id: mainWindow
    width: 960
    height: 680
    visible: true
    title: qsTr("FileTaggerPro")
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

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
        color: Style.backgroundColor
        border.color: Style.borderColor
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
                settings: settings
                fileManager: fileManager
                folderDialog: folderDialog
                settingsWindow: settingsWindow
            }
            
            // TagToolBar
            Components.TagToolBar {
                Layout.fillWidth: true
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
                
                settings: settings
                fileManager: fileManager
            }
            
            // 底部状态栏
            Components.StatusBar {
                Layout.fillWidth: true
                fileManager: fileManager
                fileList: mainContainer.fileList
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
    }

    Dialogs.SettingsWindow {
        id: settingsWindow
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
