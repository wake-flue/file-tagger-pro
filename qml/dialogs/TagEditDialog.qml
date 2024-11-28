import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import FileManager 1.0
import ".." 1.0

Dialog {
    id: root
    title: editMode ? qsTr("编辑标签") : qsTr("添加标签")
    width: 400
    height: 300
    modal: true
    
    // 在对话框打开时居中显示
    onOpened: {
        centerDialog()
    }
    
    // 窗口大小改变时保持居中
    Connections {
        target: parent
        function onWidthChanged() {
            centerDialog()
        }
        function onHeightChanged() {
            centerDialog()
        }
    }
    
    // 居中显示函数
    function centerDialog() {
        if (!parent) return
        
        // 计算居中位置
        const newX = Math.max(0, Math.min(parent.width - width, (parent.width - width) / 2))
        const newY = Math.max(0, Math.min(parent.height - height, (parent.height - height) / 2))
        
        // 设置位置
        x = newX
        y = newY
    }
    
    property bool editMode: false
    property int tagId: -1
    property string tagName: ""
    property color tagColor: Qt.rgba(0, 0.47, 0.83, 1)
    property string tagDescription: ""
    
    // 信号声明
    signal tagSaved(int id, string name, color color, string description)
    signal tagAdded()
    signal tagUpdated()
    signal tagError(string message)
    
    // 背景设置
    background: Rectangle {
        color: Style.backgroundColor
        border.color: Style.borderColor
        border.width: 1
        radius: 6
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        
        // 标签名称
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            Label {
                text: qsTr("标签名称")
                font {
                    family: Style.fontFamily
                    pixelSize: Style.fontSizeNormal
                    bold: true
                }
                color: Style.textColor
            }
            
            TextField {
                id: nameField
                text: root.tagName
                Layout.fillWidth: true
                placeholderText: qsTr("输入标签名称")
                
                background: Rectangle {
                    implicitHeight: 32
                    color: Style.backgroundColor
                    border.color: nameField.activeFocus ? Style.accentColor : Style.borderColor
                    border.width: nameField.activeFocus ? 2 : 1
                    radius: 4
                }
                
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSizeNormal
                color: Style.textColor
                
                selectByMouse: true
            }
        }
        
        // 标签颜色
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            Label {
                text: qsTr("标签颜色")
                font {
                    family: Style.fontFamily
                    pixelSize: Style.fontSizeNormal
                    bold: true
                }
                color: Style.textColor
            }
            
            Button {
                Layout.fillWidth: true
                padding: 8
                
                background: Rectangle {
                    implicitHeight: 32
                    color: Style.backgroundColor
                    border.color: parent.down ? Style.accentColor :
                                parent.hovered ? Style.accentColor : Style.borderColor
                    border.width: 1
                    radius: 4
                }
                
                contentItem: RowLayout {
                    spacing: 8
                    
                    Label {
                        text: qsTr("选择颜色")
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontSizeNormal
                        color: Style.textColor
                        Layout.fillWidth: true
                    }
                    
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: root.tagColor
                        border.width: 1
                        border.color: Qt.darker(color, 1.1)
                    }
                }
                
                onClicked: colorDialog.open()
            }
        }
        
        // 标签描述
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Label {
                text: qsTr("描述")
                font {
                    family: Style.fontFamily
                    pixelSize: Style.fontSizeNormal
                    bold: true
                }
                color: Style.textColor
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                TextArea {
                    id: descriptionField
                    text: root.tagDescription
                    placeholderText: qsTr("输入标签描述(可选)")
                    wrapMode: TextArea.Wrap
                    
                    background: Rectangle {
                        color: Style.backgroundColor
                        border.color: descriptionField.activeFocus ? Style.accentColor : Style.borderColor
                        border.width: descriptionField.activeFocus ? 2 : 1
                        radius: 4
                    }
                    
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal
                    color: Style.textColor
                    
                    selectByMouse: true
                }
            }
        }
        
        // 错误提示标签
        Label {
            id: errorLabel
            visible: false
            color: "#dc3545"
            font.pixelSize: Style.fontSizeNormal - 1
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        
        // 按钮区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: qsTr("取消")
                padding: 8
                
                background: Rectangle {
                    implicitWidth: 80
                    implicitHeight: 32
                    color: parent.down ? Qt.darker(Style.backgroundColor, 1.1) :
                           parent.hovered ? Style.hoverColor : Style.backgroundColor
                    border.color: parent.down ? Style.accentColor :
                                parent.hovered ? Style.accentColor : Style.borderColor
                    border.width: 1
                    radius: 4
                }
                
                contentItem: Label {
                    text: parent.text
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal
                    color: Style.textColor
                    horizontalAlignment: Text.AlignHCenter
                }
                
                onClicked: root.reject()
            }
            
            Button {
                text: qsTr("保存")
                padding: 8
                
                background: Rectangle {
                    implicitWidth: 80
                    implicitHeight: 32
                    color: parent.down ? Qt.darker(Style.accentColor, 1.1) :
                           parent.hovered ? Qt.lighter(Style.accentColor, 1.1) : Style.accentColor
                    border.width: 0
                    radius: 4
                }
                
                contentItem: Label {
                    text: parent.text
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontSizeNormal
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }
                
                onClicked: validateAndSave()
            }
        }
    }
    
    ColorDialog {
        id: colorDialog
        title: qsTr("选择标签颜色")
        selectedColor: root.tagColor
        onAccepted: root.tagColor = selectedColor
    }
    
    // 在保存前添加检查
    function validateAndSave() {
        // 检查标签名是否为空
        if (!nameField.text.trim()) {
            showError(qsTr("标签名称不能为空"))
            tagError(qsTr("标签名称不能为空"))
            return
        }
        
        // 检查标签名是否已存在
        if (!editMode && TagManager.isTagNameExists(nameField.text.trim())) {
            showError(qsTr("标签名称已存在"))
            tagError(qsTr("标签名称已存在"))
            return
        }
        
        // 保存标签
        if (editMode) {
            if (TagManager.updateTag(root.tagId, nameField.text.trim(), root.tagColor, descriptionField.text.trim())) {
                tagUpdated()
            } else {
                tagError(qsTr("更新标签失败"))
                return
            }
        } else {
            if (TagManager.addTag(nameField.text.trim(), root.tagColor, descriptionField.text.trim())) {
                tagAdded()
            } else {
                tagError(qsTr("添加标签失败"))
                return
            }
        }
        
        root.accept()
    }
    
    function showError(message) {
        errorLabel.text = message
        errorLabel.visible = true
    }
} 