import QtQuick
import QtQuick.Effects
import QtQuick.Window
import ".." 1.0

Rectangle {
    id: root
    
    property string buttonText: ""
    property string iconSource: ""
    property color hoverColor: Style.controlButtonHoverColor
    property color hoverTextColor: Style.controlButtonTextColor
    property color normalColor: Style.controlButtonNormalColor
    property color normalTextColor: Style.controlButtonTextColor
    
    width: Style.controlButtonWidth
    height: Style.controlButtonHeight
    color: mouseArea.containsMouse ? hoverColor : normalColor
    
    Image {
        id: buttonIcon
        anchors.centerIn: parent
        source: parent.iconSource
        sourceSize.width: Style.controlButtonIconSize
        sourceSize.height: Style.controlButtonIconSize
        visible: parent.iconSource !== ""
    }
    
    MultiEffect {
        source: buttonIcon
        anchors.fill: buttonIcon
        colorization: 1.0
        colorizationColor: mouseArea.containsMouse ? root.hoverTextColor : root.normalTextColor
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
    
    signal clicked()
} 