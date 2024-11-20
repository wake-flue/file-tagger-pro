import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: filterDialog
    title: "设置筛选条件"
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true
    width: 600
    height: 600  // 固定高度
    
    property string currentFilter: ""
    property Settings settings
    property QtObject style
    
    // 预置的筛选项
    readonly property var presetFilters: {
        return {
            "所有文件": "*.*",
            "文档文件": "*.txt;*.doc;*.docx;*.pdf;*.rtf;*.md",
            "图片文件": "*.jpg;*.jpeg;*.png;*.gif;*.bmp;*.webp;*.tiff;*.svg;*.ico",
            "视频文件": "*.mp4;*.avi;*.mkv;*.mov;*.wmv;*.flv;*.webm;*.m4v;*.mpg;*.mpeg;*.3gp",
            "音频文件": "*.mp3;*.wav;*.flac;*.m4a;*.aac;*.ogg;*.wma;*.mid",
            "压缩文件": "*.zip;*.rar;*.7z;*.tar;*.gz;*.bz2",
            "开发文件": "*.cpp;*.h;*.java;*.py;*.js;*.html;*.css;*.json;*.xml"
        }
    }
    
    // 添加动画效果
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 200 }
    }
    
    background: Rectangle {
        color: style ? style.backgroundColor : "#FFFFFF"
        border.color: style ? style.borderColor : "#E5E5E5"
        border.width: 1
        radius: 6
        
        // 使用多个 Rectangle 实现阴影效果
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.margins: -2
            color: "#20000000"
            radius: parent.radius + 2
        }
        Rectangle {
            z: -2
            anchors.fill: parent
            anchors.margins: -4
            color: "#10000000"
            radius: parent.radius + 4
        }
    }
    
    // 自定义标准按钮样式
    header: DialogButtonBox {
        id: standardButtonBox
        standardButtons: filterDialog.standardButtons
        alignment: Qt.AlignRight
        spacing: 8
        padding: 16

        background: Rectangle {
            color: style ? style.backgroundColor : "#FFFFFF"
        }

        delegate: Button {
            id: dialogButton
            required property int standardButton

            contentItem: Text {
                text: dialogButton.text
                font {
                    family: filterDialog.style ? filterDialog.style.fontFamily : "Microsoft YaHei"
                    pixelSize: filterDialog.style ? filterDialog.style.defaultFontSize : 12
                }
                color: {
                    if (standardButton === Dialog.Apply || standardButton === Dialog.Ok) {
                        return dialogButton.down ? "#FFFFFF" : "#FFFFFF"
                    }
                    return dialogButton.down ? "#666666" : "#333333"
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 4
                color: {
                    if (standardButton === Dialog.Apply || standardButton === Dialog.Ok) {
                        if (dialogButton.down) {
                            return style ? style.buttonPressedColor : "#005FB8"
                        } else if (dialogButton.hovered) {
                            return style ? style.buttonHoverColor : "#0078D4"
                        }
                        return style ? style.buttonColor : "#0078D4"
                    } else {
                        if (dialogButton.down) {
                            return "#E0E0E0"
                        } else if (dialogButton.hovered) {
                            return "#F0F0F0"
                        }
                        return "#F5F5F5"
                    }
                }
                border.color: standardButton === Dialog.Cancel ? "#E0E0E0" : "transparent"
                border.width: standardButton === Dialog.Cancel ? 1 : 0
                
                Behavior on color {
                    ColorAnimation { duration: 100 }
                }
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        ColumnLayout {
            width: scrollView.width
            spacing: 16
            
            // 自定义筛选条件部分
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                spacing: 8
                
                Label {
                    text: "自定义筛选条件"
                    font {
                        family: filterDialog.style ? filterDialog.style.fontFamily : "Microsoft YaHei"
                        pixelSize: filterDialog.style ? filterDialog.style.defaultFontSize + 2 : 14
                        bold: true
                    }
                    Layout.fillWidth: true
                }
                
                TextField {
                    id: filterInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    text: filterDialog.currentFilter
                    placeholderText: "输入文件类型，例如：*.jpg;*.png"
                    font.family: filterDialog.style ? filterDialog.style.fontFamily : "Microsoft YaHei"
                    selectByMouse: true
                    wrapMode: TextInput.WrapAnywhere
                    
                    background: Rectangle {
                        implicitHeight: Math.max(32, filterInput.contentHeight + 16)
                        color: filterInput.enabled ? "white" : "#f0f0f0"
                        border.color: filterInput.activeFocus ? 
                                    (filterDialog.style ? filterDialog.style.accentColor : "#0078D4") : 
                                    (filterDialog.style ? filterDialog.style.borderColor : "#E5E5E5")
                        border.width: filterInput.activeFocus ? 2 : 1
                        radius: 4
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 100 }
                        }
                        Behavior on border.width {
                            NumberAnimation { duration: 100 }
                        }
                    }
                }
                
                Label {
                    text: "提示：多个类型用分号(;)分隔，例如：*.jpg;*.png"
                    font {
                        family: filterDialog.style ? filterDialog.style.fontFamily : "Microsoft YaHei"
                        pixelSize: filterDialog.style ? filterDialog.style.defaultFontSize - 1 : 11
                    }
                    color: filterDialog.style ? filterDialog.style.secondaryTextColor : "#666666"
                }
            }

            // 分隔线
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: style ? style.borderColor : "#E5E5E5"
                opacity: 0.5
            }
            
            // 预置筛选条件部分
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Label {
                    text: "预置筛选条件（可多选）"
                    font {
                        family: filterDialog.style ? filterDialog.style.fontFamily : "Microsoft YaHei"
                        pixelSize: filterDialog.style ? filterDialog.style.defaultFontSize + 2 : 14
                        bold: true
                    }
                }
                
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Repeater {
                        id: presetRepeater
                        model: Object.keys(presetFilters)
                        
                        CheckBox {
                            required property string modelData
                            text: modelData
                            font.family: filterDialog.style ? filterDialog.style.fontFamily : "Microsoft YaHei"
                            
                            checked: {
                                let currentPatterns = filterInput.text.split(';').map(p => p.trim());
                                let presetPatterns = presetFilters[modelData].split(';').map(p => p.trim());
                                return presetPatterns.every(p => currentPatterns.includes(p));
                            }
                            
                            onClicked: {
                                let currentPatterns = new Set(filterInput.text.split(';').map(p => p.trim()).filter(p => p));
                                let presetPatterns = presetFilters[modelData].split(';').map(p => p.trim());
                                
                                if (checked) {
                                    presetPatterns.forEach(p => currentPatterns.add(p));
                                } else {
                                    presetPatterns.forEach(p => currentPatterns.delete(p));
                                }
                                
                                filterInput.text = Array.from(currentPatterns).join(';');
                            }
                            
                            ToolTip {
                                visible: parent.hovered
                                text: presetFilters[parent.text]
                                delay: 500
                                font.family: filterDialog.style ? filterDialog.style.fontFamily : "Microsoft YaHei"
                            }
                        }
                    }
                }
            }
        }
    }
    
    onAccepted: {
        currentFilter = filterInput.text
        if (settings) {
            settings.setValue("fileFilter", currentFilter)
        }
    }
    
    Component.onCompleted: {
        if (settings) {
            currentFilter = settings.value("fileFilter", "")
            filterInput.text = currentFilter
        }
    }
}
