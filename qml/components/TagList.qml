import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

Rectangle {
    id: root
    
    // 必要的属性声明
    required property QtObject style
    required property var currentFile
    
    property var tags: []
    
    // 信号声明
    signal addTagClicked()
    signal tagRemoved(int tagId)
    
    color: style.backgroundColor
    border.color: style.borderColor
    border.width: 1
    radius: 4
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        
        // 标题栏
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Label {
                text: "标签"
                font {
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize
                    bold: true
                }
                color: root.style.textColor
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: "添加"
                icon.source: "qrc:/resources/images/add.svg"
                icon.width: 12
                icon.height: 12
                padding: 4
                
                onClicked: root.addTagClicked()
            }
        }
        
        // 标签列表
        ListView {
            id: tagListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: root.tags
            
            delegate: Rectangle {
                width: tagListView.width
                height: 32
                radius: 4
                color: modelData.color
                opacity: 0.8
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Label {
                        text: modelData.name
                        font.family: root.style.fontFamily
                        color: "#FFFFFF"
                        Layout.fillWidth: true
                    }
                    
                    Button {
                        icon.source: "qrc:/resources/images/remove.svg"
                        icon.width: 12
                        icon.height: 12
                        padding: 4
                        flat: true
                        
                        onClicked: root.tagRemoved(modelData.id)
                    }
                }
            }
            
            ScrollBar.vertical: ScrollBar {}
        }
    }
} 