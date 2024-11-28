import QtQuick
import QtQuick.Effects
import QtQuick.Window

Rectangle {
    id: root
    
    property string buttonText: ""
    property string iconSource: ""
    property color hoverColor: "#F0F0F0"
    property color hoverTextColor: "#202020"
    property color normalColor: "transparent"
    property color normalTextColor: "#202020"
    
    width: 46
    height: 32
    color: mouseArea.containsMouse ? hoverColor : normalColor
    
    Image {
        id: buttonIcon
        anchors.centerIn: parent
        source: parent.iconSource
        sourceSize.width: 10
        sourceSize.height: 10
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