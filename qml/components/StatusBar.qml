import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".." 1.0

Rectangle {
    id: root
    
    // 必要的属性声明
    required property var fileManager
    required property var fileList
    required property var settingsWindow
    
    // 添加属性验证
    property bool isValid: fileManager && fileList && fileList.model
    
    // 添加信号
    signal requestShowLog()
    
    color: Style.backgroundColor
    border.color: Style.borderColor
    border.width: 1
    height: 32

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 12

        // 文件统计信息
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            Image {
                source: "qrc:/resources/images/file.svg"
                sourceSize.width: 14
                sourceSize.height: 14
                width: 14
                height: 14
                opacity: 0.7
            }
            Label {
                text: "总文件数: " + (isValid ? fileList.model.count : 0)
                font {
                    family: Style.fontFamily
                    pixelSize: Style.fontSizeNormal - 1
                }
                color: Style.lightTextColor
            }
        }

        // 分隔符
        Rectangle {
            width: 1
            height: 16
            color: Qt.alpha(Style.borderColor, 0.8)
            Layout.alignment: Qt.AlignVCenter
        }

        // 最后一条日志消息
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            Image {
                source: "qrc:/resources/images/log.svg"
                sourceSize.width: 14
                sourceSize.height: 14
                width: 14
                height: 14
                opacity: 0.7
            }
            Label {
                id: lastMessageLabel
                Layout.fillWidth: true
                text: fileManager?.logger?.lastMessage ?? "就绪"
                elide: Text.ElideRight
                font {
                    family: Style.fontFamily
                    pixelSize: Style.fontSizeNormal - 1
                }
                color: logMouseArea.containsMouse ? Style.accentColor : Style.lightTextColor

                MouseArea {
                    id: logMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onDoubleClicked: {
                        if (settingsWindow) {
                            settingsWindow.currentIndex = 5  // 日志设置在第6个位置（索引为5）
                            settingsWindow.show()
                        }
                    }
                }
            }
        }

        // 分隔符
        Rectangle {
            width: 1
            height: 16
            color: Qt.alpha(Style.borderColor, 0.8)
            Layout.alignment: Qt.AlignVCenter
        }

        // 当前目录信息
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            Image {
                source: "qrc:/resources/images/folder.svg"
                sourceSize.width: 14
                sourceSize.height: 14
                width: 14
                height: 14
                opacity: 0.7
            }
            Label {
                id: pathLabel
                text: "当前目录: " + (isValid && fileManager.currentPath ? fileManager.currentPath : "未选择")
                elide: Text.ElideMiddle
                Layout.preferredWidth: Math.min(300, implicitWidth)  // 限制最大宽度
                font {
                    family: Style.fontFamily
                    pixelSize: Style.fontSizeNormal - 1
                }
                color: pathMouseArea.containsMouse ? Style.accentColor : Style.lightTextColor

                MouseArea {
                    id: pathMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onDoubleClicked: {
                        if (isValid && fileManager.currentPath) {
                            Qt.openUrlExternally("file:///" + fileManager.currentPath)
                        }
                    }
                }
            }
        }
    }
} 