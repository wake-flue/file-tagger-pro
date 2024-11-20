import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

Dialog {
    id: logDialog
    title: qsTr("运行日志")
    width: 600
    height: 400
    modal: true
    
    property alias logMessages: logViewer.logMessages
    
    // 添加窗口大小限制
    Component.onCompleted: {
        if (width < 400) width = 400
        if (height < 300) height = 300
    }
    
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        
        LogViewer {
            id: logViewer
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        
        Button {
            text: qsTr("关闭")
            Layout.alignment: Qt.AlignRight
            onClicked: logDialog.close()
        }
    }
}
