import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FileManager 1.0
import "../dialogs" as Dialogs

Rectangle {
    id: root
    color: "#ffffff"
    radius: 8

    // 必要的属性声明
    required property var style
    required property var selectedItem
    required property var settings
    
    // 添加标签相关属性
    property var fileTags: []
    property string currentFileId: ""
    
    // 添加公开的更新函数
    function refreshTags() {
        if (currentFileId) {
            updateTags()
        }
    }
    
    // 添加标签对话框更新处理
    Connections {
        target: fileTagDialog
        
        function onTagsUpdated(updatedFileId) {
            if (updatedFileId === currentFileId) {
                updateTags()
            }
        }
    }
    
    // 监听组件创建完成
    Component.onCompleted: {
        updateTags()
    }
    
    // 监听 selectedItem 变化
    onSelectedItemChanged: {
        if (selectedItem) {
            const props = {
                fileId: selectedItem.fileId,
                fileName: selectedItem.fileName,
                filePath: selectedItem.filePath,
                fileType: selectedItem.fileType,
                displaySize: selectedItem.displaySize,
                displayDate: selectedItem.displayDate
            }
            
            if (selectedItem.fileId) {
                currentFileId = String(selectedItem.fileId)
            } else {
                currentFileId = ""
                fileTags = []
            }
        } else {
            currentFileId = ""
            fileTags = []
        }
    }
    
    // 监听 currentFileId 变化
    onCurrentFileIdChanged: {
        if (currentFileId) {
            updateTags()
        }
    }
    
    // 更新标签的函数
    function updateTags() {
        if (!selectedItem || !currentFileId) {
            fileTags = []
            return
        }
        
        try {
            const tags = TagManager.getFileTagsById(currentFileId)
            
            if (!tags) {
                fileTags = []
                return
            }
            
            // 确保 tags 是数组
            if (!Array.isArray(tags)) {
                fileTags = []
                return
            }
            
            // 转换标签数据格式
            const processedTags = tags.map(tag => ({
                id: tag.id,
                name: tag.name,
                color: tag.color,
                description: tag.description
            }))
            
            fileTags = processedTags
        } catch (error) {
            fileTags = []
        }
    }
    
    // 计算预览区域的高度
    readonly property real previewHeight: Math.min(width * 0.75, height * 0.6)
    
    // 添加显示状态属性
    property bool isVisible: false
    
    // 添加动画效果
    x: isVisible ? 0 : parent.width
    Behavior on x {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // 预览区域
        Item {
            id: previewContainer
            Layout.fillWidth: true
            Layout.preferredHeight: root.previewHeight
            Layout.maximumHeight: root.height
            Layout.alignment: Qt.AlignTop

            // 阴影
            Rectangle {
                id: shadow
                anchors.fill: previewRect
                anchors.margins: -2
                color: "transparent"
                radius: previewRect.radius + 2

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    color: "#20000000"
                    radius: parent.radius
                }
            }

            // 预览容器
            Rectangle {
                id: previewRect
                anchors.fill: parent
                color: "#f8f9fa"
                border.color: "transparent"
                radius: 12
                clip: true

                // 预览图片或默认图标
                Image {
                    id: previewImage
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    fillMode: Image.PreserveAspectFit
                    sourceSize {
                        width: Math.min(1920, parent.width * Screen.devicePixelRatio)
                        height: Math.min(1920, parent.height * Screen.devicePixelRatio)
                    }
                    autoTransform: true
                    asynchronous: true
                    cache: true
                    smooth: true

                    source: {
                        if (!root.selectedItem) {
                            return "qrc:/resources/images/unselected-file.svg"
                        }
                        
                        const fileType = (root.selectedItem.fileType || "").toLowerCase()
                        
                        if (root.settings.imageFilter.includes(fileType)) {
                            return "file:///" + root.selectedItem.filePath.replace(/\\/g, '/')
                        } else if (root.settings.videoFilter.includes(fileType)) {
                            return "qrc:/resources/images/video.svg"
                        } else if (root.settings.audioFilter.includes(fileType)) {
                            return "qrc:/resources/images/audio.svg"
                        } else if (root.settings.documentFilter.includes(fileType)) {
                            return "qrc:/resources/images/text.svg"
                        } else if (root.settings.archiveFilter.includes(fileType)) {
                            return "qrc:/resources/images/archive.svg"
                        } else if (root.settings.devFilter.includes(fileType)) {
                            return "qrc:/resources/images/code.svg"
                        }
                        
                        return root.selectedItem.fileIcon || "qrc:/resources/images/unselected-file.svg"
                    }

                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.warn("Error loading image:", source)
                            source = "qrc:/resources/images/unselected-file.svg"
                        }
                    }

                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                // 加载指示器
                BusyIndicator {
                    id: loadingIndicator
                    anchors.centerIn: parent
                    running: previewImage.status === Image.Loading
                    visible: running
                    width: 32
                    height: 32
                }

                // 错误提示
                Rectangle {
                    anchors.fill: parent
                    color: "#fff5f5"
                    visible: previewImage.status === Image.Error
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Image {
                            anchors.horizontalCenter: parent.horizontalCenter
                            source: "qrc:/resources/images/error.svg"
                            sourceSize.width: 32
                            sourceSize.height: 32
                            opacity: 0.6
                        }
                        
                        Text {
                            text: "图片加载失败"
                            color: "#ff4d4f"
                            font.pixelSize: root.style.defaultFontSize
                            font.family: root.style.fontFamily
                        }
                    }
                }
            }
        }

        // 文件信息区域
        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: scrollView.width
                spacing: 16

                // 标题栏
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Layout.bottomMargin: 4

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: "#f0f2f5"

                        Image {
                            anchors.centerIn: parent
                            source: "qrc:/resources/images/file.svg"
                            sourceSize.width: 16
                            sourceSize.height: 16
                            opacity: 0.8
                        }
                    }

                    Label {
                        text: "文件详情"
                        font {
                            family: root.style.fontFamily
                            bold: true
                            pixelSize: root.style.defaultFontSize + 2
                        }
                        color: root.style.textColor
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: root.style.borderColor
                        opacity: 0.3
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                // 文件详情内容
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 12

                    // 文件名（占据两列）
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        implicitHeight: fileNameColumn.implicitHeight + 24
                        color: "#f8f9fa"
                        radius: 8
                        
                        ColumnLayout {
                            id: fileNameColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                            spacing: 6
                            
                            RowLayout {
                                spacing: 8
                                
                                Image {
                                    source: "qrc:/resources/images/file.svg"
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "文件名"
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize - 1
                                    }
                                    color: root.style.secondaryTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.fileName || "-") : "-"
                                font {
                                    family: root.style.fontFamily
                                    pixelSize: root.style.defaultFontSize
                                    weight: Font.Medium
                                }
                                color: root.style.textColor
                                Layout.fillWidth: true
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }

                    // 标签（占据两列）
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        implicitHeight: tagsColumn.implicitHeight + 24
                        color: "#f8f9fa"
                        radius: 8
                        visible: true

                        ColumnLayout {
                            id: tagsColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                            spacing: 6

                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                
                                Image {
                                    source: "qrc:/resources/images/tag.svg"
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "标签"
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize - 1
                                    }
                                    color: root.style.secondaryTextColor
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Label {
                                    text: root.fileTags.length > 0 ? root.fileTags.length + "个标签" : ""
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize - 1
                                    }
                                    color: root.style.secondaryTextColor
                                    visible: root.fileTags.length > 0
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: true

                                Repeater {
                                    model: root.fileTags
                                    delegate: Rectangle {
                                        width: tagText.width + 16
                                        height: 24
                                        radius: 12
                                        color: modelData.color
                                        opacity: 0.9

                                        Label {
                                            id: tagText
                                            anchors.centerIn: parent
                                            text: modelData.name || ""
                                            color: "#ffffff"
                                            font {
                                                family: root.style.fontFamily
                                                pixelSize: root.style.defaultFontSize - 1
                                            }
                                        }
                                    }
                                }

                                // 没有标签时显示的提示文本
                                Label {
                                    visible: root.fileTags.length === 0
                                    text: "暂无标签"
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize
                                    }
                                    color: root.style.secondaryTextColor
                                }
                            }
                        }
                    }

                    // 类型
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: typeColumn.implicitHeight + 24
                        color: "#f8f9fa"
                        radius: 8
                        
                        ColumnLayout {
                            id: typeColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                            spacing: 6
                            
                            RowLayout {
                                spacing: 8
                                
                                Image {
                                    source: "qrc:/resources/images/type.svg"
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "类型"
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize - 1
                                    }
                                    color: root.style.secondaryTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.fileType || "-") : "-"
                                font {
                                    family: root.style.fontFamily
                                    pixelSize: root.style.defaultFontSize
                                    weight: Font.Medium
                                }
                                color: root.style.textColor
                                Layout.fillWidth: true
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }

                    // 大小
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: sizeColumn.implicitHeight + 24
                        color: "#f8f9fa"
                        radius: 8
                        
                        ColumnLayout {
                            id: sizeColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                            spacing: 6
                            
                            RowLayout {
                                spacing: 8
                                
                                Image {
                                    source: "qrc:/resources/images/size.svg"
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "大小"
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize - 1
                                    }
                                    color: root.style.secondaryTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.displaySize || "-") : "-"
                                font {
                                    family: root.style.fontFamily
                                    pixelSize: root.style.defaultFontSize
                                    weight: Font.Medium
                                }
                                color: root.style.textColor
                                Layout.fillWidth: true
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }

                    // 修改时间（占据两列）
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        implicitHeight: timeColumn.implicitHeight + 24
                        color: "#f8f9fa"
                        radius: 8
                        
                        ColumnLayout {
                            id: timeColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 12
                            }
                            spacing: 6
                            
                            RowLayout {
                                spacing: 8
                                
                                Image {
                                    source: "qrc:/resources/images/time.svg"
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "修改时间"
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize - 1
                                    }
                                    color: root.style.secondaryTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.displayDate || "-") : "-"
                                font {
                                    family: root.style.fontFamily
                                    pixelSize: root.style.defaultFontSize
                                    weight: Font.Medium
                                }
                                color: root.style.textColor
                                Layout.fillWidth: true
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }
                }

                // 路径显示
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: pathColumn.implicitHeight + 24
                    color: "#f8f9fa"
                    radius: 8

                    ColumnLayout {
                        id: pathColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: 12
                        }
                        spacing: 6

                        RowLayout {
                            spacing: 8
                            
                            Image {
                                source: "qrc:/resources/images/path.svg"
                                sourceSize.width: 14
                                sourceSize.height: 14
                                opacity: 0.6
                            }
                            
                            Label {
                                text: "路径"
                                font {
                                    family: root.style.fontFamily
                                    pixelSize: root.style.defaultFontSize - 1
                                }
                                color: root.style.secondaryTextColor
                            }
                        }

                        Label {
                            id: pathLabel
                            text: root.selectedItem ? (root.selectedItem.filePath || "-") : "-"
                            font {
                                family: root.style.fontFamily
                                pixelSize: root.style.defaultFontSize
                                weight: Font.Medium
                            }
                            color: root.style.textColor
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }
        }
    }
} 