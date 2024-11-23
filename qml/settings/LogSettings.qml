import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    required property QtObject style
    required property var fileManager
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 标题和说明
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        Label {
            text: qsTr("日志设置")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.titleFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("查看和管理应用程序运行日志")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
    
    // 工具栏
    Rectangle {
        Layout.fillWidth: true
        height: settingsStyle.toolbarHeight
        
        RowLayout {
            anchors {
                fill: parent
                margins: settingsStyle.defaultItemSpacing
            }
            spacing: settingsStyle.defaultItemSpacing
            
            Label {
                text: qsTr("日志级别:")
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
                color: style?.textColor ?? settingsStyle.defaultTextColor
            }
            
            ComboBox {
                id: logLevelFilter
                model: [
                    { text: qsTr("调试"), value: 0 },
                    { text: qsTr("信息"), value: 1 },
                    { text: qsTr("警告"), value: 2 },
                    { text: qsTr("错误"), value: 3 },
                    { text: qsTr("致命"), value: 4 }
                ]
                textRole: "text"
                valueRole: "value"
                
                implicitWidth: 120
                implicitHeight: settingsStyle.comboBoxHeight
                leftPadding: settingsStyle.comboBoxLeftPadding
                rightPadding: settingsStyle.comboBoxRightPadding
                
                indicator: Item { }
                
                background: Rectangle {
                    implicitWidth: parent.implicitWidth
                    implicitHeight: parent.implicitHeight
                    color: parent.down ? settingsStyle.comboBoxPressedColor :
                           parent.hovered ? settingsStyle.comboBoxHoverColor :
                           settingsStyle.comboBoxNormalColor
                    border.color: parent.visualFocus ? settingsStyle.comboBoxFocusBorderColor :
                                 parent.down || parent.hovered ? settingsStyle.defaultAccentColor :
                                 settingsStyle.comboBoxBorderColor
                    border.width: parent.visualFocus ? 2 : 1
                    radius: settingsStyle.defaultRadius
                    
                    // 下拉箭头
                    Image {
                        x: parent.width - width - 8
                        y: (parent.height - height) / 2
                        width: settingsStyle.comboBoxIndicatorSize
                        height: settingsStyle.comboBoxIndicatorSize
                        source: "qrc:/resources/images/dropdown.svg"
                        sourceSize: Qt.size(width, height)
                    }
                }
                
                contentItem: Label {
                    leftPadding: 4
                    text: logLevelFilter.displayText
                    font {
                        family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                    color: style?.textColor ?? settingsStyle.defaultTextColor
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                
                popup: Popup {
                    y: parent.height + 4
                    width: parent.width
                    height: Math.min(contentItem.implicitHeight, 200)
                    padding: 1
                    
                    background: Rectangle {
                        color: settingsStyle.comboBoxPopupBackgroundColor
                        border.color: settingsStyle.comboBoxPopupBorderColor
                        border.width: 1
                        radius: settingsStyle.defaultRadius
                    }
                    
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: logLevelFilter.popup.visible ? logLevelFilter.delegateModel : null
                        currentIndex: logLevelFilter.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                        
                        delegate: ItemDelegate {
                            width: parent.width
                            height: settingsStyle.comboBoxPopupItemHeight
                            padding: settingsStyle.comboBoxLeftPadding
                            highlighted: logLevelFilter.highlightedIndex === index
                            
                            background: Rectangle {
                                color: parent.highlighted ? settingsStyle.comboBoxItemHighlightColor :
                                       parent.hovered ? settingsStyle.comboBoxItemHoverColor :
                                       settingsStyle.comboBoxItemNormalColor
                            }
                            
                            contentItem: Label {
                                text: modelData.text
                                color: parent.highlighted ? settingsStyle.comboBoxItemHighlightedTextColor :
                                       settingsStyle.comboBoxItemTextColor
                                font {
                                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                                }
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                
                // 添加当前值属性
                property int currentLogLevel: 0
                
                // 监听选择变化
                onCurrentValueChanged: {
                    currentLogLevel = currentValue
                    updateLogList()
                }
            }
            
            TextField {
                id: searchInput
                Layout.preferredWidth: 200
                placeholderText: qsTr("搜索日志...")
                selectByMouse: true
                
                background: Rectangle {
                    implicitHeight: settingsStyle.defaultInputHeight
                    color: style?.inputBackgroundColor ?? settingsStyle.defaultInputBackgroundColor
                    border.color: parent.activeFocus ? 
                                (style?.accentColor ?? settingsStyle.defaultAccentColor) :
                                (style?.inputBorderColor ?? settingsStyle.defaultInputBorderColor)
                    border.width: parent.activeFocus ? 2 : 1
                    radius: settingsStyle.defaultRadius
                }
                
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
                
                // 添加搜索文本变化监听
                onTextChanged: {
                    updateLogList()
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                id: statsButton
                text: qsTr("日志统计")
                icon.source: "qrc:/resources/images/chart.svg"
                icon.width: 16
                icon.height: 16
                checkable: true
                
                background: Rectangle {
                    implicitWidth: settingsStyle.defaultButtonWidth
                    implicitHeight: settingsStyle.defaultButtonHeight
                    color: parent.down || parent.checked ? 
                           (style?.buttonPressedColor ?? settingsStyle.defaultButtonPressedColor) :
                           parent.hovered ? 
                           (style?.buttonHoverColor ?? settingsStyle.defaultButtonHoverColor) :
                           (style?.buttonNormalColor ?? settingsStyle.defaultButtonNormalColor)
                    border.color: parent.down || parent.checked ?
                                (style?.buttonPressedBorderColor ?? settingsStyle.defaultButtonPressedBorderColor) :
                                parent.hovered ?
                                (style?.buttonHoverBorderColor ?? settingsStyle.defaultButtonHoverBorderColor) :
                                (style?.buttonNormalBorderColor ?? settingsStyle.defaultButtonNormalBorderColor)
                    border.width: 1
                    radius: settingsStyle.defaultRadius
                }
                
                contentItem: RowLayout {
                    spacing: settingsStyle.defaultItemSpacing
                    Image {
                        source: parent.parent.icon.source
                        sourceSize.width: parent.parent.icon.width
                        sourceSize.height: parent.parent.icon.height
                    }
                    Label {
                        text: parent.parent.text
                        font {
                            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                            pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                        }
                        color: style?.textColor ?? settingsStyle.defaultTextColor
                    }
                }
            }
        }
    }
    
    // 日志列表
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: settingsStyle.logListBackgroundColor
        border.color: style?.borderColor ?? settingsStyle.defaultBorderColor
        border.width: 1
        radius: settingsStyle.defaultRadius
        
        ListView {
            id: logListView
            anchors.fill: parent
            anchors.margins: 1
            clip: true
            model: filteredLogs
            
            delegate: Rectangle {
                width: ListView.view.width
                height: logText.height + 2 * settingsStyle.logItemPadding
                color: index % 2 === 0 ? 
                       settingsStyle.logListBackgroundColor :
                       settingsStyle.logListAlternateColor
                
                Label {
                    id: logText
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: settingsStyle.logItemPadding
                    }
                    text: modelData
                    wrapMode: Text.Wrap
                    font {
                        family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                    color: {
                        if (modelData.includes("[ERROR]") || modelData.includes("[FATAL]"))
                            return settingsStyle.logErrorColor
                        if (modelData.includes("[WARN]"))
                            return settingsStyle.logWarningColor
                        if (modelData.includes("[DEBUG]"))
                            return settingsStyle.logDebugColor
                        return settingsStyle.logInfoColor
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }
        }
    }
    
    // 添加过滤后的日志列表属性
    property var filteredLogs: []
    
    // 添加日志过滤和更新函数
    function updateLogList() {
        if (!fileManager?.logger?.fileMessages) {
            filteredLogs = []
            return
        }
        
        const searchText = searchInput.text.toLowerCase()
        const logLevel = logLevelFilter.currentLogLevel
        
        filteredLogs = fileManager.logger.fileMessages.filter(message => {
            // 首先检查日志级别
            let messageLevel = 0
            if (message.includes("[FATAL]")) messageLevel = 4
            else if (message.includes("[ERROR]")) messageLevel = 3
            else if (message.includes("[WARN]")) messageLevel = 2
            else if (message.includes("[INFO]")) messageLevel = 1
            else if (message.includes("[DEBUG]")) messageLevel = 0
            
            // 如果消息级别低于选择的级别，过滤掉
            if (messageLevel < logLevel) return false
            
            // 然后检查搜索文本
            if (searchText && !message.toLowerCase().includes(searchText)) {
                return false
            }
            
            return true
        })
    }
    
    // 在组件完成加载时初始化日志列表
    Component.onCompleted: {
        updateLogList()
        
        // 调试信息
        console.log("LogSettings 初始化")
        console.log("fileManager:", fileManager)
        console.log("logger:", fileManager?.logger)
    }
    
    // 监听原始日志列表变化
    Connections {
        target: fileManager?.logger
        function onFileMessagesChanged() {
            updateLogList()
        }
    }
    
    // 添加日志文件信息显示
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        
        // 当前日志文件
        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            
            Label {
                text: qsTr("当前日志文件:")
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    bold: true
                }
                color: style?.textColor ?? settingsStyle.defaultTextColor
            }
            
            Label {
                text: fileManager?.logger?.getCurrentLogFile() ?? ""
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
                color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                Layout.fillWidth: true
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (parent.text) {
                            Qt.openUrlExternally("file:///" + parent.text)
                        }
                    }
                }
            }
        }
        
        // 历史日志文件
        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Layout.topMargin: 8
            
            Label {
                text: qsTr("历史日志文件:")
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    bold: true
                }
                color: style?.textColor ?? settingsStyle.defaultTextColor
            }
            
            Flow {
                Layout.fillWidth: true
                spacing: 8
                
                Repeater {
                    model: fileManager?.logger?.getLogFiles() ?? []
                    delegate: Label {
                        required property string modelData
                        
                        text: {
                            const logDir = fileManager?.logger?.getCurrentLogFile()?.replace(/[^\/\\]*$/, '') ?? ""
                            return logDir + modelData
                        }
                        font {
                            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                            pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                        }
                        color: style?.linkColor ?? "#0366d6"
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.text) {
                                    Qt.openUrlExternally("file:///" + parent.text)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 修改日志统计视图
    Rectangle {
        Layout.fillWidth: true
        height: statsColumn.implicitHeight + 16  // 根据内容自适应高度
        visible: statsButton.checked
        opacity: visible ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
        
        color: style?.backgroundColor ?? settingsStyle.defaultBackgroundColor
        border.color: style?.borderColor ?? settingsStyle.defaultBorderColor
        border.width: 1
        radius: settingsStyle.defaultRadius
        
        ColumnLayout {
            id: statsColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12
            
            // 标题
            Label {
                text: qsTr("日志统计信息")
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    bold: true
                }
                color: style?.textColor ?? settingsStyle.defaultTextColor
            }
            
            // 统计数据网格
            GridLayout {
                Layout.fillWidth: true
                columns: Math.max(2, Math.min(6, Math.floor(parent.width / 160))) // 自适应列数
                rowSpacing: 12
                columnSpacing: 16
                
                Repeater {
                    model: [
                        { label: "调试", key: "debug", color: "#6c757d", icon: "qrc:/resources/images/debug.svg" },
                        { label: "信息", key: "info", color: "#0366d6", icon: "qrc:/resources/images/info.svg" },
                        { label: "警告", key: "warn", color: "#ffc107", icon: "qrc:/resources/images/warning.svg" },
                        { label: "错误", key: "error", color: "#dc3545", icon: "qrc:/resources/images/error.svg" },
                        { label: "致命", key: "fatal", color: "#721c24", icon: "qrc:/resources/images/fatal.svg" },
                        { label: "总计", key: "total", color: style?.accentColor ?? "#0078D4", icon: "qrc:/resources/images/chart.svg" }
                    ]
                    
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 64
                        color: Qt.alpha(modelData.color, 0.05)
                        border.color: Qt.alpha(modelData.color, 0.2)
                        border.width: 1
                        radius: 6
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            
                            // 图标
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                color: Qt.alpha(modelData.color, 0.1)
                                radius: 4
                                
                                Image {
                                    anchors.centerIn: parent
                                    source: modelData.icon
                                    sourceSize: Qt.size(16, 16)
                                    opacity: 0.8
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Label {
                                    text: modelData.label
                                    font {
                                        family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                                        pixelSize: style?.defaultFontSize - 1 ?? settingsStyle.defaultFontSize - 1
                                    }
                                    color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
                                }
                                
                                Label {
                                    text: (fileManager?.logger?.logStats?.[modelData.key] ?? 0).toString()
                                    font {
                                        family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                                        pixelSize: style?.defaultFontSize + 4 ?? settingsStyle.defaultFontSize + 4
                                        bold: true
                                    }
                                    color: modelData.color
                                }
                            }
                        }
                    }
                }
            }
        }
    }
} 