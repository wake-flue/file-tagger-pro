import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import FileManager 1.0

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
    
    required property QtObject style
    
    property bool editMode: false
    property int tagId: -1
    property string tagName: ""
    property color tagColor: Qt.rgba(0, 0.47, 0.83, 1)
    property string tagDescription: ""
    
    // 信号声明
    signal tagSaved(int id, string name, color color, string description)
    
    // 背景设置
    background: Rectangle {
        color: root.style.backgroundColor
        border.color: root.style.borderColor
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
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize
                    bold: true
                }
                color: root.style.textColor
            }
            
            TextField {
                id: nameField
                text: root.tagName
                Layout.fillWidth: true
                placeholderText: qsTr("输入标签名称")
                
                background: Rectangle {
                    implicitHeight: 32
                    color: root.style.backgroundColor
                    border.color: nameField.activeFocus ? root.style.accentColor : root.style.borderColor
                    border.width: nameField.activeFocus ? 2 : 1
                    radius: 4
                }
                
                font.family: root.style.fontFamily
                font.pixelSize: root.style.defaultFontSize
                color: root.style.textColor
                
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
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize
                    bold: true
                }
                color: root.style.textColor
            }
            
            Button {
                Layout.fillWidth: true
                padding: 8
                
                background: Rectangle {
                    implicitHeight: 32
                    color: root.style.backgroundColor
                    border.color: parent.down ? root.style.accentColor :
                                parent.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 4
                }
                
                contentItem: RowLayout {
                    spacing: 8
                    
                    Label {
                        text: qsTr("选择颜色")
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize
                        color: root.style.textColor
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
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize
                    bold: true
                }
                color: root.style.textColor
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
                        color: root.style.backgroundColor
                        border.color: descriptionField.activeFocus ? root.style.accentColor : root.style.borderColor
                        border.width: descriptionField.activeFocus ? 2 : 1
                        radius: 4
                    }
                    
                    font.family: root.style.fontFamily
                    font.pixelSize: root.style.defaultFontSize
                    color: root.style.textColor
                    
                    selectByMouse: true
                }
            }
        }
        
        // 错误提示标签
        Label {
            id: errorLabel
            visible: false
            color: "#dc3545"
            font.pixelSize: root.style.defaultFontSize - 1
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
                    color: parent.down ? Qt.darker(root.style.backgroundColor, 1.1) :
                           parent.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: parent.down ? root.style.accentColor :
                                parent.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 4
                }
                
                contentItem: Label {
                    text: parent.text
                    font.family: root.style.fontFamily
                    font.pixelSize: root.style.defaultFontSize
                    color: root.style.textColor
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
                    color: parent.down ? Qt.darker(root.style.accentColor, 1.1) :
                           parent.hovered ? Qt.lighter(root.style.accentColor, 1.1) : root.style.accentColor
                    border.width: 0
                    radius: 4
                }
                
                contentItem: Label {
                    text: parent.text
                    font.family: root.style.fontFamily
                    font.pixelSize: root.style.defaultFontSize
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
            return
        }
        
        // 检查标签名是否已存在
        if (!editMode && TagManager.isTagNameExists(nameField.text.trim())) {
            showError(qsTr("标签名称已存在"))
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