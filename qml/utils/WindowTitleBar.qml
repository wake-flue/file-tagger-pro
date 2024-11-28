import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root
    height: 32
    width: parent.width
    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }
    color: style ? style.backgroundColor : "#FFFFFF"
    
    property var window
    property var style
    property string title
    property point startMousePos: Qt.point(0, 0)
    property bool isDragging: false
    property real initialWindowWidth: 0
    property real initialWindowHeight: 0
    property real startDpi: Screen.devicePixelRatio
    
    // 缩放限制
    readonly property real maxScaleFactor: 1.1
    readonly property real minScaleFactor: 0.9
    readonly property real defaultWidth: 960
    readonly property real defaultHeight: 680
    
    Component.onCompleted: {
        initialWindowWidth = window.width
        initialWindowHeight = window.height
    }
    
    property color defaultTextColor: "#202020"
    property string defaultFontFamily: "Microsoft YaHei"
    property int defaultFontSize: 12
    
    // 左侧图标和标题
    RowLayout {
        height: parent.height
        anchors {
            left: parent.left
            right: windowControls.left
        }
        spacing: 8

        Image {
            Layout.leftMargin: 8
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            source: "qrc:/resources/icons/app_icon.svg"
        }

        Text {
            text: root.title
            color: style ? style.textColor : root.defaultTextColor
            font.family: style ? style.fontFamily : root.defaultFontFamily
            font.pixelSize: style ? style.defaultFontSize : root.defaultFontSize
        }

        Item { 
            Layout.fillWidth: true 
        }
    }

    // 右侧窗口控制按钮
    Row {
        id: windowControls
        anchors.right: parent.right
        height: parent.height

        WindowControlButton {
            iconSource: "qrc:/resources/images/window-minimize.svg"
            onClicked: window.showMinimized()
        }

        WindowControlButton {
            id: maximizeButton
            iconSource: window.visibility === Window.Maximized ? 
                "qrc:/resources/images/window-restore.svg" : 
                "qrc:/resources/images/window-maximize.svg"
            onClicked: {
                if (window.visibility === Window.Maximized) {
                    window.showNormal()
                } else {
                    window.showMaximized()
                }
            }
        }

        WindowControlButton {
            iconSource: "qrc:/resources/images/window-close.svg"
            hoverColor: "#E81123"
            hoverTextColor: "#FFFFFF"
            onClicked: window.close()
        }
    }

    MouseArea {
        id: dragArea
        anchors {
            fill: parent
            rightMargin: windowControls.width
        }
        property point clickPos: Qt.point(0, 0)
        property point lastPos: Qt.point(0, 0)
        property bool dragging: false
        
        // 安全地获取屏幕几何信息
        function getScreenGeometry(screen) {
            if (!screen) return null
            
            try {
                return {
                    x: screen.virtualX || 0,
                    y: screen.virtualY || 0,
                    width: screen.width || Screen.width,
                    height: screen.height || Screen.height
                }
            } catch (e) {
                console.error("Failed to get screen geometry:", e)
                return {
                    x: 0,
                    y: 0,
                    width: Screen.width,
                    height: Screen.height
                }
            }
        }
        
        // 计算合理的缩放比例
        function calculateScaleFactor(currentDpi, startDpi) {
            var rawRatio = currentDpi / startDpi
            return Math.min(Math.max(rawRatio, minScaleFactor), maxScaleFactor)
        }
        
        // 确保窗口尺寸在合理范围内
        function constrainWindowSize(size) {
            var maxWidth = defaultWidth * maxScaleFactor
            var maxHeight = defaultHeight * maxScaleFactor
            var minWidth = defaultWidth * minScaleFactor
            var minHeight = defaultHeight * minScaleFactor
            
            return Qt.size(
                Math.min(Math.max(size.width, minWidth), maxWidth),
                Math.min(Math.max(size.height, minHeight), maxHeight)
            )
        }
        
        // 确保窗口位置在屏幕范围内
        function constrainWindowPosition(x, y, width, height, screenGeometry) {
            if (!screenGeometry) return Qt.point(x, y)
            
            var newX = Math.min(Math.max(x, screenGeometry.x),
                               screenGeometry.x + screenGeometry.width - width)
            var newY = Math.min(Math.max(y, screenGeometry.y),
                               screenGeometry.y + screenGeometry.height - height)
            
            return Qt.point(newX, newY)
        }
        
        // 调整窗口大小以适应新的DPI
        function adjustWindowSize() {
            if (!window) return
            
            var currentDpi = window.screen ? window.screen.devicePixelRatio : Screen.devicePixelRatio
            if (Math.abs(currentDpi - startDpi) < 0.01) return
            
            // 计算新尺寸
            var scaleFactor = calculateScaleFactor(currentDpi, startDpi)
            var targetSize = constrainWindowSize(Qt.size(
                initialWindowWidth * scaleFactor,
                initialWindowHeight * scaleFactor
            ))
            
            // 应用新的窗口尺寸
            window.width = Math.max(targetSize.width, window.minimumWidth)
            window.height = Math.max(targetSize.height, window.minimumHeight)
            
            // 调整窗口位置
            var screenGeometry = getScreenGeometry(window.screen)
            if (screenGeometry) {
                var newPos = constrainWindowPosition(
                    window.x, window.y,
                    window.width, window.height,
                    screenGeometry
                )
                window.x = newPos.x
                window.y = newPos.y
            }
        }
        
        onPressed: function(event) {
            if (!event || !window) return
            
            clickPos = Qt.point(event.x, event.y)
            lastPos = mapToGlobal(event.x, event.y)
            dragging = false
            
            if (window.visibility !== Window.Maximized) {
                var constrainedSize = constrainWindowSize(Qt.size(window.width, window.height))
                initialWindowWidth = constrainedSize.width
                initialWindowHeight = constrainedSize.height
                startDpi = window.screen ? window.screen.devicePixelRatio : Screen.devicePixelRatio
            }
        }
        
        onPositionChanged: function(event) {
            if (!event || !window) return
            
            if (!dragging) {
                var currentPos = mapToGlobal(event.x, event.y)
                if (!currentPos) return
                
                var deltaX = Math.abs(currentPos.x - lastPos.x)
                var deltaY = Math.abs(currentPos.y - lastPos.y)
                
                if (deltaX > 5 || deltaY > 5) {
                    dragging = true
                    if (window.visibility === Window.Maximized) {
                        window.showNormal()
                        var relativeX = event.x / width
                        
                        var constrainedSize = constrainWindowSize(Qt.size(
                            window.previousWindowState.width,
                            window.previousWindowState.height
                        ))
                        window.width = constrainedSize.width
                        window.height = constrainedSize.height
                        initialWindowWidth = constrainedSize.width
                        initialWindowHeight = constrainedSize.height
                        
                        var newX = currentPos.x - (window.width * relativeX)
                        var newY = currentPos.y - clickPos.y
                        
                        // 确保新位置在屏幕范围内
                        var screenGeometry = getScreenGeometry(window.screen)
                        if (screenGeometry) {
                            var newPos = constrainWindowPosition(
                                newX, newY,
                                window.width, window.height,
                                screenGeometry
                            )
                            window.x = newPos.x
                            window.y = newPos.y
                        } else {
                            window.x = newX
                            window.y = newY
                        }
                        
                        lastPos = currentPos
                    }
                }
            }
            
            if (dragging && window.visibility !== Window.Maximized) {
                var currentPos = mapToGlobal(event.x, event.y)
                if (!currentPos) return
                
                var deltaX = currentPos.x - lastPos.x
                var deltaY = currentPos.y - lastPos.y
                
                window.x += deltaX
                window.y += deltaY
                lastPos = currentPos
            }
        }
        
        onReleased: function() {
            if (!window) return
            
            if (dragging) {
                adjustWindowSize()
            }
            
            dragging = false
            
            if (window.y < 0) {
                window.showMaximized()
            }
        }
        
        onDoubleClicked: {
            if (!window) return
            
            if (window.visibility === Window.Maximized) {
                window.showNormal()
            } else {
                window.previousWindowState = Qt.rect(window.x, window.y, window.width, window.height)
                window.showMaximized()
            }
        }
    }
} 