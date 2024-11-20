import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FileManager 1.0

Item {
    id: root
    
    property alias model: gridView.model
    property var selectedItem: null
    
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
                                        console.warn("预览加载超时:", delegateItem.fileName);
                                        previewImage.source = getFileIcon(delegateItem);
                                    }
                                }
                                
                                onCurrentSourceChanged: {
                                    console.log("预览源变更 - 文件:", delegateItem.fileName, 
                                               "路径:", currentSource,
                                               "加载状态:", delegateItem.previewLoading);
                                    // 重置计时器
                                    loadingTimer.restart();
                                }
                                
                                onStatusChanged: {
                                    switch (status) {
                                        case Image.Loading:
                                            console.log("正在加载预览:", delegateItem.fileName);
                                            loadingTimer.restart();  // 开始计时
                                            break;
                                        case Image.Ready:
                                            console.log("预览加载完成:", delegateItem.fileName);
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
                
                onClicked: {
                    gridView.currentIndex = index
                    root.selectedItem = {
                        fileName: fileName,
                        fileType: fileType,
                        filePath: filePath,
                        displaySize: displaySize,
                        displayDate: displayDate
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
