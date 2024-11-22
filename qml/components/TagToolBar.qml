import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import FileManager 1.0

Rectangle {
    id: root
    color: style.backgroundColor
    border.color: style.borderColor
    border.width: 1
    radius: 4
    height: 36

    // 必要的属性声明
    required property QtObject style
    required property QtObject settings
    required property QtObject fileManager
    required property QtObject dbViewerDialog

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 8
            topMargin: 4
            bottomMargin: 4
        }
        spacing: 8

        // 标签过滤器
        Rectangle {
            Layout.preferredWidth: 200
            Layout.preferredHeight: 28
            color: "#f5f5f5"
            radius: 3
            border.color: tagFilterInput.activeFocus ? root.style.accentColor : root.style.borderColor
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4

                Image {
                    source: "qrc:/resources/images/tag.svg"
                    sourceSize.width: 14
                    sourceSize.height: 14
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: tagFilterInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "按标签筛选..."
                    font.family: root.style.fontFamily
                    font.pixelSize: root.style.defaultFontSize - 1
                    color: root.style.textColor
                    selectByMouse: true
                    background: null

                    onTextChanged: {
                        if (root.fileManager && root.fileManager.fileModel) {
                            root.fileManager.fileModel.tagFilter = text
                        }
                    }
                }
            }
        }

        // 标签统计
        Row {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            Label {
                text: "已使用标签:"
                font.family: root.style.fontFamily
                font.pixelSize: root.style.defaultFontSize - 1
                color: root.style.secondaryTextColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                text: TagManager.getAllTags().length
                font.family: root.style.fontFamily
                font.pixelSize: root.style.defaultFontSize - 1
                color: root.style.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item { Layout.fillWidth: true }  // 弹性空间

        // 右侧按钮组
        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            // 标签管理按钮
            Button {
                id: tagManageButton
                text: "管理标签"
                icon.source: "qrc:/resources/images/tag-edit.svg"
                icon.width: 14
                icon.height: 14
                padding: 6

                background: Rectangle {
                    implicitWidth: 90
                    implicitHeight: 28
                    color: tagManageButton.down ? Qt.darker(root.style.backgroundColor, 1.1) : 
                           tagManageButton.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: tagManageButton.down ? root.style.accentColor : 
                                tagManageButton.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 3
                }

                contentItem: RowLayout {
                    spacing: 4
                    Image {
                        source: tagManageButton.icon.source
                        sourceSize.width: tagManageButton.icon.width
                        sourceSize.height: tagManageButton.icon.height
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: tagManageButton.text
                        color: root.style.textColor
                        font.family: root.style.fontFamily
                        font.pixelSize: root.style.defaultFontSize - 1
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                onClicked: {
                    // TODO: 打开标签管理对话框
                }
            }

            // 数据库查看按钮
            Button {
                id: dbViewButton
                icon.source: "qrc:/resources/images/database.svg"
                icon.width: 14
                icon.height: 14
                padding: 6
                
                ToolTip {
                    visible: parent.hovered
                    text: "数据库管理"
                    delay: 500
                }

                background: Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    color: dbViewButton.down ? Qt.darker(root.style.backgroundColor, 1.1) : 
                           dbViewButton.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: dbViewButton.down ? root.style.accentColor : 
                                dbViewButton.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 3
                }

                onClicked: {
                    if (root.dbViewerDialog) {
                        root.dbViewerDialog.open()
                    }
                }
            }

            // 数据库备份按钮
            Button {
                id: dbBackupButton
                icon.source: "qrc:/resources/images/backup.svg"
                icon.width: 14
                icon.height: 14
                padding: 6
                
                ToolTip {
                    visible: parent.hovered
                    text: "备份数据库"
                    delay: 500
                }

                background: Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    color: dbBackupButton.down ? Qt.darker(root.style.backgroundColor, 1.1) : 
                           dbBackupButton.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: dbBackupButton.down ? root.style.accentColor : 
                                dbBackupButton.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 3
                }

                onClicked: {
                    // TODO: 实现数据库备份功能
                }
            }
        }
    }
} 