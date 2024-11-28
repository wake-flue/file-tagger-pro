import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import FileManager 1.0
import "../dialogs" as Dialogs

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 刷新标签列表数据
    function refreshTagList() {
        const searchText = searchField.text.toLowerCase().trim()
        const allTags = TagManager.getAllTags()
        tagListView.model = searchText === "" ? allTags :
            allTags.filter(tag => 
                (tag?.name?.toLowerCase().includes(searchText) || 
                 tag?.description?.toLowerCase().includes(searchText))
            )
    }
    
    // 标题和说明
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        Label {
            text: qsTr("标签管理")
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.titleFontSize
                bold: true
            }
            color: settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("管理文件标签，包括创建、编辑和删除标签")
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
    
    // 工具栏
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: settingsStyle.defaultItemSpacing
        spacing: 8
        
        Button {
            text: qsTr("新建标签")
            icon.source: "qrc:/resources/images/add.svg"
            icon.width: 16
            icon.height: 16
            
            background: Rectangle {
                implicitWidth: 100
                implicitHeight: settingsStyle.defaultButtonHeight
                color: parent.down ? Qt.darker(settingsStyle.defaultAccentColor, 1.1) :
                       parent.hovered ? Qt.lighter(settingsStyle.defaultAccentColor, 1.1) :
                       settingsStyle.defaultAccentColor
                radius: settingsStyle.defaultRadius
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
                    color: "white"
                    font.family: settingsStyle.defaultFontFamily
                    font.pixelSize: settingsStyle.defaultFontSize
                }
            }
            
            onClicked: {
                editDialog.editMode = false
                editDialog.tagId = -1
                editDialog.tagName = ""
                editDialog.tagColor = Qt.rgba(0, 0.47, 0.83, 1)
                editDialog.tagDescription = ""
                editDialog.open()
            }
        }
        
        Button {
            id: refreshButton
            icon.source: "qrc:/resources/images/refresh.svg"
            icon.width: 16
            icon.height: 16
            
            background: Rectangle {
                implicitWidth: settingsStyle.defaultButtonHeight
                implicitHeight: settingsStyle.defaultButtonHeight
                color: parent.down ? settingsStyle.defaultButtonPressedColor :
                       parent.hovered ? settingsStyle.defaultButtonHoverColor :
                       settingsStyle.defaultButtonNormalColor
                border.color: parent.down ? settingsStyle.defaultButtonPressedBorderColor :
                            parent.hovered ? settingsStyle.defaultButtonHoverBorderColor :
                            settingsStyle.defaultButtonNormalBorderColor
                border.width: 1
                radius: settingsStyle.defaultRadius
            }
            
            ToolTip {
                visible: parent.hovered
                text: qsTr("刷新列表")
                delay: 500
                font.family: settingsStyle.defaultFontFamily
                font.pixelSize: settingsStyle.defaultFontSize
            }
            
            onClicked: {
                searchField.text = ""
                refreshTagList()
            }
        }
        
        Item { Layout.fillWidth: true }
        
        TextField {
            id: searchField
            placeholderText: qsTr("搜索标签...")
            Layout.preferredWidth: 200
            selectByMouse: true
            
            background: Rectangle {
                implicitHeight: settingsStyle.defaultInputHeight
                color: settingsStyle.defaultInputBackgroundColor
                border.color: parent.activeFocus ? 
                            settingsStyle.defaultInputFocusBorderColor :
                            parent.hovered ? 
                            settingsStyle.defaultButtonHoverBorderColor :
                            settingsStyle.defaultInputBorderColor
                border.width: parent.activeFocus ? 2 : 1
                radius: settingsStyle.defaultRadius
            }
            
            font {
                family: settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.defaultFontSize
            }
            
            onTextChanged: refreshTagList()
        }
    }
    
    // 标签列表
    ListView {
        id: tagListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: settingsStyle.defaultSpacing
        clip: true
        model: TagManager.getAllTags()
        spacing: 1
        
        delegate: ItemDelegate {
            id: tagDelegate
            width: ListView.view.width
            height: 48
            
            required property var modelData
            
            background: Rectangle {
                color: tagDelegate.hovered ? 
                       settingsStyle.defaultListItemHoverColor : 
                       "transparent"
            }
            
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }
                spacing: 12
                
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: tagDelegate.modelData?.color ?? "transparent"
                    
                    Behavior on scale {
                        NumberAnimation { duration: 100 }
                    }
                    
                    scale: tagDelegate.hovered ? 1.1 : 1.0
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Label {
                        text: tagDelegate.modelData?.name ?? ""
                        font {
                            family: settingsStyle.defaultFontFamily
                            pixelSize: settingsStyle.defaultFontSize
                        }
                        color: settingsStyle.defaultTextColor
                    }
                    
                    Label {
                        text: tagDelegate.modelData?.description ?? ""
                        font {
                            family: settingsStyle.defaultFontFamily
                            pixelSize: settingsStyle.descriptionFontSize
                        }
                        color: settingsStyle.defaultSecondaryTextColor
                        opacity: settingsStyle.defaultOpacity
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                Row {
                    spacing: 8
                    
                    Button {
                        icon.source: "qrc:/resources/images/edit.svg"
                        icon.width: 16
                        icon.height: 16
                        
                        background: Rectangle {
                            implicitWidth: settingsStyle.defaultButtonHeight
                            implicitHeight: settingsStyle.defaultButtonHeight
                            color: parent.down ? settingsStyle.defaultButtonPressedColor :
                                   parent.hovered ? settingsStyle.defaultButtonHoverColor :
                                   "transparent"
                            radius: settingsStyle.defaultRadius
                        }
                        
                        onClicked: {
                            editDialog.editMode = true
                            editDialog.tagId = tagDelegate.modelData.id
                            editDialog.tagName = tagDelegate.modelData.name
                            editDialog.tagColor = tagDelegate.modelData.color
                            editDialog.tagDescription = tagDelegate.modelData.description
                            editDialog.open()
                        }
                    }
                    
                    Button {
                        icon.source: "qrc:/resources/images/delete.svg"
                        icon.width: 16
                        icon.height: 16
                        
                        background: Rectangle {
                            implicitWidth: settingsStyle.defaultButtonHeight
                            implicitHeight: settingsStyle.defaultButtonHeight
                            color: parent.down ? Qt.darker("#dc3545", 1.1) :
                                   parent.hovered ? Qt.lighter("#dc3545", 1.1) :
                                   "transparent"
                            radius: settingsStyle.defaultRadius
                        }
                        
                        onClicked: {
                            deleteConfirmDialog.tagId = tagDelegate.modelData.id
                            deleteConfirmDialog.tagName = tagDelegate.modelData.name
                            deleteConfirmDialog.open()
                        }
                    }
                }
            }
        }
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }
    
    // 标签编辑对话框
    Dialogs.TagEditDialog {
        id: editDialog
        
        onClosed: {
            if (result === Dialog.Accepted) {
                refreshTagList()
            }
        }
        
        onTagAdded: refreshTagList()
        onTagUpdated: refreshTagList()
        onTagError: console.error("标签操作失败:", message)
    }
    
    // 删除确认对话框
    Dialog {
        id: deleteConfirmDialog
        title: qsTr("删除标签")
        modal: true
        
        property int tagId: -1
        property string tagName: ""
        
        // 设置固定宽度和高度
        width: 400
        height: 200
        
        // 使用anchors进行居中定位
        anchors.centerIn: parent
        
        contentItem: ColumnLayout {
            spacing: 16
            width: parent.width
            
            Label {
                text: qsTr("确定要删除标签吗？")
                font {
                    family: settingsStyle.defaultFontFamily
                    pixelSize: settingsStyle.defaultFontSize
                }
                color: settingsStyle.defaultTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            
            Label {
                text: qsTr("此操作不可撤销。")
                font {
                    family: settingsStyle.defaultFontFamily
                    pixelSize: settingsStyle.descriptionFontSize
                }
                color: settingsStyle.defaultSecondaryTextColor
                opacity: settingsStyle.defaultOpacity
            }
        }
        
        footer: DialogButtonBox {
            Button {
                text: qsTr("取消")
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                
                background: Rectangle {
                    implicitWidth: 80
                    implicitHeight: settingsStyle.defaultButtonHeight
                    color: parent.down ? settingsStyle.defaultButtonPressedColor :
                           parent.hovered ? settingsStyle.defaultButtonHoverColor :
                           settingsStyle.defaultButtonNormalColor
                    border.color: parent.down ? settingsStyle.defaultButtonPressedBorderColor :
                                 parent.hovered ? settingsStyle.defaultButtonHoverBorderColor :
                                 settingsStyle.defaultButtonNormalBorderColor
                    border.width: 1
                    radius: settingsStyle.defaultRadius
                }
            }
            
            Button {
                text: qsTr("删除")
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                
                background: Rectangle {
                    implicitWidth: 80
                    implicitHeight: settingsStyle.defaultButtonHeight
                    color: parent.down ? Qt.darker("#dc3545", 1.1) :
                           parent.hovered ? Qt.lighter("#dc3545", 1.1) :
                           "#dc3545"
                    radius: settingsStyle.defaultRadius
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font {
                        family: settingsStyle.defaultFontFamily
                        pixelSize: settingsStyle.defaultFontSize
                    }
                }
            }
        }
        
        onAccepted: {
            if (tagId !== -1) {
                if (TagManager.deleteTag(tagId)) {
                    refreshTagList()
                } else {
                    console.error("删除标签失败")
                }
            }
        }
    }
    
    // 监听标签变化
    Connections {
        target: TagManager
        
        function onTagAdded(tag) {
            refreshTagList()
        }
        
        function onTagRemoved(tagId) {
            refreshTagList()
        }
        
        function onTagUpdated(tag) {
            refreshTagList()
        }
        
        function onTagError(message) {
            // 显示错误消息
            errorDialog.text = message
            errorDialog.open()
        }
    }
    
    // 错误提示对话框
    Dialog {
        id: errorDialog
        title: qsTr("错误")
        modal: true
        
        property alias text: messageLabel.text
        
        Label {
            id: messageLabel
            width: parent.width
            wrapMode: Text.Wrap
            font.family: settingsStyle.defaultFontFamily
            font.pixelSize: settingsStyle.defaultFontSize
            color: settingsStyle.defaultTextColor
        }
        
        standardButtons: Dialog.Ok
    }
} 