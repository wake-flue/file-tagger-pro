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
    
    color: style.backgroundColor
    border.color: style.borderColor
    border.width: 1
    radius: 4
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
                text: "总文件数: " + (fileList.model ? fileList.model.count : 0)
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
                Layout.fillWidth: true
                text: fileManager.logMessages.length > 0 ? 
                      fileManager.logMessages[0].replace(/\[.*?\] /, '') : "就绪"
                elide: Text.ElideRight
                font {
                    family: root.style ? root.style.fontFamily : "Microsoft YaHei"
                    pixelSize: root.style ? root.style.defaultFontSize - 1 : 11
                }
                color: root.style ? root.style.secondaryTextColor : "#666666"
            }
        }

        // 查看日志按钮
        Button {
            id: viewLogButton
            icon.source: "qrc:/resources/images/log.svg"
            icon.width: 16
            icon.height: 16
            padding: 6
            implicitWidth: 28
            implicitHeight: 28
            Layout.alignment: Qt.AlignVCenter
            
            ToolTip {
                visible: parent.hovered
                text: "查看日志"
                delay: 500
                font {
                    family: root.style ? root.style.fontFamily : "Microsoft YaHei"
                    pixelSize: root.style ? root.style.defaultFontSize - 1 : 11
                }
            }
            
            background: Rectangle {
                color: viewLogButton.down ? Qt.alpha(root.style ? root.style.accentColor : "#0078D4", 0.15) : 
                       viewLogButton.hovered ? Qt.alpha(root.style ? root.style.accentColor : "#0078D4", 0.1) : 
                       "transparent"
                radius: 4
                
                border.color: viewLogButton.down || viewLogButton.hovered ? 
                            Qt.alpha(root.style ? root.style.accentColor : "#0078D4", 0.3) : 
                            "transparent"
                border.width: 1
            }
            
            onClicked: logDialog.open()
        }
    }
} 