import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    
    // 必要的属性声明
    required property QtObject style
    required property var fileManager
    required property var fileList
    required property var logDialog
    required property var settingsWindow
    
    // 添加属性验证
    property bool isValid: fileManager && fileList && fileList.model
    
    color: style.backgroundColor
    border.color: style.borderColor
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
                    family: root.style ? root.style.fontFamily : "Microsoft YaHei"
                    pixelSize: root.style ? root.style.defaultFontSize - 1 : 11
                }
                color: root.style ? root.style.secondaryTextColor : "#666666"
            }
        }

        // 分隔符
        Rectangle {
            width: 1
            height: 16
            color: root.style ? Qt.alpha(root.style.borderColor, 0.8) : "#E5E5E5"
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
                    family: root.style ? root.style.fontFamily : "Microsoft YaHei"
                    pixelSize: root.style ? root.style.defaultFontSize - 1 : 11
                }
                color: logMouseArea.containsMouse ? 
                       (root.style ? root.style.accentColor : "#0078D4") : 
                       (root.style ? root.style.secondaryTextColor : "#666666")

                MouseArea {
                    id: logMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onDoubleClicked: {
                        if (root.settingsWindow) {
                            root.settingsWindow.currentIndex = 5  // 切换到日志设置页面
                            root.settingsWindow.show()
                        }
                    }
                }
            }
        }

        // 分隔符
        Rectangle {
            width: 1
            height: 16
            color: root.style ? Qt.alpha(root.style.borderColor, 0.8) : "#E5E5E5"
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
                    family: root.style ? root.style.fontFamily : "Microsoft YaHei"
                    pixelSize: root.style ? root.style.defaultFontSize - 1 : 11
                }
                color: pathMouseArea.containsMouse ? 
                       (root.style ? root.style.accentColor : "#0078D4") : 
                       (root.style ? root.style.secondaryTextColor : "#666666")

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