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
    required property QtObject style
    
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
    
    // 标题区域
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        Label {
            text: qsTr("标签管理")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("管理文件标签，包括创建、编辑和删除标签")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
            opacity: settingsStyle.defaultOpacity
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
    
    // 工具栏
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        color: style?.backgroundColor ?? settingsStyle.defaultButtonNormalColor
        radius: settingsStyle.defaultRadius
        
        RowLayout {
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 8
            
            Button {
                text: qsTr("新建标签")
                icon.source: "qrc:/resources/images/add.svg"
                icon.width: 16
                icon.height: 16
                
                background: Rectangle {
                    implicitWidth: 100
                    implicitHeight: 32
                    color: parent.down ? Qt.darker(style?.accentColor ?? settingsStyle.defaultAccentColor, 1.1) :
                           parent.hovered ? Qt.lighter(style?.accentColor ?? settingsStyle.defaultAccentColor, 1.1) : 
                           style?.accentColor ?? settingsStyle.defaultAccentColor
                    radius: settingsStyle.defaultRadius
                    
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
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
                        font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
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
            
            // 添加刷新按钮
            Button {
                id: refreshButton
                icon.source: "qrc:/resources/images/refresh.svg"
                icon.width: 16
                icon.height: 16
                
                background: Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    color: parent.down ? Qt.darker(style?.backgroundColor ?? settingsStyle.defaultButtonNormalColor, 1.1) :
                           parent.hovered ? (style?.hoverColor ?? settingsStyle.defaultButtonHoverColor) : 
                           style?.backgroundColor ?? settingsStyle.defaultButtonNormalColor
                    border.color: parent.down ? (style?.accentColor ?? settingsStyle.defaultAccentColor) :
                                parent.hovered ? (style?.accentColor ?? settingsStyle.defaultAccentColor) :
                                style?.borderColor ?? settingsStyle.defaultBorderColor
                    border.width: 1
                    radius: settingsStyle.defaultRadius
                    
                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
                }
                
                ToolTip {
                    visible: parent.hovered
                    text: qsTr("刷新列表")
                    delay: 500
                    font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    font.pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
                
                onClicked: {
                    searchField.text = ""  // 清空搜索框
                    refreshTagList()       // 刷新列表
                }
            }
            
            Item { Layout.fillWidth: true }
            
            TextField {
                id: searchField
                placeholderText: qsTr("搜索标签...")
                Layout.preferredWidth: 200
                
                background: Rectangle {
                    implicitHeight: 32
                    color: style?.backgroundColor ?? settingsStyle.defaultButtonNormalColor
                    border.color: parent.activeFocus ? 
                                (style?.accentColor ?? settingsStyle.defaultAccentColor) : 
                                "transparent"
                    border.width: parent.activeFocus ? 2 : 0
                    radius: settingsStyle.defaultRadius
                }
                
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
                
                onTextChanged: refreshTagList()
            }
        }
    }
    
    // 标签列表容器
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: style?.backgroundColor ?? settingsStyle.defaultButtonNormalColor
        border.color: style?.borderColor ?? settingsStyle.defaultBorderColor
        border.width: 1
        radius: settingsStyle.defaultRadius
        
        ListView {
            id: tagListView
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            model: TagManager.getAllTags()
            
            delegate: ItemDelegate {
                id: tagDelegate
                width: ListView.view.width
                height: 48
                
                required property var modelData
                
                background: Rectangle {
                    color: tagDelegate.hovered ? 
                           (style?.hoverColor ?? settingsStyle.defaultButtonHoverColor) : 
                           "transparent"
                    radius: settingsStyle.defaultRadius
                }
                
                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }
                    spacing: 12
                    
                    // 颜色标记
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: tagDelegate.modelData?.color ?? "transparent"
                        border.width: 1
                        border.color: tagDelegate.modelData?.color ? 
                                    Qt.darker(tagDelegate.modelData.color, 1.1) : 
                                    "transparent"
                        
                        Behavior on scale {
                            NumberAnimation { duration: 100 }
                        }
                        
                        scale: tagDelegate.hovered ? 1.1 : 1.0
                    }
                    
                    // 标签信息
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: tagDelegate.modelData?.name ?? ""
                            font {
                                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                                pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                            }
                            color: style?.textColor ?? settingsStyle.defaultTextColor
                        }
                        
                        Label {
                            text: tagDelegate.modelData?.description ?? ""
                            font {
                                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                                pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 2
                            }
                            color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
                            opacity: settingsStyle.defaultOpacity
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    
                    // 操作按钮
                    Row {
                        spacing: 8
                        
                        Button {
                            icon.source: "qrc:/resources/images/edit.svg"
                            icon.width: 16
                            icon.height: 16
                            
                            background: Rectangle {
                                implicitWidth: 32
                                implicitHeight: 32
                                color: parent.down ? 
                                       (style?.hoverColor ?? settingsStyle.defaultButtonPressedColor) :
                                       parent.hovered ? 
                                       (style?.backgroundColor ?? settingsStyle.defaultButtonHoverColor) : 
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
                                implicitWidth: 32
                                implicitHeight: 32
                                color: parent.down ? 
                                       Qt.darker("#dc3545", 1.1) :
                                       parent.hovered ? 
                                       Qt.lighter("#dc3545", 1.1) : 
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
                active: true
                policy: ScrollBar.AsNeeded
            }
            
            // 添加分隔线
            section.delegate: Rectangle {
                width: parent.width
                height: 1
                color: style?.borderColor ?? settingsStyle.defaultBorderColor
                opacity: 0.5
            }
        }
    }
    
    // 标签编辑对话框
    Dialogs.TagEditDialog {
        id: editDialog
        style: root.style
        
        // 添加关闭信号处理
        onClosed: {
            if (result === Dialog.Accepted) {
                refreshTagList()
            }
        }
        
        // 添加标签操作的结果处理
        onTagAdded: {
            refreshTagList()  // 添加标签后刷新
        }
        
        onTagUpdated: {
            refreshTagList()  // 更新标签后刷新
        }
        
        onTagError: {
            // TODO: 可以添加错误提示对话框
            console.error("标签操作失败:", message)
        }
    }
    
    // 删除确认对话框
    Dialog {
        id: deleteConfirmDialog
        title: qsTr("删除标签")
        modal: true
        
        property int tagId: -1
        property string tagName: ""
        
        // 居中显示
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        contentItem: ColumnLayout {
            spacing: 16
            
            Label {
                text: qsTr("确定要删除标签吗？")
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                }
                color: style?.textColor ?? settingsStyle.defaultTextColor
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            
            Label {
                text: qsTr("此操作不可撤销。")
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: (style?.defaultFontSize ?? settingsStyle.defaultFontSize) - 1
                }
                color: style?.secondaryTextColor ?? settingsStyle.defaultTextColor
                opacity: settingsStyle.defaultOpacity
            }
        }
        
        footer: DialogButtonBox {
            Button {
                text: qsTr("取消")
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                
                background: Rectangle {
                    implicitWidth: 80
                    implicitHeight: 32
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
                    implicitHeight: 32
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
                        family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        pixelSize: style?.defaultFontSize ?? settingsStyle.defaultFontSize
                    }
                }
            }
        }
        
        onAccepted: {
            if (tagId !== -1) {
                if (TagManager.deleteTag(tagId)) {
                    refreshTagList()
                } else {
                    // 可以添加错误提示
                    console.error("删除标签失败")
                }
            }
        }
    }
} 