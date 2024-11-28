import QtQuick
import ".." 1.0

MouseArea {
    id: root
    width: Style.windowResizerSize
    height: Style.windowResizerSize
    cursorShape: Qt.SizeFDiagCursor
    
    property var window
    property point clickPos: Qt.point(0, 0)
    
    onPressed: function(event) {
        clickPos = Qt.point(event.x, event.y)
    }
    
    onPositionChanged: function(event) {
        if (pressed && window.visibility !== Window.Maximized) {
            var delta = Qt.point(event.x - clickPos.x, event.y - clickPos.y)
            window.width = Math.max(window.width + delta.x, window.minimumWidth)
            window.height = Math.max(window.height + delta.y, window.minimumHeight)
        }
    }
} 