import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import FileManager 1.0
import "." as Components
import "../dialogs" as Dialogs
import "../utils" as Utils

Item {
    id: root
    
    property alias model: gridView.model
    property var selectedItem: null
    property QtObject fileManager: null
    required property var style
    
    Components.Settings {
        id: settings
        
        // 添加调试输出
        Component.onCompleted: {
            console.log("FileList Settings 初始化完成")
            console.log("当前图标大小:", iconSize)
        }
    }
    
    // 添加监听
    Connections {
        target: settings
        
        function onIconSizeChanged() {
            console.log("图标大小已更改为:", settings.iconSize)
            // 强制重新布局
            gridView.forceLayout()
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        
        GridView {
            id: gridView
            anchors.fill: parent
            anchors.rightMargin: verticalScrollBar.visible ? verticalScrollBar.width : 0
            clip: true
            
            cellWidth: {
                if (!model || model.viewMode !== FileListModel.LargeIconView) 
                    return width
                return settings.iconSize + 20  // 添加边距
            }
            
            cellHeight: {
                if (!model || model.viewMode !== FileListModel.LargeIconView) 
                    return 40
                return settings.iconSize + 40  // 为文件名预留空间
            }
            
            ScrollBar.vertical: verticalScrollBar
            ScrollBar.horizontal: horizontalScrollBar
            
            delegate: ItemDelegate {
                id: delegateItem
                width: gridView.cellWidth
                height: gridView.cellHeight
                
                padding: gridView.model && gridView.model.viewMode === FileListModel.LargeIconView ? 0 : 6
                
                required property int index
                required property string fileName
                required property string fileType
                required property string filePath
                required property string displaySize
                required property string displayDate
                required property string previewPath
                required property bool previewLoading
                required property string fileId
                
                contentItem: Loader {
                    sourceComponent: gridView.model && 
                                   gridView.model.viewMode === FileListModel.LargeIconView ? 
                                   largeIconLayout : listLayout
                }
                
                Component {
                    id: listLayout
                    RowLayout {
                        spacing: 12
                        width: delegateItem.width
                        height: delegateItem.height
                        
                        Item { width: 8; height: 1 }
                        
                        Image {
                            source: getFileIcon(delegateItem)
                            sourceSize.width: 20
                            sourceSize.height: 20
                            Layout.alignment: Qt.AlignVCenter
                        }
                        
                        Label {
                            text: delegateItem.fileName
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: 12
                        }
                        
                        Label {
                            text: delegateItem.displaySize
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 80
                            font.pixelSize: 12
                            color: "#666666"
                        }
                        
                        Label {
                            text: delegateItem.displayDate
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 150
                            font.pixelSize: 12
                            color: "#666666"
                        }
                        
                        Item { width: 8; height: 1 }
                    }
                }
                
                Component {
                    id: largeIconLayout
                    ColumnLayout {
                        spacing: 8
                        width: delegateItem.width
                        height: delegateItem.height
                        
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: settings.iconSize
                            Layout.alignment: Qt.AlignHCenter
                            
                            Image {
                                id: previewImage
                                anchors.centerIn: parent
                                width: settings.iconSize
                                height: settings.iconSize
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: true
                                
                                property string currentSource: {
                                    if (delegateItem.previewLoading) {
                                        return "qrc:/resources/images/loading.svg";
                                    }
                                    if (delegateItem.previewPath && delegateItem.previewPath !== "") {
                                        return "file:///" + delegateItem.previewPath;
                                    }
                                    return getFileIcon(delegateItem);
                                }
                                
                                source: currentSource
                                
                                // 添加计时器用于处理超时
                                Timer {
                                    id: loadingTimer
                                    interval: 5000  // 5秒超时
                                    running: previewImage.status === Image.Loading
                                    onTriggered: {
                                        previewImage.source = getFileIcon(delegateItem);
                                    }
                                }
                                
                                onCurrentSourceChanged: {
                                    // 重置计时器
                                    loadingTimer.restart();
                                }
                                
                                BusyIndicator {
                                    anchors.centerIn: parent
                                    running: delegateItem.previewLoading || parent.status === Image.Loading
                                    visible: running && !loadingTimer.running  // 超时后不显示加载指示器
                                }
                            }
                        }
                        
                        Label {
                            text: delegateItem.fileName
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignTop
                            wrapMode: Text.NoWrap
                            maximumLineCount: 1
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignHCenter
                            Layout.margins: 4
                            
                            font {
                                pixelSize: 12
                                family: "Microsoft YaHei"
                            }
                        }
                    }
                }
                
                highlighted: GridView.isCurrentItem
                
                onClicked: function(mouse) {
                    gridView.currentIndex = index
                    root.selectedItem = {
                        fileId: fileId,
                        fileName: fileName,
                        fileType: fileType,
                        filePath: filePath,
                        displaySize: displaySize,
                        displayDate: displayDate
                    }
                    Utils.Logger.logOperation(fileManager, "选中文件", fileName)
                }
                
                onPressAndHold: function(mouse) {
                    gridView.currentIndex = index
                    root.selectedItem = {
                        fileId: fileId,
                        fileName: fileName,
                        fileType: fileType,
                        filePath: filePath,
                        displaySize: displaySize,
                        displayDate: displayDate
                    }
                    Utils.Logger.logOperation(fileManager, "长按文件", fileName)
                    contextMenu.popup()
                }
                
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        gridView.currentIndex = index
                        root.selectedItem = {
                            fileId: fileId,
                            fileName: fileName,
                            fileType: fileType,
                            filePath: filePath,
                            displaySize: displaySize,
                            displayDate: displayDate
                        }
                        Utils.Logger.logOperation(fileManager, "右键点击文件", fileName)
                        contextMenu.popup()
                    }
                }
                
                // 添加双击处理
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: {
                        if (!delegateItem.fileType) return
                        const type = String(delegateItem.fileType).toLowerCase()
                        if (settings.imageFilter.includes(type) || settings.videoFilter.includes(type)) {
                            if (root.fileManager) {
                                Utils.Logger.logOperation(fileManager, "双击打开文件", delegateItem.fileName)
                                root.fileManager.openFile(delegateItem.filePath, delegateItem.fileType)
                            }
                        }
                    }
                }
                
                Menu {
                    id: contextMenu
                    
                    padding: 2
                    
                    background: Rectangle {
                        implicitWidth: 180
                        color: "white"
                        radius: 6
                        
                        Rectangle {
                            id: borderRect
                            anchors.fill: parent
                            color: "transparent"
                            radius: parent.radius
                            border.width: 1
                            border.color: "#E5E5E5"
                        }
                        
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            anchors.margins: -1
                            color: "#10000000"
                            radius: parent.radius + 1
                        }
                        Rectangle {
                            z: -2
                            anchors.fill: parent
                            anchors.margins: -2
                            color: "#08000000"
                            radius: parent.radius + 2
                        }
                        Rectangle {
                            z: -3
                            anchors.fill: parent
                            anchors.margins: -3
                            color: "#05000000"
                            radius: parent.radius + 3
                        }
                    }
                    
                    enter: Transition {
                        ParallelAnimation {
                            NumberAnimation { 
                                property: "opacity"
                                from: 0.0
                                to: 1.0
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation { 
                                property: "scale"
                                from: 0.95
                                to: 1.0
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    
                    exit: Transition {
                        ParallelAnimation {
                            NumberAnimation { 
                                property: "opacity"
                                from: 1.0
                                to: 0.0
                                duration: 100
                                easing.type: Easing.InCubic
                            }
                            NumberAnimation { 
                                property: "scale"
                                from: 1.0
                                to: 0.95
                                duration: 100
                                easing.type: Easing.InCubic
                            }
                        }
                    }
                    
                    MenuItem {
                        id: openMenuItem
                        text: qsTr("打开")
                        icon.source: "qrc:/resources/images/open.svg"
                        icon.width: 14
                        icon.height: 14
                        
                        background: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 28
                            color: "transparent"
                        }
                        
                        contentItem: RowLayout {
                            spacing: 6
                            Image {
                                source: openMenuItem.icon.source
                                sourceSize.width: openMenuItem.icon.width
                                sourceSize.height: openMenuItem.icon.height
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: openMenuItem.text
                                color: openMenuItem.enabled ? "#000000" : "#999999"
                                font.family: "Microsoft YaHei"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 2
                            }
                        }
                        
                        enabled: {
                            if (!delegateItem.fileType) return false
                            const type = String(delegateItem.fileType).toLowerCase()
                            return settings.imageFilter.includes(type) || 
                                   settings.videoFilter.includes(type)
                        }
                        
                        onTriggered: {
                            if (!delegateItem.fileType) {
                                Utils.Logger.logError(fileManager, "打开文件", delegateItem.fileName, "无效的文件类型")
                                return
                            }
                            Utils.Logger.logOperation(fileManager, "菜单打开文件", delegateItem.fileName)
                            if (root.fileManager) {
                                root.fileManager.openFile(delegateItem.filePath, delegateItem.fileType)
                            }
                        }
                    }

                    MenuItem {
                        id: tagEditMenuItem
                        text: qsTr("编辑标签")
                        icon.source: "qrc:/resources/images/tag-edit.svg"
                        icon.width: 14
                        icon.height: 14
                        
                        background: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 28
                            color: "transparent"
                        }
                        
                        contentItem: RowLayout {
                            spacing: 6
                            Image {
                                source: tagEditMenuItem.icon.source
                                sourceSize.width: tagEditMenuItem.icon.width
                                sourceSize.height: tagEditMenuItem.icon.height
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: tagEditMenuItem.text
                                color: "#000000"
                                font.family: "Microsoft YaHei"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 2
                            }
                        }
                        
                        onTriggered: {
                            if (!delegateItem || !delegateItem.fileId) {
                                Utils.Logger.logError(fileManager, "编辑标签", delegateItem.fileName, "无效的文件ID")
                                return
                            }
                            Utils.Logger.logOperation(fileManager, "打开标签编辑", delegateItem.fileName)
                            fileTagDialog.fileId = delegateItem.fileId
                            fileTagDialog.filePath = delegateItem.filePath
                            fileTagDialog.open()
                        }
                    }
                    
                    MenuItem {
                        id: showInFolderMenuItem
                        text: qsTr("在文件夹中显示")
                        icon.source: "qrc:/resources/images/folder.svg"
                        icon.width: 14
                        icon.height: 14
                        
                        background: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 28
                            color: "transparent"
                        }
                        
                        contentItem: RowLayout {
                            spacing: 6
                            Image {
                                source: showInFolderMenuItem.icon.source
                                sourceSize.width: showInFolderMenuItem.icon.width
                                sourceSize.height: showInFolderMenuItem.icon.height
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: showInFolderMenuItem.text
                                color: showInFolderMenuItem.enabled ? "#000000" : "#999999"
                                font.family: "Microsoft YaHei"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 2
                            }
                        }
                        
                        enabled: delegateItem.filePath ? true : false
                        onTriggered: {
                            if (delegateItem.filePath) {
                                const normalizedPath = delegateItem.filePath.replace(/\\/g, '/')
                                const folderPath = normalizedPath.substring(0, normalizedPath.lastIndexOf('/'))
                                
                                if (folderPath) {
                                    Utils.Logger.logOperation(fileManager, "在文件夹中显示", delegateItem.fileName)
                                    Qt.openUrlExternally("file:///" + folderPath)
                                } else {
                                    Utils.Logger.logError(fileManager, "在文件夹中显示", delegateItem.fileName, "无法获取文件夹路径")
                                }
                            } else {
                                Utils.Logger.logError(fileManager, "在文件夹中显示", "未知文件", "文件路径为空")
                            }
                        }
                    }

                    MenuSeparator {
                        contentItem: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 1
                            color: "#E5E5E5"
                        }
                        
                        padding: 4
                    }

                    MenuItem {
                        id: debugMenuItem
                        text: qsTr("调试信息")
                        icon.source: "qrc:/resources/images/debug.svg"
                        icon.width: 14
                        icon.height: 14
                        
                        background: Rectangle {
                            implicitWidth: 180
                            implicitHeight: 28
                            color: "transparent"
                        }
                        
                        contentItem: RowLayout {
                            spacing: 6
                            Image {
                                source: debugMenuItem.icon.source
                                sourceSize.width: debugMenuItem.icon.width
                                sourceSize.height: debugMenuItem.icon.height
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: debugMenuItem.text
                                color: "#000000"
                                font.family: "Microsoft YaHei"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Layout.leftMargin: 2
                            }
                        }
                        
                        onTriggered: {
                            Utils.Logger.logOperation(fileManager, "显示调试信息", delegateItem.fileName)
                            console.log("文件信息:", JSON.stringify({
                                fileName: delegateItem.fileName,
                                fileType: delegateItem.fileType,
                                filePath: delegateItem.filePath,
                                fileId: delegateItem.fileId,
                                displaySize: delegateItem.displaySize,
                                displayDate: delegateItem.displayDate
                            }, null, 2))
                        }
                    }

                    MenuItem {
                        id: spriteMenuItem
                        text: qsTr("雪碧图")
                        icon.source: "qrc:/resources/images/image.svg"
                        icon.width: 14
                        icon.height: 14
                        
                        visible: {
                            if (!delegateItem.fileType) return false
                            const type = String(delegateItem.fileType).toLowerCase()
                            return settings.videoFilter.includes(type)
                        }
                        
                        onTriggered: {
                            Utils.Logger.logOperation(fileManager, "生成视频雪碧图", delegateItem.fileName)
                            spriteDialog.filePath = delegateItem.filePath
                            spriteDialog.open()
                        }
                    }
                }
            }
        }
        
        ScrollBar {
            id: verticalScrollBar
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: horizontalScrollBar.visible ? horizontalScrollBar.top : parent.bottom
            
            active: hovered || pressed
            orientation: Qt.Vertical
            size: gridView.height / gridView.contentHeight
            position: gridView.visibleArea.yPosition
            visible: gridView.contentHeight > gridView.height
            
            background: Rectangle {
                color: "transparent"
                border.color: "transparent"
            }
        }
        
        ScrollBar {
            id: horizontalScrollBar
            anchors.left: parent.left
            anchors.right: verticalScrollBar.visible ? verticalScrollBar.left : parent.right
            anchors.bottom: parent.bottom
            
            active: hovered || pressed
            orientation: Qt.Horizontal
            size: gridView.width / gridView.contentWidth
            position: gridView.visibleArea.xPosition
            visible: gridView.contentWidth > gridView.width
            
            background: Rectangle {
                color: "transparent"
                border.color: "transparent"
            }
        }
    }
    
    // 添加组件生命周期日志
    Component.onCompleted: {
        Utils.Logger.logDebug(fileManager, "组件初始化", "FileList")
        if (model) {
            Utils.Logger.logDebug(fileManager, "视图模式", 
                model.viewMode === FileListModel.ListView ? "列表视图" : "大图标视图")
        }
    }
    
    // 添加视图模式变更日志
    Connections {
        target: model
        function onViewModeChanged() {
            if (model) {
                Utils.Logger.logOperation(fileManager, "视图模式变更", 
                    model.viewMode === FileListModel.ListView ? "列表视图" : "大图标视图")
            }
        }
    }
    
    // 添加预览加载日志
    function onPreviewLoadError(fileName) {
        Utils.Logger.logOperation(fileManager, "预览加载失败", fileName)
    }
    
    function onPreviewLoadSuccess(fileName) {
        Utils.Logger.logOperation(fileManager, "预览加载成功", fileName)
    }
    
    function getFileIcon(item) {
        if (!item || !item.fileType) {
            return "qrc:/resources/images/file.svg"
        }
        
        const type = String(item.fileType).toLowerCase()
        if (settings.imageFilter.includes(type)) {
            return "qrc:/resources/images/image.svg"
        } else if (settings.videoFilter.includes(type)) {
            return "qrc:/resources/images/video.svg"
        } else if (settings.documentFilter.includes(type)) {
            return "qrc:/resources/images/text.svg"
        } else if (settings.audioFilter.includes(type)) {
            return "qrc:/resources/images/audio.svg"
        } else if (settings.archiveFilter.includes(type)) {
            return "qrc:/resources/images/archive.svg"
        } else if (settings.devFilter.includes(type)) {
            return "qrc:/resources/images/code.svg"
        }
        return "qrc:/resources/images/file.svg"
    }
    
    Dialogs.SpriteDialog {
        id: spriteDialog
        style: root.style
        fileManager: root.fileManager
        filePath: ""
    }
    
    // 添加过滤方法
    function setFilterByFileIds(fileIds) {
        if (model) {
            model.setFilterByFileIds(fileIds, false)
        }
    }

    function clearFilter() {
        if (model) {
            model.clearFilter()
        }
    }
}
