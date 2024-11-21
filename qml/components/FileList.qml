import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import FileManager 1.0

Item {
    id: root
    
    property alias model: gridView.model
    property var selectedItem: null
    property QtObject fileManager: null
    
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        
        GridView {
            id: gridView
            anchors.fill: parent
            anchors.rightMargin: verticalScrollBar.visible ? verticalScrollBar.width : 0
            clip: true
            
            cellWidth: model && model.viewMode === FileListModel.LargeIconView ? 160 : parent.width
            cellHeight: model && model.viewMode === FileListModel.LargeIconView ? 160 : 40
            
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
                            Layout.preferredHeight: 100
                            Layout.alignment: Qt.AlignHCenter
                            
                            Image {
                                id: previewImage
                                anchors.centerIn: parent
                                width: 80
                                height: 80
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
                                
                                onStatusChanged: {
                                    switch (status) {
                                        case Image.Loading:
                                            loadingTimer.restart();  // 开始计时
                                            break;
                                        case Image.Ready:
                                            loadingTimer.stop();  // 停止计时
                                            break;
                                        case Image.Error:
                                            console.error("预览加载失败:", delegateItem.fileName, source);
                                            loadingTimer.stop();  // 停止计时
                                            source = getFileIcon(delegateItem);
                                            break;
                                    }
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
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
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
                        fileName: fileName,
                        fileType: fileType,
                        filePath: filePath,
                        displaySize: displaySize,
                        displayDate: displayDate
                    }
                }
                
                onPressAndHold: function(mouse) {
                    gridView.currentIndex = index
                    root.selectedItem = {
                        fileName: fileName,
                        fileType: fileType,
                        filePath: filePath,
                        displaySize: displaySize,
                        displayDate: displayDate
                    }
                    contextMenu.popup()
                }
                
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        gridView.currentIndex = index
                        root.selectedItem = {
                            fileName: fileName,
                            fileType: fileType,
                            filePath: filePath,
                            displaySize: displaySize,
                            displayDate: displayDate
                        }
                        contextMenu.popup()
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
                            return type.match(/^(jpg|jpeg|png|gif|bmp)$/) || 
                                   type.match(/^(mp4|avi|mkv|mov)$/)
                        }
                        
                        onTriggered: {
                            console.log("尝试打开文件:", delegateItem.filePath, 
                                      "类型:", delegateItem.fileType)
                            if (root.fileManager) {
                                console.log("fileManager 可用")
                                root.fileManager.openFile(delegateItem.filePath, delegateItem.fileType)
                            } else {
                                console.error("fileManager 未定义!")
                            }
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
                            console.log("尝试打开文件夹:", delegateItem.filePath)
                            if (delegateItem.filePath) {
                                const normalizedPath = delegateItem.filePath.replace(/\\/g, '/')
                                const folderPath = normalizedPath.substring(0, normalizedPath.lastIndexOf('/'))
                                
                                if (folderPath) {
                                    console.log("打开文件夹:", folderPath)
                                    Qt.openUrlExternally("file:///" + folderPath)
                                } else {
                                    console.error("无法获取文件夹路径")
                                }
                            } else {
                                console.error("文件路径为空")
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
                            console.log("文件信息:", JSON.stringify({
                                fileName: delegateItem.fileName,
                                fileType: delegateItem.fileType,
                                filePath: delegateItem.filePath,
                                displaySize: delegateItem.displaySize,
                                displayDate: delegateItem.displayDate
                            }, null, 2))
                            console.log("FileManager 状态:", root.fileManager ? "已定义" : "未定义")
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
    
    Component.onCompleted: {
        console.log("[FileList] 组件初始化完成")
        if (model) {
            console.log("[FileList] 当前视图模式:", model.viewMode)
        }
    }
    
    Connections {
        target: model
        function onViewModeChanged() {
            if (model) {
                console.log("[FileList] 视图模式变更为:", model.viewMode)
            }
        }
    }
    
    function getFileIcon(item) {
        if (!item || !item.fileType) {
            return "qrc:/resources/images/file.svg"
        }
        
        const type = String(item.fileType).toLowerCase()
        if (type.match(/^(jpg|jpeg|png|gif|bmp)$/)) {
            return "qrc:/resources/images/image.svg"
        } else if (type.match(/^(mp4|avi|mkv|mov)$/)) {
            return "qrc:/resources/images/video.svg"
        } else if (type.match(/^(txt|doc|docx|pdf)$/)) {
            return "qrc:/resources/images/text.svg"
        }
        return "qrc:/resources/images/file.svg"
    }
}
