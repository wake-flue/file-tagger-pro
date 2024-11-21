import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

Window {
    id: logWindow
    title: qsTr("运行日志")
    width: 600
    height: 400
    
    // 窗口属性
    visible: false  // 默认隐藏
    flags: Qt.Window | Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint  // 无边框窗口
    color: "#ffffff"  // 设置窗口背景色
    
    property alias logMessages: logViewer.logMessages
    property int resizeMargin: 5  // 调整大小的边缘宽度
    
    // 添加窗口大小限制
    minimumWidth: 400
    minimumHeight: 300
    
    // 打开窗口的方法
    function open() {
        visible = true
        raise()
        requestActivate()
    }
    
    // 关闭窗口的方法
    function close() {
        visible = false
    }
    
    Rectangle {
        anchors.fill: parent
        border.width: 1
        border.color: "#E5E5E5"
        
        // 左边缘调整区域
        MouseArea {
            id: leftResize
            width: resizeMargin
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            cursorShape: Qt.SizeHorCursor
            property int startX
            property int startWidth
            
            onPressed: {
                startX = mouseX
                startWidth = logWindow.width
            }
            onMouseXChanged: {
                var dx = mouseX - startX
                var newWidth = Math.max(startWidth - dx, logWindow.minimumWidth)
                if (newWidth !== logWindow.width) {
                    logWindow.x += logWindow.width - newWidth
                    logWindow.width = newWidth
                }
            }
        }
        
        // 右边缘调整区域
        MouseArea {
            id: rightResize
            width: resizeMargin
            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            cursorShape: Qt.SizeHorCursor
            property int startX
            property int startWidth
            
            onPressed: {
                startX = mouseX
                startWidth = logWindow.width
            }
            onMouseXChanged: {
                var dx = mouseX - startX
                var newWidth = Math.max(startWidth + dx, logWindow.minimumWidth)
                logWindow.width = newWidth
            }
        }
        
        // 底部边缘调整区域
        MouseArea {
            id: bottomResize
            height: resizeMargin
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            cursorShape: Qt.SizeVerCursor
            property int startY
            property int startHeight
            
            onPressed: {
                startY = mouseY
                startHeight = logWindow.height
            }
            onMouseYChanged: {
                var dy = mouseY - startY
                var newHeight = Math.max(startHeight + dy, logWindow.minimumHeight)
                logWindow.height = newHeight
            }
        }
        
        // 右下角调整区域
        MouseArea {
            id: cornerResize
            width: resizeMargin * 2
            height: resizeMargin * 2
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            cursorShape: Qt.SizeFDiagCursor
            property point startPos
            property size startSize
            
            onPressed: {
                startPos = Qt.point(mouseX, mouseY)
                startSize = Qt.size(logWindow.width, logWindow.height)
            }
            onPositionChanged: {
                var dx = mouseX - startPos.x
                var dy = mouseY - startPos.y
                var newWidth = Math.max(startSize.width + dx, logWindow.minimumWidth)
                var newHeight = Math.max(startSize.height + dy, logWindow.minimumHeight)
                logWindow.width = newWidth
                logWindow.height = newHeight
            }
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            // 自定义标题栏
            Rectangle {
                id: titleBar
                Layout.fillWidth: true
                height: 36
                color: "#f5f5f5"
                
                // 标题栏拖动区域
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    property point lastMousePos
                    
                    onPressed: {
                        lastMousePos = Qt.point(mouseX, mouseY)
                    }
                    
                    onMouseXChanged: {
                        var dx = mouseX - lastMousePos.x
                        logWindow.x += dx
                    }
                    
                    onMouseYChanged: {
                        var dy = mouseY - lastMousePos.y
                        logWindow.y += dy
                    }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8
                    
                    Image {
                        source: "qrc:/resources/images/log.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16
                        opacity: 0.7
                    }
                    
                    Label {
                        text: logWindow.title
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: 13
                    }
                    
                    Rectangle {
                        width: 36
                        height: 36
                        color: closeMouseArea.containsMouse ? "#ffdddd" : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeMouseArea.containsMouse ? "#cc0000" : "#666666"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: logWindow.visible = false
                        }
                    }
                }
            }
            
            // 内容区域
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 10
                spacing: 10
                
                LogViewer {
                    id: logViewer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
    
    // 添加窗口关闭事件处理
    onClosing: function(close) {
        close.accepted = true
        visible = false
    }
}
