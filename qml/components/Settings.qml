import QtQuick
import QtCore
import Qt.labs.platform as Platform

Item {
    id: settings

    // 内部使用 Settings 对象
    QtObject {
        id: internal
        property Settings settings: Settings {
            id: settingsBackend
            location: Settings.UserScope
        }
    }
    
    // 属性定义
    property string imagePlayer: internal.settings.value("imagePlayer", "")
    property string videoPlayer: internal.settings.value("videoPlayer", "")
    property string fileFilter: internal.settings.value("fileFilter", "")
    property string ffmpegPath: internal.settings.value("ffmpegPath", "D:/Environment/ffmpeg")
    
    // 设置文件格式
    property var imageFilter: ["jpg", "jpeg", "png", "gif", "bmp", "webp", "tiff", "svg", "ico"]
    property var videoFilter: ["mp4", "avi", "mkv", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg"]
    property var audioFilter: ["mp3", "wav", "flac", "m4a", "aac", "ogg", "wma"]
    property var documentFilter: ["txt", "doc", "docx", "pdf", "xls", "xlsx", "ppt", "pptx", "md"]
    property var archiveFilter: ["zip", "rar", "7z", "tar", "gz", "bz2"]
    property var devFilter: ["cpp", "h", "hpp", "c", "py", "js", "html", "css", "java", "json", "xml", "yml", "qml"]
    
    property int iconSize: internal.settings.value("iconSize", 128)
    property string previewQuality: internal.settings.value("previewQuality", "medium")
    
    // 同步方法
    function sync() {
        internal.settings.sync()
        console.log("Settings 完整信息:", JSON.stringify({
            imagePlayer: imagePlayer,
            videoPlayer: videoPlayer,
            fileFilter: fileFilter,
            ffmpegPath: ffmpegPath,
            iconSize: iconSize,
            previewQuality: previewQuality
        }, null, 2))
    }
    
    function setValue(key: string, value: any) {
        console.log("Settings setValue - key:", key, "value:", value)
        
        internal.settings.setValue(key, value)
        
        // 更新对应的属性
        if (key === "imagePlayer") {
            imagePlayer = value
        } else if (key === "videoPlayer") {
            videoPlayer = value
        } else if (key === "fileFilter") {
            fileFilter = value
        } else if (key === "ffmpegPath") {
            ffmpegPath = value
        } else if (key === "iconSize") {
            iconSize = value
        } else if (key === "previewQuality") {
            previewQuality = value
        }
        
        // 输出当前状态
        console.log("Settings 当前状态:")
        console.log("- imagePlayer:", imagePlayer)
        console.log("- videoPlayer:", videoPlayer)
        console.log("- fileFilter:", fileFilter)
        console.log("- ffmpegPath:", ffmpegPath)
        console.log("- iconSize:", iconSize)
        console.log("- previewQuality:", previewQuality)
    }
    
    function value(key: string, defaultValue: any): any {
        return internal.settings.value(key, defaultValue)
    }
    
    Component.onCompleted: {
        sync()
    }
}
