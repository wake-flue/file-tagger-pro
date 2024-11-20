import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#f5f5f5"
    radius: 4

    // 必要的属性声明
    required property var style
    required property var selectedItem
    required property var settings

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 16

        // 预览区域
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: width * 0.75  // 保持4:3的宽高比
            color: "white"
            radius: 4
            clip: true

            // 预览图片或默认图标
            Image {
                id: previewImage
                anchors.centerIn: parent
                height: parent.height
                fillMode: Image.PreserveAspectFit
                source: {
                    if (!root.selectedItem) {
                        return "qrc:/resources/images/file.svg"
                    }
                    
                    const fileType = root.selectedItem.fileType.toLowerCase()
                    if (fileType.match(/^(jpg|jpeg|png|gif|bmp)$/)) {
                        return "file:///" + root.selectedItem.filePath
                    }
                    return root.selectedItem.fileIcon || "qrc:/resources/images/file.svg"
                }
                asynchronous: true
                cache: true

                // 加载失败时显示默认图标
                onStatusChanged: {
                    if (status === Image.Error) {
                        source = "qrc:/resources/images/file.svg"
                    }
                }

                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }
            }

            // 无选中项时的提示
            Text {
                anchors.centerIn: parent
                text: "未选择文件"
                font.family: root.style.fontFamily
                font.pixelSize: root.style.defaultFontSize
                color: root.style.secondaryTextColor
                visible: !root.selectedItem
            }
        }

        // 文件信息区域
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // 标题栏
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Image {
                    source: "qrc:/resources/images/file.svg"
                    sourceSize.width: 14
                    sourceSize.height: 14
                    opacity: 0.7
                }

                Label {
                    text: "文件详情"
                    font {
                        family: root.style.fontFamily
                        bold: true
                        pixelSize: root.style.defaultFontSize
                    }
                    color: root.style.textColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.style.borderColor
                    opacity: 0.5
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // 文件详情内容
            Repeater {
                model: [
                    {
                        label: "文件名", 
                        value: root.selectedItem ? root.selectedItem.fileName || "-" : "-"
                    },
                    {
                        label: "类型", 
                        value: root.selectedItem ? root.selectedItem.fileType || "-" : "-"
                    },
                    {
                        label: "大小", 
                        value: root.selectedItem ? root.selectedItem.displaySize || "-" : "-"
                    },
                    {
                        label: "修改时间", 
                        value: root.selectedItem ? root.selectedItem.displayDate || "-" : "-"
                    }
                ]
                
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    Label {
                        text: modelData.label
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize - 1
                        color: root.style.secondaryTextColor
                    }
                    
                    Label {
                        text: modelData.value || "-"
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize
                        color: root.style.textColor
                        Layout.fillWidth: true
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: root.style.borderColor
                        opacity: 0.3
                        visible: index < 3
                    }
                }
            }

            // 路径显示
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "路径"
                    font.family: root.style.fontFamily
                    font.pixelSize: root.style.defaultFontSize - 1
                    color: root.style.secondaryTextColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: pathLabel.height + 16
                    color: "#f8f9fa"
                    radius: 4

                    Label {
                        id: pathLabel
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        text: root.selectedItem ? root.selectedItem.filePath : "-"
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize
                        color: root.style.textColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }  // 占位符
    }
} 