import QtCore

Settings {
    id: settings
    
    property string imagePlayer: ""  // 图片查看器路径
    property string videoPlayer: ""  // 视频播放器路径
    property string fileFilter: ""   // 文件筛选器设置
    property string ffmpegPath: "D:/Environment/ffmpeg-7.1-full_build"  // FFmpeg 路径
    
    function setValue(key: string, value: any) {
        if (key === "fileFilter") {
            fileFilter = value;
        } else if (key === "ffmpegPath") {
            ffmpegPath = value;
        }
    }
    
    function value(key: string, defaultValue: any): any {
        if (key === "fileFilter") {
            return fileFilter || defaultValue;
        } else if (key === "ffmpegPath") {
            return ffmpegPath || defaultValue;
        }
        return defaultValue;
    }
}
