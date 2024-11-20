import QtCore

Settings {
    id: settings
    
    property string imagePlayer: ""  // 图片查看器路径
    property string videoPlayer: ""  // 视频播放器路径
    property string fileFilter: ""   // 保持原有的文件筛选器设置
    
    function setValue(key: string, value: any) {
        if (key === "fileFilter") {
            fileFilter = value;
        }
    }
    
    function value(key: string, defaultValue: any): any {
        if (key === "fileFilter") {
            return fileFilter || defaultValue;
        }
        return defaultValue;
    }
}
