import QtQuick
import Qt.labs.settings
import Qt.labs.platform as Platform

Settings {
    id: settings
    
    // 使用标准路径和统一的文件名
    fileName: {
        const dataPath = Platform.StandardPaths.writableLocation(Platform.StandardPaths.AppDataLocation)
        // 将 URL 转换为本地路径
        const url = Qt.resolvedUrl(dataPath)
        const localPath = url.toString().replace(/^file:\/\/\//, "")
        // 在 Windows 上确保使用反斜杠
        const normalizedPath = Qt.platform.os === "windows" ? 
            localPath.split("/").join("\\") : 
            localPath
        const path = normalizedPath + (Qt.platform.os === "windows" ? "\\" : "/") + "FileTaggingPro.ini"
        console.log("Settings file path (normalized):", path)
        return path
    }
    
    category: "General"
    
    property string imagePlayer: ""  // 图片查看器路径
    property string videoPlayer: ""  // 视频播放器路径
    property string fileFilter: ""   // 文件筛选器设置

    // 设置文件格式
    property var imageFilter: ["jpg", "jpeg", "png", "gif", "bmp", "webp", "tiff", "svg", "ico"]  // 图片文件格式
    property var videoFilter: ["mp4", "avi", "mkv", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg"]  // 视频文件格式
    property var audioFilter: ["mp3", "wav", "flac", "m4a", "aac", "ogg", "wma"]  // 音频文件格式
    property var documentFilter: ["txt", "doc", "docx", "pdf", "xls", "xlsx", "ppt", "pptx", "md"]  // 文档文件格式
    property var archiveFilter: ["zip", "rar", "7z", "tar", "gz", "bz2"]  // 压缩文件格式
    property var devFilter: ["cpp", "h", "hpp", "c", "py", "js", "html", "css", "java", "json", "xml", "yml", "qml"]  // 开发文件格式
    
    property int iconSize: 128  // 默认图标大小
    property string previewQuality: "medium"  // 默认预览质量
    
    // 添加同步方法
    function sync() {
        // 输出完整的设置信息
        console.log("Settings 完整信息:", JSON.stringify({
            category: category,
            fileName: fileName,
            imagePlayer: imagePlayer,
            videoPlayer: videoPlayer,
            fileFilter: fileFilter
        }, null, 2));
    }
    
    function setValue(key: string, value: any) {
        console.log("Settings setValue - key:", key, "value:", value);
        
        if (key === "imagePlayer") {
            imagePlayer = value;
        } else if (key === "videoPlayer") {
            videoPlayer = value;
        } else if (key === "fileFilter") {
            fileFilter = value;
        } else if (key === "iconSize") {
            iconSize = value;
        } else if (key === "previewQuality") {
            previewQuality = value;
        }
        
        // 每次设置值后输出当前状态
        console.log("Settings 当前状态:");
        console.log("Settings 文件路径:", fileName);
        console.log("- imagePlayer:", imagePlayer);
        console.log("- videoPlayer:", videoPlayer);
        console.log("- fileFilter:", fileFilter);
        console.log("- iconSize:", iconSize);
        console.log("- previewQuality:", previewQuality);
    }
    
    function value(key: string, defaultValue: any): any {
        let result;
        if (key === "imagePlayer") {
            result = imagePlayer || defaultValue;
        } else if (key === "videoPlayer") {
            result = videoPlayer || defaultValue;
        } else if (key === "fileFilter") {
            result = fileFilter || defaultValue;
        } else {
            result = defaultValue;
        }
        
        console.log("Settings value - key:", key, "defaultValue:", defaultValue, "result:", result);
        return result;
    }
    
    // 修改组件完成时的处理
    Component.onCompleted: {
        // 强制同步一次设置
        sync()
    }
}
