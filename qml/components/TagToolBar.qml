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
    required property QtObject settingsWindow

    // 内部属性
    property var selectedTagIds: []

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 8
            topMargin: 4
            bottomMargin: 4
        }
        spacing: 8

        // 标签水平滚动区域
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            Row {
                spacing: 8
                height: parent.height

                Repeater {
                    model: TagManager.getAllTags()
                    
                    CheckBox {
                        id: tagCheckBox
                        text: modelData.name
                        padding: 2
                        height: parent.height
                        
                        contentItem: Rectangle {
                            id: tagRect
                            implicitWidth: tagRow.width + 24
                            height: parent.height - 4
                            radius: height / 6
                            color: modelData.color
                            opacity: tagCheckBox.checked ? 0.9 : 0.6
                            border.width: tagCheckBox.checked ? 2 : 0
                            border.color: Qt.lighter(modelData.color, 1.4)
                            
                            // 添加鼠标悬停效果
                            states: State {
                                name: "hovered"
                                when: tagMouseArea.containsMouse
                                PropertyChanges {
                                    target: tagRect
                                    opacity: tagCheckBox.checked ? 1 : 0.8
                                    scale: 1.05
                                }
                            }
                            
                            transitions: Transition {
                                NumberAnimation {
                                    properties: "opacity,scale"
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Row {
                                id: tagRow
                                anchors.centerIn: parent
                                spacing: 4

                                // 选中状态指示器
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                    opacity: tagCheckBox.checked ? 1 : 0
                                    scale: tagCheckBox.checked ? 1 : 0
                                    
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }
                                    Behavior on scale {
                                        NumberAnimation { duration: 200 }
                                    }
                                }

                                Label {
                                    id: tagLabel
                                    text: tagCheckBox.text
                                    font.family: root.style.fontFamily
                                    font.pixelSize: root.style.defaultFontSize - 1
                                    color: "white"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: tagMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tagCheckBox.checked = !tagCheckBox.checked
                            }
                        }

                        indicator: null // 移除默认的复选框指示器

                        onCheckedChanged: {
                            if (checked) {
                                if (!root.selectedTagIds.includes(modelData.id)) {
                                    root.selectedTagIds.push(modelData.id)
                                }
                            } else {
                                let index = root.selectedTagIds.indexOf(modelData.id)
                                if (index !== -1) {
                                    root.selectedTagIds.splice(index, 1)
                                }
                            }
                            updateFileFilter()
                        }
                    }
                }
            }
        }

        // 右侧按钮组
        RowLayout {
            spacing: 4
            Layout.alignment: Qt.AlignVCenter

            // 清除筛选按钮
            Button {
                id: clearFilterButton
                icon.source: "qrc:/resources/images/clear.svg"
                icon.width: 14
                icon.height: 14
                padding: 6
                visible: root.selectedTagIds.length > 0
                
                ToolTip {
                    visible: parent.hovered
                    text: "清除筛选"
                    delay: 500
                }

                background: Rectangle {
                    implicitWidth: 32
                    implicitHeight: 28
                    color: clearFilterButton.down ? Qt.darker(root.style.backgroundColor, 1.1) : 
                           clearFilterButton.hovered ? root.style.hoverColor : root.style.backgroundColor
                    border.color: clearFilterButton.down ? root.style.accentColor : 
                                clearFilterButton.hovered ? root.style.accentColor : root.style.borderColor
                    border.width: 1
                    radius: 3
                }

                onClicked: {
                    root.selectedTagIds = []
                    updateFileFilter()
                }
            }

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
                    if (root.settingsWindow) {
                        root.settingsWindow.currentIndex = 3  // 切换到标签设置页面
                        root.settingsWindow.show()
                    }
                }
            }
        }
    }

    // 更新文件过滤器
    function updateFileFilter() {
        if (root.fileManager && root.fileManager.fileModel) {
            root.fileManager.fileModel.selectedTagIds = root.selectedTagIds
        }
    }

    // 监听标签变化
    Connections {
        target: TagManager
        function onTagsChanged() {
            // 清除已失效的选中标签
            root.selectedTagIds = root.selectedTagIds.filter(id => 
                TagManager.getTagById(id) !== null
            )
            updateFileFilter()
        }
    }
} 