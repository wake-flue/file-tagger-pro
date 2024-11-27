import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

Dialog {
    id: root
    title: qsTr("编辑文件标签")
    width: 400
    height: 500
    modal: true
    
    // 添加标签更新信号
    signal tagsUpdated(string fileId)
    
    // 在对话框打开时居中显示
    onOpened: {
        centerDialog()
        if (!fileId) {
            close()
            return
        }
        selectedTags = TagManager.getFileTagsById(fileId)
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
    
    // 必要的属性声明
    required property QtObject style
    property string fileId: ""
    property string filePath: ""
    property var selectedTags: []
    
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
        
        // 文件信息区域
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            
            Label {
                text: qsTr("文件路径")
                font {
                    family: root.style.fontFamily
                    pixelSize: root.style.defaultFontSize
                    bold: true
                }
                color: root.style.textColor
            }
            
            Label {
                text: root.filePath
                font.family: root.style.fontFamily
                font.pixelSize: root.style.defaultFontSize
                color: root.style.secondaryTextColor
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }
        
        // 分隔线
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: root.style.borderColor
        }
        
        // 标签列表区域
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            
            Label {
                text: qsTr("可用标签")
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
                clip: true
                
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                
                Flow {
                    id: tagFlow
                    width: parent.width - 20  // 减去滚动条宽度
                    spacing: 8
                    
                    Repeater {
                        id: tagRepeater
                        model: TagManager.getAllTags()
                        
                        Rectangle {
                            id: tagItem
                            width: tagRow.width + 24
                            height: 32
                            color: modelData.color
                            opacity: tagMouseArea.containsMouse ? 1.0 :
                                    isTagSelected(modelData.id) ? 0.9 : 0.6
                            radius: height / 2
                            border.width: isTagSelected(modelData.id) ? 2 : 0
                            border.color: Qt.lighter(modelData.color, 1.4)
                            
                            property bool selected: isTagSelected(modelData.id)
                            
                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                            
                            Row {
                                id: tagRow
                                anchors.centerIn: parent
                                spacing: 6
                                
                                // 选中状态指示器
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "white"
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: tagItem.selected
                                    
                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }
                                }
                                
                                Label {
                                    text: modelData.name
                                    color: "white"
                                    font {
                                        family: root.style.fontFamily
                                        pixelSize: root.style.defaultFontSize
                                        bold: tagItem.selected
                                    }
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            
                            MouseArea {
                                id: tagMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    let success = false
                                    if (tagItem.selected) {
                                        success = TagManager.removeTagFromFileById(fileId, modelData.id)
                                        if (!success) {
                                            console.error("移除标签失败 - fileId:", fileId, "tagId:", modelData.id)
                                        }
                                    } else {
                                        success = TagManager.addTagToFileById(fileId, modelData.id)
                                        if (!success) {
                                            console.error("添加标签失败 - fileId:", fileId, "tagId:", modelData.id)
                                        }
                                    }
                                    // 更新选中状态
                                    root.selectedTags = TagManager.getFileTagsById(fileId)
                                    // 发送标签更新信号
                                    root.tagsUpdated(fileId)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 底部按钮区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Button {
                text: qsTr("添加新标签")
                icon.source: "qrc:/resources/images/add.svg"
                icon.width: 16
                icon.height: 16
                padding: 8
                
                background: Rectangle {
                    implicitWidth: 120
                    implicitHeight: 32
                    color: parent.down ? Qt.darker(root.style.backgroundColor, 1.1) :
                           parent.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: parent.down ? root.style.accentColor :
                                parent.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 4
                }
                
                contentItem: RowLayout {
                    spacing: 6
                    Image {
                        source: parent.parent.icon.source
                        sourceSize.width: parent.parent.icon.width
                        sourceSize.height: parent.parent.icon.height
                    }
                    Label {
                        text: parent.parent.text
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize
                        color: root.style.textColor
                    }
                }
                
                onClicked: {
                    tagEditDialog.editMode = false
                    tagEditDialog.open()
                }
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: qsTr("关闭")
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
                
                onClicked: root.close()
            }
        }
    }
    
    // 标签编辑对话框
    TagEditDialog {
        id: tagEditDialog
        style: root.style
        
        onAccepted: {
            // 刷新标签列表
            tagRepeater.model = TagManager.getAllTags()
            selectedTags = TagManager.getFileTagsById(fileId)
        }
    }
    
    // 辅助函数：检查标签是否被选中
    function isTagSelected(tagId) {
        for (let tag of selectedTags) {
            if (tag.id === tagId) return true
        }
        return false
    }
    
    function addTag(tagId) {
        if (TagManager.addTagToFileById(fileId, tagId)) {
            selectedTags = TagManager.getFileTagsById(fileId)
        }
    }
    
    function removeTag(tagId) {
        if (TagManager.removeTagFromFileById(fileId, tagId)) {
            selectedTags = TagManager.getFileTagsById(fileId)
        }
    }
    
    // 监听标签变化
    Connections {
        target: TagManager
        
        function onTagsChanged() {
            // 刷新标签列表
            tagRepeater.model = TagManager.getAllTags()
        }
        
        function onFileTagsChanged(changedFileId) {
            if (changedFileId === fileId) {
                // 更新当前文件的标签
                selectedTags = TagManager.getFileTagsById(fileId)
            }
        }
        
        function onTagError(message) {
            // 显示错误消息
            console.error(message)
        }
    }
} 