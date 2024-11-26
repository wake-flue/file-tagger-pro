import QtQuick

Rectangle {
    id: splitter
    
    property real position: 0.8  // 分隔位置，0-1之间
    property real minimumPosition: 0.2  // 最小位置
    property real maximumPosition: 0.8  // 最大位置
    property bool dragging: mouseArea.drag.active
    property bool panelVisible: false  // 添加面板可见性属性
    
    width: 4
    height: parent.height
    visible: panelVisible  // 根据面板可见性控制分割线显示
    opacity: 0
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4  // 扩大点击区域
        cursorShape: Qt.SplitHCursor
        drag.target: parent
        drag.axis: Drag.XAxis
        drag.minimumX: parent.parent.width * minimumPosition
        drag.maximumX: parent.parent.width * maximumPosition
        enabled: panelVisible  // 只在面板可见时允许拖动
        
        onPositionChanged: {
            if (drag.active) {
                splitter.position = parent.x / parent.parent.width
            }
        }
    }
}
