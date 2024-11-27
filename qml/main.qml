import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import FileManager 1.0
import "./components" as Components
import "./dialogs" as Dialogs
import "./settings" as Settings

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
        Rectangle {
            id: titleBar
            height: 32
            color: style.backgroundColor
            radius: 0
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            // 标题栏内容
            RowLayout {
                anchors.fill: parent
                spacing: 0

                // 应用图标
                Image {
                    Layout.leftMargin: 8
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    source: "qrc:/resources/icons/app_icon.svg"
                }

                // 标题文本
                Text {
                    Layout.leftMargin: 8
                    text: mainWindow.title
                    color: style.textColor
                    font.family: style.fontFamily
                    font.pixelSize: style.defaultFontSize
                }

                // 弹性空间
                Item {
                    Layout.fillWidth: true
                }

                // 窗口控制按钮
                Row {
                    Layout.alignment: Qt.AlignRight
                    spacing: 0

                    // 最小化按钮
                    Loader {
                        sourceComponent: titleBarButtonComponent
                        onLoaded: {
                            item.iconSource = "qrc:/resources/images/window-minimize.svg"
                            item.clicked.connect(function() { mainWindow.showMinimized() })
                        }
                    }

                    // 最大化/还原按钮
                    Loader {
                        id: maximizeButton
                        sourceComponent: titleBarButtonComponent
                        property bool isMaximized: mainWindow.visibility === Window.Maximized

                        Component.onCompleted: {
                            item.iconSource = isMaximized ? "qrc:/resources/images/window-restore.svg" : "qrc:/resources/images/window-maximize.svg"
                        }

                        Connections {
                            target: mainWindow
                            function onVisibilityChanged() {
                                if (maximizeButton.item) {
                                    maximizeButton.item.iconSource = mainWindow.visibility === Window.Maximized ? 
                                        "qrc:/resources/images/window-restore.svg" : "qrc:/resources/images/window-maximize.svg"
                                }
                            }
                        }

                        onLoaded: {
                            item.clicked.connect(function() {
                                if (mainWindow.visibility === Window.Maximized) {
                                    mainWindow.showNormal()
                                } else {
                                    mainWindow.showMaximized()
                                }
                            })
                        }
                    }

                    // 关闭按钮
                    Loader {
                        sourceComponent: titleBarButtonComponent
                        onLoaded: {
                            item.iconSource = "qrc:/resources/images/window-close.svg"
                            item.hoverColor = "#E81123"
                            item.hoverTextColor = "#FFFFFF"
                            item.clicked.connect(function() { mainWindow.close() })
                        }
                    }
                }
            }

            // 标题栏拖动区域
            MouseArea {
                id: titleBarMouseArea
                anchors.fill: parent
                anchors.rightMargin: 138
                property point clickPos: Qt.point(0, 0)
                property bool isDragging: false
                property point startWindowPos: Qt.point(0, 0)
                property point startMousePos: Qt.point(0, 0)
                property bool needsSizeCheck: false

                function handlePressed(mouseX, mouseY) {
                    clickPos = Qt.point(mouseX, mouseY)
                    startWindowPos = Qt.point(mainWindow.x, mainWindow.y)
                    startMousePos = mapToGlobal(mouseX, mouseY)
                    mainWindow.dragStartSize = Qt.size(mainWindow.width, mainWindow.height)
                    isDragging = false
                    needsSizeCheck = false
                }

                function handlePositionChanged(mouseX, mouseY) {
                    if (!isDragging) {
                        var currentGlobalPos = mapToGlobal(mouseX, mouseY)
                        var deltaX = Math.abs(currentGlobalPos.x - startMousePos.x)
                        var deltaY = Math.abs(currentGlobalPos.y - startMousePos.y)
                        
                        if (deltaX > 5 || deltaY > 5) {
                            isDragging = true
                            if (mainWindow.visibility === Window.Maximized) {
                                mainWindow.showNormal()
                                var relativeX = mouseX / titleBar.width
                                mainWindow.width = previousWindowState.width
                                mainWindow.height = previousWindowState.height
                                mainWindow.dragStartSize = Qt.size(previousWindowState.width, previousWindowState.height)
                                
                                var newX = currentGlobalPos.x - (mainWindow.width * relativeX)
                                var newY = currentGlobalPos.y - (clickPos.y)
                                mainWindow.x = newX
                                mainWindow.y = newY
                                startWindowPos = Qt.point(newX, newY)
                                startMousePos = currentGlobalPos
                            }
                            needsSizeCheck = true
                        }
                    }
                    
                    if (isDragging && mainWindow.visibility !== Window.Maximized) {
                        mainWindow.width = mainWindow.dragStartSize.width
                        mainWindow.height = mainWindow.dragStartSize.height
                        
                        var currentPos = mapToGlobal(mouseX, mouseY)
                        var totalDeltaX = currentPos.x - startMousePos.x
                        var totalDeltaY = currentPos.y - startMousePos.y
                        
                        mainWindow.x = startWindowPos.x + totalDeltaX
                        mainWindow.y = startWindowPos.y + totalDeltaY
                    }
                }

                function checkAndAdjustSize() {
                    if (!needsSizeCheck) return
                    
                    var targetWidth = Math.max(mainWindow.width, minimumWidth)
                    var targetHeight = Math.max(mainWindow.height, minimumHeight)
                    
                    if (mainWindow.width < mainWindow.dragStartSize.width * 0.8) {
                        targetWidth = mainWindow.dragStartSize.width
                    }
                    if (mainWindow.height < mainWindow.dragStartSize.height * 0.8) {
                        targetHeight = mainWindow.dragStartSize.height
                    }
                    
                    if (targetWidth !== mainWindow.width || targetHeight !== mainWindow.height) {
                        mainWindow.width = targetWidth
                        mainWindow.height = targetHeight
                    }
                    
                    needsSizeCheck = false
                }

                function handleDoubleClicked() {
                    if (mainWindow.visibility === Window.Maximized) {
                        mainWindow.showNormal()
                    } else {
                        previousWindowState = Qt.rect(mainWindow.x, mainWindow.y, mainWindow.width, mainWindow.height)
                        mainWindow.showMaximized()
                    }
                }

                onPressed: function(event) { handlePressed(event.x, event.y) }
                onPositionChanged: function(event) { handlePositionChanged(event.x, event.y) }
                onDoubleClicked: handleDoubleClicked()
                onReleased: {
                    if (isDragging) {
                        checkAndAdjustSize()
                    }
                    isDragging = false
                    startWindowPos = Qt.point(mainWindow.x, mainWindow.y)
                }
            }
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
        MouseArea {
            id: resizeArea
            width: 8
            height: 8
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            cursorShape: Qt.SizeFDiagCursor

            property point clickPos: Qt.point(0, 0)

            function handlePressed(mouseX, mouseY) {
                clickPos = Qt.point(mouseX, mouseY)
            }

            function handlePositionChanged(mouseX, mouseY) {
                if (pressed && mainWindow.visibility !== Window.Maximized) {
                    var delta = Qt.point(mouseX - clickPos.x, mouseY - clickPos.y)
                    mainWindow.width = Math.max(mainWindow.width + delta.x, mainWindow.minimumWidth)
                    mainWindow.height = Math.max(mainWindow.height + delta.y, mainWindow.minimumHeight)
                }
            }

            onPressed: function(event) { handlePressed(event.x, event.y) }
            onPositionChanged: function(event) { handlePositionChanged(event.x, event.y) }
        }
    }

    // 标题栏按钮组件
    Component {
        id: titleBarButtonComponent
        Rectangle {
            property string buttonText: ""
            property string iconSource: ""
            property color hoverColor: style.hoverColor
            property color hoverTextColor: style.textColor
            property color normalColor: "transparent"
            property color normalTextColor: style.textColor
            
            width: 46
            height: 32
            color: mouseArea.containsMouse ? hoverColor : normalColor
            
            Image {
                id: buttonIcon
                anchors.centerIn: parent
                source: parent.iconSource
                sourceSize.width: 10
                sourceSize.height: 10
                visible: parent.iconSource !== ""
            }
            
            MultiEffect {
                source: buttonIcon
                anchors.fill: buttonIcon
                colorization: 1.0
                colorizationColor: mouseArea.containsMouse ? parent.hoverTextColor : parent.normalTextColor
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: parent.clicked()
            }
            
            signal clicked()
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
            console.log("应用文件过滤器:", settings.fileFilter)
        }
    }
}
