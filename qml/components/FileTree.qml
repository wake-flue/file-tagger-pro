import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Qt.labs.platform
import ".." 1.0

Rectangle {
    id: root
    color: Style.windowBackgroundColor
    
    property string currentPath: ""
    property string selectedFilePath: ""
    property bool initialized: false
    property var fileSystemManager: null
    property var pathHistory: []  // 历史记录数组
    property int historyIndex: -1 // 当前在历史记录中的位置
    property bool canGoBack: historyIndex > 0
    property bool canGoForward: historyIndex < pathHistory.length - 1
    property bool isLoading: false // 添加加载状态标志
    
    signal fileSelected(string filePath)
    
    // 添加延迟加载计时器
    Timer {
        id: loadTimer
        interval: 50  // 50ms 延迟
        repeat: false
        property string pathToLoad: ""
        property bool addToHistory: true
        onTriggered: {
            if (pathToLoad) {
                root.loadDirectoryInternal(pathToLoad, addToHistory)
                pathToLoad = ""
            }
        }
    }
    
    Component.onCompleted: {
        if (fileSystemManager) {
            fileSystemManager.fileTree = root
            if (fileSystemManager.currentPath) {
                loadDirectory(fileSystemManager.currentPath, true)
            }
        }
    }
    
    Connections {
        target: fileSystemManager
        function onCurrentPathChanged(path) {
            if (path && path !== root.currentPath && !root.isLoading) {
                loadDirectory(path, true)
            }
        }
    }
    
    // 公共加载函数
    function loadDirectory(path, addToHistory = true) {
        if (!path || root.isLoading) return
        
        // 使用计时器延迟加载
        loadTimer.pathToLoad = path
        loadTimer.addToHistory = addToHistory
        loadTimer.start()
    }
    
    // 内部加载函数
    function loadDirectoryInternal(path, addToHistory) {
        if (!path || root.isLoading) return
        
        root.isLoading = true
        
        // 规范化路径
        let normalizedPath = path.replace(/\\/g, '/')
        if (!normalizedPath.endsWith('/')) {
            normalizedPath += '/'
        }
        
        // 如果路径没有变化，不需要重新加载
        if (normalizedPath === root.currentPath) {
            root.isLoading = false
            return
        }
        
        root.currentPath = normalizedPath
        root.initialized = true
        
        // 设置文件夹模型的路径
        let urlPath = "file:///" + normalizedPath.replace(/^[A-Za-z]:/, match => match.toLowerCase())
        folderModel.folder = urlPath
        
        if (fileSystemManager && fileSystemManager.currentPath !== normalizedPath) {
            fileSystemManager.currentPath = normalizedPath
        }

        // 添加到历史记录
        if (addToHistory) {
            // 如果在历史记录中间位置导航到新位置，删除当前位置之后的记录
            if (historyIndex < pathHistory.length - 1) {
                pathHistory = pathHistory.slice(0, historyIndex + 1)
            }
            pathHistory.push(normalizedPath)
            historyIndex = pathHistory.length - 1
        }
    }

    function goBack() {
        if (canGoBack) {
            historyIndex--
            loadDirectory(pathHistory[historyIndex], false)
        }
    }

    function goForward() {
        if (canGoForward) {
            historyIndex++
            loadDirectory(pathHistory[historyIndex], false)
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: root.initialized
        
        // 导航栏
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.toolBarHeight
            color: Style.backgroundColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.contentMargin
                anchors.rightMargin: Style.contentMargin
                spacing: Style.spacingNormal

                // 导航按钮容器
                RowLayout {
                    spacing: Style.spacingSmall

                    Button {
                        id: backButton
                        Layout.preferredWidth: Style.iconSizeNormal
                        Layout.preferredHeight: Style.iconSizeNormal
                        enabled: root.canGoBack
                        flat: true
                        
                        contentItem: Text {
                            text: "←"
                            color: backButton.enabled ? 
                                (backButton.hovered ? Style.accentColor : Style.textColor) : 
                                Style.lightTextColor
                            font.pixelSize: Style.fontSizeLarge
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: backButton.hovered ? Style.hoverColor : "transparent"
                            radius: Style.radiusSmall
                        }

                        onClicked: root.goBack()
                    }

                    Button {
                        id: forwardButton
                        Layout.preferredWidth: Style.iconSizeNormal
                        Layout.preferredHeight: Style.iconSizeNormal
                        enabled: root.canGoForward
                        flat: true

                        contentItem: Text {
                            text: "→"
                            color: forwardButton.enabled ? 
                                (forwardButton.hovered ? Style.accentColor : Style.textColor) : 
                                Style.lightTextColor
                            font.pixelSize: Style.fontSizeLarge
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            color: forwardButton.hovered ? Style.hoverColor : "transparent"
                            radius: Style.radiusSmall
                        }

                        onClicked: root.goForward()
                    }
                }

                // 路径显示
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.inputHeight
                    color: Style.backgroundColor
                    radius: Style.radiusSmall

                    Label {
                        anchors.fill: parent
                        anchors.leftMargin: Style.contentMargin
                        anchors.rightMargin: Style.contentMargin
                        text: root.currentPath
                        elide: Text.ElideMiddle
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10
                        color: Style.textColor
                    }
                }
            }
        }
        
        ListView {
            id: folderView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Style.spacingSmall / 2
            
            model: FolderListModel {
                id: folderModel
                showDirsFirst: true
                showDotAndDotDot: false
                sortField: FolderListModel.Name
                nameFilters: ["*"]
                showFiles: false
                showDirs: true
                caseSensitive: false
                rootFolder: "file:///"
                folder: root.currentPath ? "file://" + root.currentPath : "file:///"
                
                onStatusChanged: {
                    if (status === FolderListModel.Ready) {
                        root.isLoading = false
                    } else if (status === FolderListModel.Loading) {
                        // 加载中
                    } else if (status === FolderListModel.Error) {
                        console.error("FolderListModel: 加载错误")
                        root.isLoading = false
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                active: true
                width: Style.scrollBarWidth
            }
            
            delegate: Item {
                id: delegateItem
                width: folderView.width
                height: Style.listItemHeight - Style.spacingSmall
                
                Rectangle {
                    id: background
                    anchors.fill: parent
                    anchors.leftMargin: Style.spacingSmall
                    anchors.rightMargin: Style.spacingSmall
                    color: filePath === root.selectedFilePath ? Style.selectedColor : "transparent"
                    radius: Style.radiusSmall
                    
                    Rectangle {
                        id: hoverBackground
                        anchors.fill: parent
                        color: Style.hoverColor
                        radius: Style.radiusSmall
                        opacity: 0
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Style.contentMargin
                        anchors.rightMargin: Style.contentMargin
                        spacing: Style.spacingNormal
                        
                        Item {
                            width: Style.iconSizeMini
                            height: Style.iconSizeMini
                            
                            Image {
                                anchors.centerIn: parent
                                source: fileIsDir ? "qrc:/resources/images/folder.svg" : "qrc:/resources/images/file.svg"
                                width: Style.iconSizeMini
                                height: Style.iconSizeMini
                                opacity: 0.7
                            }
                        }
                        
                        Label {
                            text: fileName
                            color: Style.textColor
                            font.pixelSize: Style.fontSizeNormal
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    
                    onEntered: {
                        hoverBackground.opacity = 0.5
                    }
                    
                    onExited: {
                        hoverBackground.opacity = 0
                    }
                    
                    onClicked: {
                        if (fileIsDir) {
                            // 使用 Timer 延迟处理点击事件
                            Qt.callLater(function() {
                                root.loadDirectory(filePath, true)
                            })
                        } else {
                            root.selectedFilePath = filePath
                            root.fileSelected(filePath)
                        }
                    }
                }
                
                Behavior on height {
                    NumberAnimation { 
                        duration: Style.animationDurationFast
                        easing.type: Easing.OutQuad 
                    }
                }
            }
        }
    }
    
    Behavior on opacity {
        NumberAnimation { duration: Style.animationDurationFast }
    }
} 