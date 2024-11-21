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
    
    category: "Players"
    
    property string imagePlayer: ""  // 图片查看器路径
    property string videoPlayer: ""  // 视频播放器路径
    property string fileFilter: ""   // 文件筛选器设置
    property string ffmpegPath: "D:/Environment/ffmpeg-7.1-full_build"  // FFmpeg 路径
    
    // 添加同步方法
    function sync() {
        // Qt.labs.settings 会自动同步，不需要手动调用
        console.log("Settings synced - imagePlayer:", imagePlayer);
        console.log("Settings synced - videoPlayer:", videoPlayer);
        console.log("Settings synced - fileFilter:", fileFilter);
        console.log("Settings synced - ffmpegPath:", ffmpegPath);
        
        // 输出完整的设置信息
        console.log("Settings 完整信息:", JSON.stringify({
            category: category,
            fileName: fileName,
            imagePlayer: imagePlayer,
            videoPlayer: videoPlayer,
            fileFilter: fileFilter,
            ffmpegPath: ffmpegPath
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
        } else if (key === "ffmpegPath") {
            ffmpegPath = value;
        }
        
        // 每次设置值后输出当前状态
        console.log("Settings 当前状态:");
        console.log("Settings 文件路径:", fileName);
        console.log("- imagePlayer:", imagePlayer);
        console.log("- videoPlayer:", videoPlayer);
        console.log("- fileFilter:", fileFilter);
        console.log("- ffmpegPath:", ffmpegPath);
    }
    
    function value(key: string, defaultValue: any): any {
        let result;
        if (key === "imagePlayer") {
            result = imagePlayer || defaultValue;
        } else if (key === "videoPlayer") {
            result = videoPlayer || defaultValue;
        } else if (key === "fileFilter") {
            result = fileFilter || defaultValue;
        } else if (key === "ffmpegPath") {
            result = ffmpegPath || defaultValue;
        } else {
            result = defaultValue;
        }
        
        console.log("Settings value - key:", key, "defaultValue:", defaultValue, "result:", result);
        return result;
    }
    
    // 修改组件完成时的处理
    Component.onCompleted: {
        console.log("Settings 组件初始化完成")
        console.log("Settings 文件路径:", fileName)
        console.log("初始设置值:")
        console.log("- imagePlayer:", imagePlayer)
        console.log("- videoPlayer:", videoPlayer)
        console.log("- fileFilter:", fileFilter)
        console.log("- ffmpegPath:", ffmpegPath)
        
        // 强制同步一次设置
        sync()
    }
}
