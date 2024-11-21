import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window

Window {
    id: root
    title: qsTr("视频雪碧图")
    width: 1000
    height: 750
    visible: false
    minimumWidth: 800
    minimumHeight: 600
    
    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    modality: Qt.ApplicationModal
    color: "#ffffff"
    
    required property var style
    required property string filePath
    required property var fileManager
    
    property int spriteCount: 12
    property var spritePaths: []
    property var presetCounts: [12, 16, 20, 24, 28, 32]
    
    // 窗口方法
    function open() {
        x = Screen.width / 2 - width / 2
        y = Screen.height / 2 - height / 2
        visible = true
        if (filePath) autoGenerateTimer.start()
    }
    
    function close() {
        autoGenerateTimer.stop()
        visible = false
    }
    
    signal accepted()
    signal rejected()
    
    Timer {
        id: autoGenerateTimer
        interval: 100
        repeat: false
        onTriggered: generateSprites()
    }
    
    function generateSprites() {
        if (!busyIndicator.running) {
            busyIndicator.running = true
            gridView.model = []
            fileManager.generateVideoSprites(root.filePath, root.spriteCount)
        }
    }
    
    // 添加窗口尺寸变化监听
    onWidthChanged: updateGridLayout()
    onHeightChanged: updateGridLayout()
    
    // 修改布局计算函数
    function updateGridLayout() {
        // 计算可用空间
        const availableWidth = gridView.width - gridView.anchors.margins * 2
        const spacing = 16  // 期望的图片间距
        
        // 计算每列的宽度（考虑间距）
        const columnCount = 4
        const totalSpacing = spacing * (columnCount - 1)
        const cellWidth = (availableWidth - totalSpacing) / columnCount
        
        // 更新 GridView 的属性
        gridView.columnSpacing = spacing
        gridView.rowSpacing = spacing
        gridView.cellWidth = cellWidth
        
        // 遍历所有可见项，更新其高度
        let maxRowHeight = 0
        for (let i = 0; i < gridView.count; i++) {
            let item = gridView.itemAtIndex(i)
            if (item && item.imageLoader.status === Image.Ready) {
                // 计算新的高度
                const newHeight = cellWidth * (item.imageLoader.sourceSize.height / item.imageLoader.sourceSize.width)
                item.height = newHeight
                maxRowHeight = Math.max(maxRowHeight, newHeight)
            }
        }
        
        // 设置 GridView 的 cellHeight，确保有足够的间距
        if (maxRowHeight > 0) {
            gridView.cellHeight = maxRowHeight + gridView.rowSpacing
        }
        
        // 强制重新布局
        gridView.forceLayout()
    }
    
    // 主布局
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // 工具栏
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "#ffffff"
            radius: 4
            border.color: root.style.borderColor
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16
                
                Label {
                    text: qsTr("截图数量:")
                    font {
                        family: root.style.fontFamily
                        pixelSize: root.style.defaultFontSize
                        bold: true
                    }
                    color: root.style.textColor
                }
                
                ComboBox {
                    id: countComboBox
                    model: root.presetCounts
                    currentIndex: root.presetCounts.indexOf(root.spriteCount)
                    
                    Layout.preferredWidth: 100
                    
                    background: Rectangle {
                        implicitWidth: 100
                        implicitHeight: 32
                        border.color: countComboBox.pressed ? root.style.accentColor : 
                                    countComboBox.hovered ? root.style.accentColor : 
                                    root.style.borderColor
                        border.width: countComboBox.pressed || countComboBox.hovered ? 2 : 1
                        radius: 4
                        color: countComboBox.pressed ? Qt.lighter(root.style.accentColor, 1.9) :
                               countComboBox.hovered ? Qt.lighter(root.style.accentColor, 1.95) :
                               "#ffffff"
                        
                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }
                    }
                    
                    contentItem: Text {
                        text: countComboBox.displayText
                        font: countComboBox.font
                        color: root.style.textColor
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    
                    onCurrentValueChanged: root.spriteCount = currentValue
                }
                
                Button {
                    text: qsTr("生成")
                    enabled: root.filePath && !busyIndicator.running
                    
                    background: Rectangle {
                        implicitWidth: 80
                        implicitHeight: 32
                        color: parent.enabled ? (parent.pressed ? Qt.darker(root.style.accentColor, 1.1) :
                               parent.hovered ? root.style.accentColor :
                               Qt.lighter(root.style.accentColor, 1.1)) :
                               Qt.lighter(root.style.accentColor, 1.5)
                        radius: 4
                        
                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font {
                            family: root.style.fontFamily
                            pixelSize: root.style.defaultFontSize
                            bold: true
                        }
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: generateSprites()
                }
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: qsTr("关闭")
                    
                    background: Rectangle {
                        implicitWidth: 80
                        implicitHeight: 32
                        color: parent.pressed ? Qt.darker("#f0f0f0", 1.1) :
                               parent.hovered ? "#f0f0f0" : "#ffffff"
                        border.color: parent.pressed ? root.style.accentColor :
                                    parent.hovered ? root.style.accentColor :
                                    root.style.borderColor
                        border.width: parent.pressed || parent.hovered ? 2 : 1
                        radius: 4
                        
                        Behavior on color {
                            ColorAnimation { duration: 100 }
                        }
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        font {
                            family: root.style.fontFamily
                            pixelSize: root.style.defaultFontSize
                        }
                        color: root.style.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        root.rejected()
                        root.close()
                    }
                }
            }
        }
        
        // 预览区域
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            background: Rectangle {
                color: "#f8f9fa"
                radius: 4
                border.color: root.style.borderColor
                border.width: 1
            }
            
            GridView {
                id: gridView
                anchors.fill: parent
                anchors.margins: 16
                
                property real columnSpacing: 16
                property real rowSpacing: 16
                
                onModelChanged: {
                    Qt.callLater(function() {
                        updateGridLayout()
                    })
                }
                
                delegate: Item {
                    id: spriteItem
                    width: gridView.cellWidth
                    property alias imageLoader: imageLoader
                    
                    Image {
                        id: imageLoader
                        visible: false
                        source: modelData ? "file:///" + modelData : ""
                        asynchronous: true
                        cache: true
                        
                        onStatusChanged: {
                            if (status === Image.Ready) {
                                // 根据图片原始比例和当前宽度计算高度
                                const newHeight = spriteItem.width * (sourceSize.height / sourceSize.width)
                                spriteItem.height = newHeight
                                displayImage.source = source
                                
                                // 更新 GridView 的行高
                                Qt.callLater(function() {
                                    let maxHeight = 0
                                    // 计算当前行的最大高度
                                    const rowStart = Math.floor(index / 4) * 4
                                    const rowEnd = Math.min(rowStart + 4, gridView.count)
                                    for (let i = rowStart; i < rowEnd; i++) {
                                        const rowItem = gridView.itemAtIndex(i)
                                        if (rowItem) {
                                            maxHeight = Math.max(maxHeight, rowItem.height)
                                        }
                                    }
                                    // 设置单元格高度，包含间距
                                    gridView.cellHeight = maxHeight + gridView.rowSpacing
                                })
                            }
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        anchors.bottomMargin: gridView.rowSpacing
                        color: "#ffffff"
                        radius: 4
                        
                        Image {
                            id: displayImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                            
                            BusyIndicator {
                                anchors.centerIn: parent
                                running: parent.status === Image.Loading || 
                                        imageLoader.status === Image.Loading
                                visible: running
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 进度指示器
    Popup {
        id: progressPopup
        anchors.centerIn: parent
        width: 300
        height: 120
        modal: true
        visible: busyIndicator.running || progressBar.visible
        closePolicy: Popup.NoAutoClose
        
        background: Rectangle {
            color: "#ffffff"
            radius: 8
            border.color: root.style.borderColor
            border.width: 1
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            BusyIndicator {
                id: busyIndicator
                Layout.alignment: Qt.AlignHCenter
                running: false
            }
            
            ProgressBar {
                id: progressBar
                Layout.fillWidth: true
                visible: false
                from: 0
                to: 1.0
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("正在生成预览图...")
                font.pixelSize: root.style.defaultFontSize
            }
        }
    }
    
    // 快捷键
    Shortcut {
        sequence: "Esc"
        onActivated: {
            root.rejected()
            root.close()
        }
    }
    
    // 关闭事件处理
    onClosing: function(close) {
        autoGenerateTimer.stop()
        root.rejected()
    }
    
    // 连接文件管理器信号
    Connections {
        target: fileManager
        
        function onSpritesGenerated(paths) {
            busyIndicator.running = false
            progressBar.visible = false
            root.spritePaths = paths
            
            // 延迟设置模型，确保布局正确计算
            Qt.callLater(function() {
                gridView.model = paths
                updateGridLayout()
            })
        }
        
        function onSpriteProgress(current, total) {
            progressBar.value = current / total
            progressBar.visible = true
        }
    }
    
    // 组件完成加载后初始化布局
    Component.onCompleted: {
        Qt.callLater(updateGridLayout)
    }
} 