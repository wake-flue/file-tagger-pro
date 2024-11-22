import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    required property QtObject style
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 添加选中类型的数组
    property var selectedTypes: []
    
    // 更新过滤器文本
    function updateFilterText() {
        if (!settings) return;
        
        let filters = []
        selectedTypes.forEach(type => {
            if (type === "all") {
                filters.push("*.*")
            } else {
                let extensions = settings[type + "Filter"] || []
                filters.push(...extensions.map(ext => "*." + ext))
            }
        })
        
        // 只更新输入框的文本，不直接应用
        filterInput.isInternalUpdate = true
        filterInput.text = filters.join(";")
        filterInput.isInternalUpdate = false
    }
    
    // 标题
    Label {
        text: qsTr("文件类型设置")
        font {
            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
            bold: true
        }
        color: style?.textColor ?? settingsStyle.defaultTextColor
    }
    
    // 说明文本
    Label {
        text: qsTr("选择要显示的文件类型，或直接输入文件扩展名")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        font {
            family: style?.fontFamily ?? settingsStyle.defaultFontFamily
            pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
        }
        color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
        opacity: settingsStyle.defaultOpacity
    }
    
    // 过滤器输入框
    ColumnLayout {
        Layout.fillWidth: true
        spacing: settingsStyle.defaultItemSpacing
        
        Label {
            text: qsTr("自定义筛选器")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
        }
        
        TextArea {
            id: filterInput
            text: settings?.fileFilter ?? ""
            placeholderText: qsTr("例如: *.jpg;*.png;*.gif")
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            selectByMouse: true
            wrapMode: TextArea.Wrap
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
            }
            
            background: Rectangle {
                implicitHeight: 80
                color: filterInput.enabled ? "white" : "#F0F0F0"
                border.color: filterInput.focus ? 
                    (style?.accentColor ?? settingsStyle.defaultAccentColor) : 
                    filterInput.hovered ? Qt.lighter(style?.accentColor ?? settingsStyle.defaultAccentColor, 1.5) :
                    (style?.borderColor ?? settingsStyle.defaultBorderColor)
                border.width: filterInput.focus ? 2 : 1
                radius: settingsStyle.defaultRadius
            }
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                visible: filterInput.contentHeight > filterInput.height
            }
            
            // 添加一个属性来防止重复更新
            property bool isInternalUpdate: false
            
            onTextChanged: {
                if (!settings || isInternalUpdate) return;
                // 移除自动应用的逻辑，只在点击应用按钮时更新
            }
        }
    }
    
    // 文件类型选择区域
    ColumnLayout {
        Layout.fillWidth: true
        spacing: settingsStyle.defaultItemSpacing
        
        Label {
            text: qsTr("常用文件类型")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
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
                        border.color: typeCheckBox.checked ? 
                            (style?.accentColor ?? settingsStyle.defaultAccentColor) : 
                            typeCheckBox.hovered ? Qt.lighter(style?.accentColor ?? settingsStyle.defaultAccentColor, 1.5) :
                            (style?.borderColor ?? settingsStyle.defaultBorderColor)
                        border.width: typeCheckBox.checked ? 2 : 1
                        color: typeCheckBox.checked ? Qt.alpha(style?.accentColor ?? settingsStyle.defaultAccentColor, 0.1) : "white"
                        
                        // 选中标记
                        Image {
                            source: "qrc:/resources/images/checkmark.svg"
                            width: 12
                            height: 12
                            anchors.centerIn: parent
                            visible: typeCheckBox.checked
                        }
                    }
                    
                    contentItem: RowLayout {
                        spacing: 8
                        anchors.left: parent.left
                        anchors.leftMargin: typeCheckBox.indicator.width + typeCheckBox.spacing
                        anchors.right: parent.right
                        anchors.rightMargin: 8
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
                                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                                pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                            }
                            color: typeCheckBox.checked ? 
                                (style?.accentColor ?? settingsStyle.defaultAccentColor) : 
                                (style?.textColor ?? settingsStyle.defaultTextColor)
                            Layout.fillWidth: true
                            elide: Text.ElideRight
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
    
    // 初始化组件
    Component.onCompleted: {
        if (!settings) return;
        
        // 解析当前过滤器
        let currentFilters = (settings.fileFilter || "").split(";").map(f => f.trim().toLowerCase())
        
        // 如果是全部文件
        if (currentFilters.length === 1 && currentFilters[0] === "*.*") {
            selectedTypes = ["all"]
        } else {
            // 创建类型映射
            let typeMap = {
                image: settings.imageFilter || [],
                video: settings.videoFilter || [],
                audio: settings.audioFilter || [],
                document: settings.documentFilter || [],
                archive: settings.archiveFilter || [],
                dev: settings.devFilter || []
            }
            
            // 检查每个类型
            Object.entries(typeMap).forEach(([type, extensions]) => {
                if (!extensions) return;
                let typeFilters = extensions.map(ext => "*." + ext.toLowerCase())
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
                    
                    // 设置标志防止触发更新
                    checkbox.checked = selectedTypes.includes(type)
                }
            }
        })
    }
    
    // 添加 fileManager 属性
    required property var fileManager
    
    // 在底部添加应用按钮
    Item {
        Layout.fillHeight: true  // 添加弹性空间
    }
    
    // 分隔线
    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: style?.borderColor ?? settingsStyle.defaultBorderColor
        opacity: 0.5
    }
    
    // 底部按钮区域
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        spacing: 8
        
        Item { Layout.fillWidth: true }  // 右对齐按钮
        
        Button {
            id: applyButton
            text: qsTr("应用")
            enabled: filterInput.text !== (settings?.fileFilter ?? "")  // 只有当过滤器发生变化时才启用
            
            background: Rectangle {
                implicitWidth: 80
                implicitHeight: 32
                radius: 4
                color: applyButton.enabled ? 
                       (applyButton.down ? Qt.darker(style?.accentColor ?? settingsStyle.defaultAccentColor, 1.1) :
                        applyButton.hovered ? Qt.lighter(style?.accentColor ?? settingsStyle.defaultAccentColor, 1.1) :
                        (style?.accentColor ?? settingsStyle.defaultAccentColor)) :
                       "#F0F0F0"
                
                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }
            
            contentItem: Text {
                text: applyButton.text
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
                color: applyButton.enabled ? "white" : style?.secondaryTextColor ?? "#666666"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                if (!settings) return;
                
                // 应用新的过滤器设置
                settings.setValue("fileFilter", filterInput.text)
                
                // 更新文件模型的过滤器
                if (fileManager && fileManager.fileModel) {
                    fileManager.fileModel.filterPattern = filterInput.text
                }
            }
        }
    }
} 