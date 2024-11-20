import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FileManager 1.0

Item {
    id: root
    
    property alias model: gridView.model
    property var selectedItem: null
    
    GridView {
        id: gridView
        anchors.fill: parent
        clip: true
        
        cellWidth: {
            if (!model) return width
            switch(model.viewMode) {
                case FileListModel.ListView:
                    return width
                case FileListModel.LargeIconView:
                    return 120
                default:
                    return 80
            }
        }
        
        cellHeight: {
            if (!model) return 40
            switch(model.viewMode) {
                case FileListModel.ListView:
                    return 40
                case FileListModel.LargeIconView:
                    return 100
                default:
                    return 60
            }
        }
        
        delegate: ItemDelegate {
            id: delegateItem
            width: gridView.cellWidth
            height: gridView.cellHeight
            
            required property int index
            required property string fileName
            required property string fileType
            required property string filePath
            required property string displaySize
            required property string displayDate
            
            contentItem: Loader {
                sourceComponent: gridView.model && 
                               gridView.model.viewMode === FileListModel.LargeIconView ? 
                               largeIconLayout : listLayout
            }
            
            Component {
                id: listLayout
                RowLayout {
                    spacing: 8
                    width: delegateItem.width
                    height: delegateItem.height
                    
                    Image {
                        source: getFileIcon(delegateItem)
                        sourceSize.width: 24
                        sourceSize.height: 24
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Label {
                        text: delegateItem.fileName
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Label {
                        text: delegateItem.displaySize
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 80
                    }
                    
                    Label {
                        text: delegateItem.displayDate
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 150
                    }
                }
            }
            
            Component {
                id: largeIconLayout
                ColumnLayout {
                    spacing: 4
                    width: delegateItem.width
                    height: delegateItem.height
                    
                    Image {
                        source: getFileIcon(delegateItem)
                        sourceSize.width: 64
                        sourceSize.height: 64
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Label {
                        text: delegateItem.fileName
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.margins: 4
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
