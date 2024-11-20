import QtQuick
import QtQuick.Controls.Basic  // 改用 Basic 样式
import QtQuick.Layouts

ColumnLayout {
    property alias logMessages: logListView.model
    spacing: 4
    
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        
        Label {
            text: "运行日志"
            font {
                bold: true
                pixelSize: 13
                family: "Microsoft YaHei"
            }
        }
        
        Item { Layout.fillWidth: true }
        
        Button {
            id: clearButton
            text: "清除日志"
            icon.source: "qrc:/resources/images/clear.svg"
            icon.width: 14
            icon.height: 14
            padding: 6
            
            // 使用 Basic 样式的按钮自定义
            background: Rectangle {
                implicitWidth: 80
                implicitHeight: 30
                color: clearButton.down ? "#e0e0e0" : 
                       clearButton.hovered ? "#f0f0f0" : "#ffffff"
                border.color: clearButton.down ? "#c0c0c0" : 
                            clearButton.hovered ? "#d0d0d0" : "#e0e0e0"
                border.width: 1
                radius: 3
            }
            
            contentItem: RowLayout {
                spacing: 4
                Image {
                    source: clearButton.icon.source
                    sourceSize.width: 14
                    sourceSize.height: 14
                    width: clearButton.icon.width
                    height: clearButton.icon.height
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: clearButton.text
                    color: clearButton.down ? "#404040" : "#606060"
                    font.family: "Microsoft YaHei"
                }
            }
            
            onClicked: fileManager.clearLogs()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "#ffffff"
        border.color: "#e0e0e0"
        border.width: 1
        radius: 3
        clip: true

        ListView {
            id: logListView
            anchors.fill: parent
            anchors.margins: 1
            spacing: 1
            clip: true
            
            onCountChanged: {
                if (atYEnd || count === 1) {
                    positionViewAtEnd()
                }
            }
            
            // 使用 Basic 样式的滚动条
            ScrollBar.vertical: ScrollBar {
                id: verticalScrollBar
                policy: ScrollBar.AsNeeded
                visible: logListView.contentHeight > logListView.height
                
                contentItem: Rectangle {
                    implicitWidth: 6
                    radius: width / 2
                    color: verticalScrollBar.pressed ? "#606060" : 
                           verticalScrollBar.hovered ? "#909090" : "#c0c0c0"
                }
            }
            
            ScrollBar.horizontal: ScrollBar {
                id: horizontalScrollBar
                policy: ScrollBar.AsNeeded
                visible: logListView.contentWidth > logListView.width
                
                contentItem: Rectangle {
                    implicitHeight: 6
                    radius: height / 2
                    color: horizontalScrollBar.pressed ? "#606060" : 
                           horizontalScrollBar.hovered ? "#909090" : "#c0c0c0"
                }
            }
            
            delegate: Rectangle {
                width: ListView.view.width
                height: logText.height + 6
                color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#f0f0f0"
                    visible: index > 0
                }

                Text {
                    id: logText
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: 8
                    }
                    text: modelData
                    color: {
                        if (modelData.toLowerCase().includes("错误") || 
                            modelData.toLowerCase().includes("失败")) {
                            return "#dc3545"
                        } else if (modelData.toLowerCase().includes("警告")) {
                            return "#ffc107"
                        } else if (modelData.toLowerCase().includes("成功") ||
                                 modelData.toLowerCase().includes("完成")) {
                            return "#28a745"
                        }
                        return "#495057"
                    }
                    font {
                        family: "Microsoft YaHei"
                        pixelSize: 12
                    }
                    wrapMode: Text.Wrap
                    
                    Component.onCompleted: {
                        let timestamp = modelData.match(/\[(.*?)\]/);
                        if (timestamp) {
                            let parts = modelData.split("] ");
                            text = "<font color='#999999'>" + timestamp[0] + "]</font> " + 
                                  parts.slice(1).join("] ");
                        }
                    }
                    textFormat: Text.RichText
                }
            }
        }
    }
}
