import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    
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
        
        // 只有当新的过滤器文本与当前文本不同时才更新
        let newText = filters.join(";")
        if (newText !== filterInput.text) {
            filterInput.text = newText
        }
    }
    
    // 标题和说明
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        Label {
            text: qsTr("文件类型设置")
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.titleFontSize
                bold: true
            }
            color: settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("选择要显示的文件类型，或直接输入文件扩展名")
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
    
    // 过滤器输入框
    ColumnLayout {
        Layout.fillWidth: true
        spacing: settingsStyle.defaultItemSpacing
        
        Label {
            text: qsTr("自定义筛选器")
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: settingsStyle.defaultSecondaryTextColor
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            
            TextArea {
                id: filterInput
                placeholderText: qsTr("例如: *.jpg;*.png;*.gif")
                selectByMouse: true
                wrapMode: TextArea.Wrap
                
                font {
                    family: settingsStyle.defaultFontFamily
                    pixelSize: settingsStyle.defaultFontSize
                }
                
                background: Rectangle {
                    implicitHeight: 80
                    color: filterInput.enabled ? settingsStyle.defaultInputBackgroundColor : "#F0F0F0"
                    border.color: filterInput.focus ? 
                        settingsStyle.defaultInputFocusBorderColor : 
                        filterInput.hovered ? settingsStyle.defaultButtonHoverBorderColor :
                        settingsStyle.defaultInputBorderColor
                    border.width: filterInput.focus ? 2 : 1
                    radius: settingsStyle.defaultRadius
                }
                
                property bool isInternalUpdate: false
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
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: settingsStyle.defaultSecondaryTextColor
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
                    
                    indicator: Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 4
                        border.color: typeCheckBox.checked ? 
                            settingsStyle.defaultAccentColor : 
                            typeCheckBox.hovered ? Qt.lighter(settingsStyle.defaultAccentColor, 1.5) :
                            settingsStyle.defaultInputBorderColor
                        border.width: typeCheckBox.checked ? 2 : 1
                        color: typeCheckBox.checked ? Qt.alpha(settingsStyle.defaultAccentColor, 0.1) : 
                               settingsStyle.defaultInputBackgroundColor
                        
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
                                family: settingsStyle.defaultFontFamily
                                pixelSize: settingsStyle.defaultFontSize
                            }
                            color: typeCheckBox.checked ? 
                                settingsStyle.defaultAccentColor : 
                                settingsStyle.defaultTextColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    
                    onCheckedChanged: {
                        if (checked) {
                            if (modelData.type === "all") {
                                selectedTypes = ["all"]
                                for (let i = 0; i < parent.children.length; i++) {
                                    let checkbox = parent.children[i]
                                    if (checkbox !== this && checkbox instanceof CheckBox) {
                                        checkbox.checked = false
                                    }
                                }
                            } else {
                                let allIndex = selectedTypes.indexOf("all")
                                if (allIndex !== -1) {
                                    selectedTypes.splice(allIndex, 1)
                                    for (let i = 0; i < parent.children.length; i++) {
                                        let checkbox = parent.children[i]
                                        if (checkbox instanceof CheckBox && 
                                            checkbox.text === "全部") {
                                            checkbox.checked = false
                                            break
                                        }
                                    }
                                }
                                if (!selectedTypes.includes(modelData.type)) {
                                    selectedTypes.push(modelData.type)
                                }
                            }
                        } else {
                            let index = selectedTypes.indexOf(modelData.type)
                            if (index !== -1) {
                                selectedTypes.splice(index, 1)
                            }
                        }
                        selectedTypes = [...new Set(selectedTypes)]
                        updateFilterText()
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
    
    // 底部按钮区域
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        spacing: 8
        
        Item { Layout.fillWidth: true }
        
        Button {
            id: applyButton
            text: qsTr("应用")
            enabled: filterInput.text !== (settings?.fileFilter ?? "")
            
            background: Rectangle {
                implicitWidth: 80
                implicitHeight: settingsStyle.defaultButtonHeight
                radius: settingsStyle.defaultRadius
                color: applyButton.enabled ? 
                       (applyButton.down ? Qt.darker(settingsStyle.defaultAccentColor, 1.1) :
                        applyButton.hovered ? Qt.lighter(settingsStyle.defaultAccentColor, 1.1) :
                        settingsStyle.defaultAccentColor) :
                       "#F0F0F0"
                
                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }
            
            contentItem: Text {
                text: applyButton.text
                font {
                    family: settingsStyle.defaultFontFamily
                    pixelSize: settingsStyle.defaultFontSize
                }
                color: applyButton.enabled ? "white" : settingsStyle.defaultSecondaryTextColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                if (!settings) return;
                settings.setValue("fileFilter", filterInput.text)
                if (fileManager && fileManager.fileModel) {
                    fileManager.fileModel.filterPattern = filterInput.text
                }
            }
        }
    }
    
    // 初始化组件
    Component.onCompleted: {
        if (!settings) return;
        
        let currentFilters = (settings.fileFilter || "").split(";").map(f => f.trim().toLowerCase())
        
        // 设置初始选中状态
        if (currentFilters.length === 1 && currentFilters[0] === "*.*") {
            selectedTypes = ["all"]
        } else {
            let typeMap = {
                image: settings.imageFilter || [],
                video: settings.videoFilter || [],
                audio: settings.audioFilter || [],
                document: settings.documentFilter || [],
                archive: settings.archiveFilter || [],
                dev: settings.devFilter || []
            }
            
            Object.entries(typeMap).forEach(([type, extensions]) => {
                if (!extensions) return;
                let typeFilters = extensions.map(ext => "*." + ext.toLowerCase())
                let hasAllExtensions = typeFilters.every(filter => 
                    currentFilters.includes(filter)
                )
                if (hasAllExtensions) {
                    selectedTypes.push(type)
                }
            })
        }
        
        // 设置复选框状态
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
                    
                    checkbox.checked = selectedTypes.includes(type)
                }
            }
            
            // 最后设置文本
            filterInput.text = settings.fileFilter || ""
        })
    }
    
    required property var fileManager
} 