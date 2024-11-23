import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform as Platform
import FileManager 1.0

ColumnLayout {
    id: root
    spacing: settingsStyle.defaultSpacing
    
    required property QtObject settings
    required property QtObject style
    
    // 使用统一的样式对象
    property SettingsStyle settingsStyle: SettingsStyle {}
    
    // 标题和说明
    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true
        
        Label {
            text: qsTr("播放器设置")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.titleFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("设置图片查看器和视频播放器的路径")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
    
    // 图片查看器设置
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: settingsStyle.defaultSpacing
        spacing: settingsStyle.defaultItemSpacing
        
        Label {
            text: qsTr("图片查看器")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.defaultFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("选择或输入图片查看器路径")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            TextField {
                id: imagePathInput
                Layout.fillWidth: true
                placeholderText: qsTr("请选择图片查看器程序")
                text: settings ? settings.imagePlayer : ""
                selectByMouse: true
                
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: settingsStyle.defaultFontSize
                }
                
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
                
                onTextChanged: {
                    settings.imagePlayer = text
                }
            }
            
            Button {
                text: qsTr("浏览")
                icon.source: "qrc:/resources/images/folder.svg"
                icon.width: 14
                icon.height: 14
                
                background: Rectangle {
                    implicitWidth: settingsStyle.defaultButtonWidth
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
                
                contentItem: RowLayout {
                    spacing: 4
                    Image {
                        source: parent.parent.icon.source
                        sourceSize.width: parent.parent.icon.width
                        sourceSize.height: parent.parent.icon.height
                    }
                    Label {
                        text: parent.parent.text
                        font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        font.pixelSize: settingsStyle.defaultFontSize
                        color: style?.textColor ?? settingsStyle.defaultTextColor
                    }
                }
                
                onClicked: {
                    fileDialog.forImage = true
                    fileDialog.open()
                }
            }
        }
    }
    
    // 视频播放器设置
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: settingsStyle.defaultSpacing
        spacing: settingsStyle.defaultItemSpacing
        
        Label {
            text: qsTr("视频播放器")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.defaultFontSize
                bold: true
            }
            color: style?.textColor ?? settingsStyle.defaultTextColor
        }
        
        Label {
            text: qsTr("选择或输入视频播放器路径")
            font {
                family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                pixelSize: settingsStyle.descriptionFontSize
            }
            color: style?.secondaryTextColor ?? settingsStyle.defaultSecondaryTextColor
            opacity: settingsStyle.defaultOpacity
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            TextField {
                id: videoPathInput
                Layout.fillWidth: true
                placeholderText: qsTr("请选择视频播放器程序")
                text: settings ? settings.videoPlayer : ""
                selectByMouse: true
                
                font {
                    family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                    pixelSize: settingsStyle.defaultFontSize
                }
                
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
                
                onTextChanged: {
                    settings.videoPlayer = text
                }
            }
            
            Button {
                text: qsTr("浏览")
                icon.source: "qrc:/resources/images/folder.svg"
                icon.width: 14
                icon.height: 14
                
                background: Rectangle {
                    implicitWidth: settingsStyle.defaultButtonWidth
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
                
                contentItem: RowLayout {
                    spacing: 4
                    Image {
                        source: parent.parent.icon.source
                        sourceSize.width: parent.parent.icon.width
                        sourceSize.height: parent.parent.icon.height
                    }
                    Label {
                        text: parent.parent.text
                        font.family: style?.fontFamily ?? settingsStyle.defaultFontFamily
                        font.pixelSize: settingsStyle.defaultFontSize
                        color: style?.textColor ?? settingsStyle.defaultTextColor
                    }
                }
                
                onClicked: {
                    fileDialog.forImage = false
                    fileDialog.open()
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
    
    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: qsTr("选择播放器程序")
        nameFilters: ["可执行文件 (*.exe)"]
        currentFolder: Platform.StandardPaths.standardLocations(
            Platform.StandardPaths.ApplicationsLocation)[0]
        
        property bool forImage: true
        
        onAccepted: {
            let path = selectedFile.toString().replace(/^(file:\/{3})/,"")
            path = decodeURIComponent(path)
            if (Qt.platform.os === "windows") {
                path = path.replace(/\//g, "\\")
            }
            if (forImage) {
                imagePathInput.text = path
            } else {
                videoPathInput.text = path
            }
        }
    }
} 