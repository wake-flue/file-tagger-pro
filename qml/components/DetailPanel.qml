import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import FileManager 1.0
import "../dialogs" as Dialogs
import ".." 1.0

Rectangle {
    id: root
    color: Style.backgroundColor
    radius: Style.radiusNormal
    border.color: Style.borderColor
    border.width: Style.borderWidth

    // 必要的属性声明
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

            // 处理视频播放
            if (selectedItem.fileType && root.settings.videoFilter.includes(selectedItem.fileType.toLowerCase())) {
                mediaPlayer.stop()
                mediaPlayer.source = "file:///" + selectedItem.filePath.replace(/\\/g, '/')
                mediaPlayer.play()
            } else {
                mediaPlayer.stop()
            }
        } else {
            currentFileId = ""
            fileTags = []
            mediaPlayer.stop()
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
        anchors.margins: Style.contentMargin
        spacing: Style.spacingLarge

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

                // 视频播放器
                MediaPlayer {
                    id: mediaPlayer
                    videoOutput: videoOutput
                    loops: MediaPlayer.Infinite
                    
                    onErrorOccurred: function(error, errorString) {
                        console.log("视频播放错误:", errorString)
                        // 如果发生错误，尝试重新加载视频
                        if (source != "") {
                            const currentSource = source
                            source = ""
                            Qt.callLater(function() {
                                source = currentSource
                            })
                        }
                    }

                    onSourceChanged: {
                        if (source != "") {
                            stop()
                            play()
                        }
                    }
                }

                // 视频输出区域
                Item {
                    id: videoContainer
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        bottom: videoControls.top
                        margins: 12
                    }

                    VideoOutput {
                        id: videoOutput
                        anchors.fill: parent
                        visible: root.selectedItem && root.settings.videoFilter.includes(root.selectedItem.fileType.toLowerCase())
                    }
                }

                // 视频控制面板
                Rectangle {
                    id: videoControls
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 12
                    }
                    height: 40
                    color: "#f0f2f5"
                    visible: videoOutput.visible
                    radius: 6

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        // 当前时间
                        Label {
                            text: {
                                const position = Math.floor(mediaPlayer.position / 1000)
                                const minutes = Math.floor(position / 60)
                                const seconds = position % 60
                                return `${minutes}:${seconds.toString().padStart(2, '0')}`
                            }
                            color: Style.textColor
                            font {
                                family: Style.fontFamily
                                pixelSize: Style.fontSizeSmall
                                weight: Font.Medium
                            }
                        }

                        // 进度条
                        Slider {
                            id: progressSlider
                            Layout.fillWidth: true
                            from: 0
                            to: mediaPlayer.duration
                            value: mediaPlayer.position
                            live: false

                            background: Rectangle {
                                x: progressSlider.leftPadding
                                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                                width: progressSlider.availableWidth
                                height: 3
                                radius: 1.5
                                color: Style.borderColor

                                Rectangle {
                                    width: progressSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Style.primaryColor
                                    radius: 1.5
                                }
                            }

                            handle: Rectangle {
                                x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                                y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                                width: 12
                                height: 12
                                radius: 6
                                color: Style.primaryColor
                                border.color: "white"
                                border.width: 2
                                opacity: progressSlider.pressed ? 1.0 : 0.8

                                Behavior on opacity {
                                    NumberAnimation { duration: 100 }
                                }
                            }

                            onMoved: {
                                if (pressed) {
                                    mediaPlayer.position = value
                                }
                            }
                        }

                        // 总时长
                        Label {
                            text: {
                                const duration = Math.floor(mediaPlayer.duration / 1000)
                                const minutes = Math.floor(duration / 60)
                                const seconds = duration % 60
                                return `${minutes}:${seconds.toString().padStart(2, '0')}`
                            }
                            color: Style.textColor
                            font {
                                family: Style.fontFamily
                                pixelSize: Style.fontSizeSmall
                                weight: Font.Medium
                            }
                        }

                        // 倍速选择
                        ComboBox {
                            id: speedComboBox
                            model: ["0.5x", "1.0x", "1.5x", "3.0x", "5.0x", "10.0x"]
                            currentIndex: 1
                            width: 64
                            height: 24
                            
                            // 移除原生下拉图标
                            indicator: null
                            
                            background: Rectangle {
                                color: speedComboBox.pressed ? Style.hoverColor : Style.backgroundColor
                                radius: 4
                                border.color: Style.borderColor
                                border.width: 1
                                
                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }
                            }

                            contentItem: Item {
                                Text {
                                    anchors.centerIn: parent
                                    text: speedComboBox.displayText
                                    color: Style.textColor
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                        weight: Font.Medium
                                    }
                                }
                            }

                            onCurrentTextChanged: {
                                const speed = parseFloat(currentText)
                                mediaPlayer.playbackRate = speed
                            }

                            popup: Popup {
                                y: speedComboBox.height + 4
                                width: speedComboBox.width
                                padding: 2

                                background: Rectangle {
                                    color: Style.backgroundColor
                                    radius: 4
                                    border.color: Style.borderColor
                                    border.width: 1
                                }

                                contentItem: ListView {
                                    implicitHeight: contentHeight
                                    model: speedComboBox.popup.visible ? speedComboBox.delegateModel : null
                                    currentIndex: speedComboBox.highlightedIndex
                                    spacing: 2

                                    delegate: ItemDelegate {
                                        width: speedComboBox.width - 4
                                        height: 24
                                        padding: 0
                                        x: 2

                                        contentItem: Text {
                                            text: modelData
                                            color: Style.textColor
                                            font {
                                                family: Style.fontFamily
                                                pixelSize: Style.fontSizeSmall
                                                weight: Font.Medium
                                            }
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        background: Rectangle {
                                            color: parent.hovered ? Style.hoverColor : "transparent"
                                            radius: 2
                                            
                                            Behavior on color {
                                                ColorAnimation { duration: 100 }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

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
                    visible: !videoOutput.visible

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
                            font.pixelSize: Style.fontSizeNormal
                            font.family: Style.fontFamily
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
                            family: Style.fontFamily
                            bold: true
                            pixelSize: Style.fontSizeNormal
                        }
                        color: Style.textColor
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Style.borderColor
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
                                    sourceSize.width: Style.iconSizeMini
                                    sourceSize.height: Style.iconSizeMini
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "文件名"
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                    }
                                    color: Style.lightTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.fileName || "-") : "-"
                                font {
                                    family: Style.fontFamily
                                    pixelSize: Style.fontSizeSmall
                                    weight: Font.Medium
                                }
                                color: Style.textColor
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
                                    sourceSize.width: Style.iconSizeMini
                                    sourceSize.height: Style.iconSizeMini
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "标签"
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                    }
                                    color: Style.lightTextColor
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Label {
                                    text: root.fileTags.length > 0 ? root.fileTags.length + "个标签" : ""
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                    }
                                    color: Style.lightTextColor
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
                                                family: Style.fontFamily
                                                pixelSize: Style.fontSizeSmall
                                            }
                                        }
                                    }
                                }

                                // 没有标签时显示的提示文本
                                Label {
                                    visible: root.fileTags.length === 0
                                    text: "暂无标签"
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                    }
                                    color: Style.lightTextColor
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
                                    sourceSize.width: Style.iconSizeMini
                                    sourceSize.height: Style.iconSizeMini
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "类型"
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                    }
                                    color: Style.lightTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.fileType || "-") : "-"
                                font {
                                    family: Style.fontFamily
                                    pixelSize: Style.fontSizeSmall
                                    weight: Font.Medium
                                }
                                color: Style.textColor
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
                                    sourceSize.width: Style.iconSizeMini
                                    sourceSize.height: Style.iconSizeMini
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "大小"
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                    }
                                    color: Style.lightTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.displaySize || "-") : "-"
                                font {
                                    family: Style.fontFamily
                                    pixelSize: Style.fontSizeSmall
                                    weight: Font.Medium
                                }
                                color: Style.textColor
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
                                    sourceSize.width: Style.iconSizeMini
                                    sourceSize.height: Style.iconSizeMini
                                    opacity: 0.6
                                }
                                
                                Label {
                                    text: "修改时间"
                                    font {
                                        family: Style.fontFamily
                                        pixelSize: Style.fontSizeSmall
                                    }
                                    color: Style.lightTextColor
                                }
                            }
                            
                            Label {
                                text: root.selectedItem ? (root.selectedItem.displayDate || "-") : "-"
                                font {
                                    family: Style.fontFamily
                                    pixelSize: Style.fontSizeSmall
                                    weight: Font.Medium
                                }
                                color: Style.textColor
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
                                sourceSize.width: Style.iconSizeMini
                                sourceSize.height: Style.iconSizeMini
                                opacity: 0.6
                            }
                            
                            Label {
                                text: "路径"
                                font {
                                    family: Style.fontFamily
                                    pixelSize: Style.fontSizeSmall
                                }
                                color: Style.lightTextColor
                            }
                        }

                        Label {
                            id: pathLabel
                            text: root.selectedItem ? (root.selectedItem.filePath || "-") : "-"
                            font {
                                family: Style.fontFamily
                                pixelSize: Style.fontSizeSmall
                                weight: Font.Medium
                            }
                            color: Style.textColor
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