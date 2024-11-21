import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Qt.labs.settings 1.0
import "../components" as Components

Window {
    id: root
    title: qsTr("文件筛选")
    
    // 属性声明
    required property QtObject settings
    required property QtObject style
    
    property string currentFilter: settings.fileFilter
    
    // 添加选中类型的数组
    property var selectedTypes: []
    
    // 窗口属性
    width: 600
    height: 500
    minimumWidth: 600
    minimumHeight: 500
    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    modality: Qt.ApplicationModal
    color: style.backgroundColor
    
    // 信号声明
    signal accepted(string filter)
    signal rejected()
    
    // 更新过滤器文本
    function updateFilterText() {
        let filters = []
        selectedTypes.forEach(type => {
            if (type === "all") {
                filters.push("*.*")
            } else {
                let extensions = root.settings[type + "Filter"] || []
                filters.push(...extensions.map(ext => "*." + ext))
            }
        })
        filterInput.text = filters.join(";")
    }
    
    // 主内容区域
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        
        // 标题区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Image {
                source: "qrc:/resources/images/filter.svg"
                sourceSize.width: 20
                sourceSize.height: 20
                opacity: 0.7
            }
            
            Label {
                text: qsTr("文件类型筛选")
                font {
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize + 2
                    bold: true
                }
                color: root.style.textColor
            }
        }
        
        // 分隔线
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.style.borderColor
            opacity: 0.5
        }
        
        // 说明文本
        Label {
            text: qsTr("选择要显示的文件类型，或直接输入文件扩展名")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            font {
                family: root.style.fontFamily
                pixelSize: root.style.defaultFontSize
            }
            color: root.style.secondaryTextColor
        }
        
        // 过滤器输入框
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            Label {
                text: qsTr("自定义筛选器")
                font {
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize - 1
                }
                color: root.style.secondaryTextColor
            }
            
            TextArea {
                id: filterInput
                text: root.currentFilter
                placeholderText: qsTr("例如: *.jpg;*.png;*.gif")
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                selectByMouse: true
                wrapMode: TextArea.Wrap
                font {
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize
                }
                
                background: Rectangle {
                    implicitHeight: 80
                    color: filterInput.enabled ? "white" : "#F0F0F0"
                    border.color: filterInput.focus ? root.style.accentColor : 
                                filterInput.hovered ? Qt.lighter(root.style.accentColor, 1.5) :
                                root.style.borderColor
                    border.width: filterInput.focus ? 2 : 1
                    radius: 6
                    
                    // 添加过渡动画
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    visible: filterInput.contentHeight > filterInput.height
                }
                
                onTextChanged: {
                    root.currentFilter = text
                }
                
                // 添加回车键确认功能
                Keys.onReturnPressed: function(event) {
                    if (event.modifiers & Qt.ControlModifier) {
                        // Ctrl+Enter 添加换行
                        insert(cursorPosition, "\n")
                    } else {
                        // 普通回车确认
                        root.accept()
                    }
                }
                Keys.onEnterPressed: function(event) {
                    if (event.modifiers & Qt.ControlModifier) {
                        insert(cursorPosition, "\n")
                    } else {
                        root.accept()
                    }
                }
            }
        }
        
        // 文件类型选择区域
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            Label {
                text: qsTr("常用文件类型")
                font {
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize - 1
                }
                color: root.style.secondaryTextColor
            }
            
            Flow {
                id: typeFlow
                Layout.fillWidth: true
                spacing: 12
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                
                Repeater {
                    id: typeRepeater
                    model: [
                        { text: "图片", type: "image", icon: "qrc:/resources/images/image.svg" },
                        { text: "视频", type: "video", icon: "qrc:/resources/images/video.svg" },
                        { text: "音频", type: "audio", icon: "qrc:/resources/images/audio.svg" },
                        { text: "文档", type: "document", icon: "qrc:/resources/images/text.svg" },
                        { text: "压缩包", type: "archive", icon: "qrc:/resources/images/archive.svg" },
                        { text: "开发", type: "dev", icon: "qrc:/resources/images/code.svg" },
                        { text: "全部", type: "all", icon: "qrc:/resources/images/file.svg" }
                    ]
                    
                    CheckBox {
                        id: typeCheckBox
                        text: modelData.text
                        width: 160
                        height: 32
                        spacing: 8
                        
                        // 自定义样式
                        indicator: Rectangle {
                            implicitWidth: 18
                            implicitHeight: 18
                            radius: 4
                            border.color: typeCheckBox.checked ? root.style.accentColor : 
                                        typeCheckBox.hovered ? Qt.lighter(root.style.accentColor, 1.5) :
                                        root.style.borderColor
                            border.width: typeCheckBox.checked ? 2 : 1
                            color: typeCheckBox.checked ? Qt.alpha(root.style.accentColor, 0.1) : "white"
                            
                            // 选中标记
                            Image {
                                source: "qrc:/resources/images/checkmark.svg"
                                width: 12
                                height: 12
                                anchors.centerIn: parent
                                visible: typeCheckBox.checked
                                opacity: 0
                                
                                // 添加出现动画
                                NumberAnimation on opacity {
                                    running: typeCheckBox.checked
                                    from: 0
                                    to: 1
                                    duration: 200
                                }
                            }
                            
                            // 添加过渡动画
                            Behavior on border.color {
                                ColorAnimation { duration: 150 }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        contentItem: RowLayout {
                            spacing: 8
                            anchors.left: parent.left
                            anchors.leftMargin: typeCheckBox.indicator.width + typeCheckBox.spacing
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.topMargin: 18
                            height: parent.height
                            
                            Image {
                                source: modelData.icon
                                sourceSize.width: 16
                                sourceSize.height: 16
                                opacity: typeCheckBox.checked ? 1 : 0.7
                            }
                            
                            Text {
                                text: typeCheckBox.text
                                font {
                                    family: root.style.fontFamily
                                    pixelSize: root.style.defaultFontSize
                                }
                                color: typeCheckBox.checked ? root.style.accentColor : root.style.textColor
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }
                        
                        // 处理选中状态变化
                        onCheckedChanged: {
                            if (checked) {
                                if (modelData.type === "all") {
                                    // 如果选择"全部"，取消其他所有选择
                                    selectedTypes = ["all"]
                                    // 更新其他复选框状态
                                    for (let i = 0; i < parent.children.length; i++) {
                                        let checkbox = parent.children[i]
                                        if (checkbox !== this && checkbox instanceof CheckBox) {
                                            checkbox.checked = false
                                        }
                                    }
                                } else {
                                    // 如果选择其他类型，移除"全部"选项
                                    let allIndex = selectedTypes.indexOf("all")
                                    if (allIndex !== -1) {
                                        selectedTypes.splice(allIndex, 1)
                                        // 更新"全部"复选框状态
                                        for (let i = 0; i < parent.children.length; i++) {
                                            let checkbox = parent.children[i]
                                            if (checkbox instanceof CheckBox && 
                                                checkbox.text === "全部") {
                                                checkbox.checked = false
                                                break
                                            }
                                        }
                                    }
                                    selectedTypes.push(modelData.type)
                                }
                            } else {
                                let index = selectedTypes.indexOf(modelData.type)
                                if (index !== -1) {
                                    selectedTypes.splice(index, 1)
                                }
                            }
                            updateFilterText()
                        }
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // 分隔线
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.style.borderColor
            opacity: 0.5
        }
        
        // 底部按钮区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: qsTr("取消")
                implicitWidth: 90
                implicitHeight: 36
                
                background: Rectangle {
                    color: parent.down ? Qt.darker(root.style.backgroundColor, 1.1) :
                           parent.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: parent.down ? root.style.accentColor :
                                parent.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 6
                    
                    // 添加过渡动画
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    font {
                        family: root.style.fontFamily
                        pixelSize: root.style.defaultFontSize
                    }
                    color: parent.down || parent.hovered ? root.style.accentColor : root.style.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    // 添加颜色过渡
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                onClicked: root.reject()
            }
            
            Button {
                text: qsTr("确定")
                implicitWidth: 90
                implicitHeight: 36
                
                background: Rectangle {
                    color: parent.down ? Qt.darker(root.style.accentColor, 1.1) :
                           parent.hovered ? Qt.lighter(root.style.accentColor, 1.1) : 
                           root.style.accentColor
                    border.width: 0
                    radius: 6
                    
                    // 添加过渡动画
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
                
                contentItem: Text {
                    text: parent.text
                    font {
                        family: root.style.fontFamily
                        pixelSize: root.style.defaultFontSize
                    }
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: root.accept()
            }
        }
    }
    
    // 窗口关闭处理
    onClosing: {
        root.reject()
    }
    
    // 打开窗口
    function open() {
        // 重置选中状态
        selectedTypes = []
        
        // 解析当前过滤器
        let currentFilters = root.currentFilter.split(";").map(f => f.trim().toLowerCase())
        
        // 如果是全部文件
        if (currentFilters.length === 1 && currentFilters[0] === "*.*") {
            selectedTypes = ["all"]
        } else {
            // 创建类型映射
            let typeMap = {
                image: root.settings.imageFilter || [],
                video: root.settings.videoFilter || [],
                audio: root.settings.audioFilter || [],
                document: root.settings.documentFilter || [],
                archive: root.settings.archiveFilter || [],
                dev: root.settings.devFilter || []
            }
            
            // 检查每个类型
            Object.entries(typeMap).forEach(([type, extensions]) => {
                // 将扩展名转换为完整的过滤器格式（*.ext）
                let typeFilters = extensions.map(ext => "*." + ext.toLowerCase())
                
                // 检查是否该类型的任何扩展名在当前过滤器中
                let hasAllExtensions = typeFilters.some(filter => 
                    currentFilters.includes(filter)
                )
                
                if (hasAllExtensions) {
                    selectedTypes.push(type)
                }
            })
        }
        
        // 更新复选框状态
        Qt.callLater(() => {
            // 通过 Repeater 的 count 属性遍历所有项
            for (let i = 0; i < typeRepeater.count; i++) {
                let checkbox = typeRepeater.itemAt(i)
                if (checkbox && checkbox instanceof CheckBox) {
                    let type = checkbox.text === "全部" ? "all" : 
                              checkbox.text === "图片" ? "image" :
                              checkbox.text === "视频" ? "video" :
                              checkbox.text === "音频" ? "audio" :
                              checkbox.text === "文档" ? "document" :
                              checkbox.text === "压缩包" ? "archive" :
                              checkbox.text === "开发" ? "dev" : ""
                    
                    checkbox.checked = selectedTypes.includes(type)
                }
            }
        })
        
        // 计算居中位置并显示
        let parentWindow = Window.window
        if (parentWindow) {
            x = parentWindow.x + (parentWindow.width - width) / 2
            y = parentWindow.y + (parentWindow.height - height) / 2
        }
        
        root.visible = true
        filterInput.selectAll()
        filterInput.forceActiveFocus()
    }
    
    // 确认处理
    function accept() {
        root.settings.setValue("fileFilter", root.currentFilter)
        root.accepted(root.currentFilter)
        root.visible = false
    }
    
    // 取消处理
    function reject() {
        root.currentFilter = root.settings.fileFilter // 恢复原值
        root.rejected()
        root.visible = false
    }
}
