import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform as Platform
import FileManager 1.0

Dialog {
    id: root
    title: qsTr("播放器设置")
    modal: true
    
    property QtObject settings
    property QtObject style
    property var defaultApps: DefaultApps {}
    
    width: 500
    height: 300
    
    Component.onCompleted: {
        defaultApps.searchDefaultApps()
    }
    
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
                settings.imagePlayer = path
            } else {
                videoPathInput.text = path
                settings.videoPlayer = path
            }
        }
    }
    
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // 图片查看器设置
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Label {
                text: qsTr("图片查看器路径")
                font.family: style ? style.fontFamily : "Microsoft YaHei"
                font.pixelSize: style ? style.defaultFontSize : 12
                color: style ? style.textColor : "#000000"
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                ComboBox {
                    id: imageViewerCombo
                    Layout.fillWidth: true
                    model: defaultApps.imageViewers
                    editable: true
                    editText: settings ? settings.imagePlayer : ""
                    
                    onEditTextChanged: {
                        imagePathInput.text = editText
                    }
                    
                    delegate: ItemDelegate {
                        width: parent.width
                        contentItem: Text {
                            text: modelData
                            elide: Text.ElideMiddle
                            font.family: style ? style.fontFamily : "Microsoft YaHei"
                            font.pixelSize: style ? style.defaultFontSize - 1 : 11
                        }
                    }
                }
                
                TextField {
                    id: imagePathInput
                    Layout.fillWidth: true
                    visible: false
                    placeholderText: qsTr("请选择图片查看器程序")
                    selectByMouse: true
                    font.family: style ? style.fontFamily : "Microsoft YaHei"
                    font.pixelSize: style ? style.defaultFontSize : 12
                    
                    background: Rectangle {
                        implicitHeight: 32
                        color: "white"
                        border.color: parent.activeFocus ? 
                            (style ? style.accentColor : "#0078D4") : 
                            (style ? style.borderColor : "#E5E5E5")
                        border.width: parent.activeFocus ? 2 : 1
                        radius: 4
                    }
                }
                
                Button {
                    text: qsTr("浏览")
                    icon.source: "qrc:/resources/images/folder.svg"
                    icon.width: 14
                    icon.height: 14
                    padding: 6
                    
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
            spacing: 8
            
            Label {
                text: qsTr("视频播放器路径")
                font.family: style ? style.fontFamily : "Microsoft YaHei"
                font.pixelSize: style ? style.defaultFontSize : 12
                color: style ? style.textColor : "#000000"
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                ComboBox {
                    id: videoPlayerCombo
                    Layout.fillWidth: true
                    model: defaultApps.videoPlayers
                    editable: true
                    editText: settings ? settings.videoPlayer : ""
                    
                    onEditTextChanged: {
                        videoPathInput.text = editText
                    }
                    
                    delegate: ItemDelegate {
                        width: parent.width
                        contentItem: Text {
                            text: modelData
                            elide: Text.ElideMiddle
                            font.family: style ? style.fontFamily : "Microsoft YaHei"
                            font.pixelSize: style ? style.defaultFontSize - 1 : 11
                        }
                    }
                }
                
                TextField {
                    id: videoPathInput
                    Layout.fillWidth: true
                    visible: false
                    placeholderText: qsTr("请选择视频播放器程序")
                    selectByMouse: true
                    font.family: style ? style.fontFamily : "Microsoft YaHei"
                    font.pixelSize: style ? style.defaultFontSize : 12
                    
                    background: Rectangle {
                        implicitHeight: 32
                        color: "white"
                        border.color: parent.activeFocus ? 
                            (style ? style.accentColor : "#0078D4") : 
                            (style ? style.borderColor : "#E5E5E5")
                        border.width: parent.activeFocus ? 2 : 1
                        radius: 4
                    }
                }
                
                Button {
                    text: qsTr("浏览")
                    onClicked: {
                        fileDialog.forImage = false
                        fileDialog.open()
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // 底部按钮
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: qsTr("确定")
                onClicked: {
                    console.log("保存设置 - 图片查看器:", imagePathInput.text);
                    console.log("保存设置 - 视频播放器:", videoPathInput.text);
                    
                    // 使用传入的 settings 对象保存设置
                    if (settings) {
                        settings.imagePlayer = imagePathInput.text;
                        settings.videoPlayer = videoPathInput.text;
                        
                        // 更新 ComboBox 的选项
                        // 注意：由于 model 来自 defaultApps，��们不能直接修改它
                        // 而是通过 defaultApps 来更新
                        if (defaultApps) {
                            defaultApps.addImageViewer(imagePathInput.text);
                            defaultApps.addVideoPlayer(videoPathInput.text);
                        }
                    } else {
                        console.error("settings 对象未定义!");
                    }
                    
                    root.accept();
                }
            }
            
            Button {
                text: qsTr("取消")
                onClicked: root.reject()
            }
        }
    }
}
