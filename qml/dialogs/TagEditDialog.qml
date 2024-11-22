import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import FileManager 1.0

Dialog {
    id: root
    title: editMode ? "编辑标签" : "添加标签"
    
    property bool editMode: false
    property int tagId: -1
    property string tagName: ""
    property color tagColor: Qt.rgba(0, 0.47, 0.83, 1)
    property string tagDescription: ""
    
    width: 400
    height: 300
    modal: true
    
    // 信号声明
    signal tagSaved(int id, string name, color color, string description)
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // 标签名称
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            Label {
                text: "标签名称"
                font.bold: true
            }
            
            TextField {
                id: nameField
                text: root.tagName
                Layout.fillWidth: true
                placeholderText: "输入标签名称"
            }
        }
        
        // 标签颜色
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            Label {
                text: "标签颜色"
                font.bold: true
            }
            
            Button {
                text: "选择颜色"
                onClicked: colorDialog.open()
                
                Rectangle {
                    width: 16
                    height: 16
                    radius: 8
                    color: root.tagColor
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 8
                }
            }
        }
        
        // 标签描述
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Label {
                text: "描述"
                font.bold: true
            }
            
            TextArea {
                id: descriptionField
                text: root.tagDescription
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: "输入标签描述(可选)"
                wrapMode: TextArea.Wrap
            }
        }
        
        // 按钮区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: "取消"
                onClicked: root.reject()
            }
            
            Button {
                text: "保存"
                highlighted: true
                onClicked: {
                    validateAndSave()
                }
            }
        }
        
        // 错误提示标签
        Label {
            id: errorLabel
            visible: false
            color: "#dc3545"
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }
    
    ColorDialog {
        id: colorDialog
        title: "选择标签颜色"
        selectedColor: root.tagColor
        onAccepted: root.tagColor = selectedColor
    }
    
    // 在保存前添加检查
    function validateAndSave() {
        // 检查标签名是否为空
        if (!nameField.text.trim()) {
            showError("标签名称不能为空")
            return
        }
        
        // 检查标签名是否已存在
        if (!editMode && TagManager.isTagNameExists(nameField.text.trim())) {
            showError("标签名称已存在")
            return
        }
        
        // 保存标签
        if (editMode) {
            TagManager.updateTag(root.tagId, nameField.text.trim(), root.tagColor, descriptionField.text.trim())
        } else {
            TagManager.addTag(nameField.text.trim(), root.tagColor, descriptionField.text.trim())
        }
        
        root.accept()
    }
    
    function showError(message) {
        errorLabel.text = message
        errorLabel.visible = true
    }
} 