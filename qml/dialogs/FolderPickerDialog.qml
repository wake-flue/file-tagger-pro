import QtQuick
import QtQuick.Dialogs
import Qt.labs.platform as Platform

Platform.FolderDialog {
    id: dialog
    title: qsTr("选择要监控的文件夹")
    currentFolder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
    
    signal folderSelected(string path)
    
    onAccepted: {
        let path = currentFolder.toString()
        path = path.replace(/^(file:\/{3})/,"")
        path = path.replace(/\//g, "\\")
        path = decodeURIComponent(path)
        folderSelected(path)
    }
}
