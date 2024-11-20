#pragma once
#include <QStringList>

namespace FileTypes {
    // 图片文件格式
    const QStringList IMAGE_EXTENSIONS = {
        "jpg", "jpeg", "png", "gif", "bmp", "webp", "tiff", "svg", "ico"
    };
    
    const QStringList IMAGE_FILTERS = {
        "*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.webp", "*.tiff", "*.svg", "*.ico"
    };
    
    // 视频文件格式
    const QStringList VIDEO_EXTENSIONS = {
        "mp4", "avi", "mkv", "mov", "wmv", "flv", "webm", "m4v", "mpg", "mpeg", "3gp"
    };
    
    const QStringList VIDEO_FILTERS = {
        "*.mp4", "*.avi", "*.mkv", "*.mov", "*.wmv", "*.flv", "*.webm", "*.m4v", "*.mpg", "*.mpeg", "*.3gp"
    };
    
    // 文档文件格式
    const QStringList DOCUMENT_EXTENSIONS = {
        "txt", "doc", "docx", "pdf", "rtf", "md", "odt"
    };
    
    const QStringList DOCUMENT_FILTERS = {
        "*.txt", "*.doc", "*.docx", "*.pdf", "*.rtf", "*.md", "*.odt"
    };
    
    // 音频文件格式
    const QStringList AUDIO_EXTENSIONS = {
        "mp3", "wav", "flac", "m4a", "aac", "ogg", "wma", "mid"
    };
    
    const QStringList AUDIO_FILTERS = {
        "*.mp3", "*.wav", "*.flac", "*.m4a", "*.aac", "*.ogg", "*.wma", "*.mid"
    };
    
    // 压缩文件格式
    const QStringList ARCHIVE_EXTENSIONS = {
        "zip", "rar", "7z", "tar", "gz", "bz2"
    };
    
    const QStringList ARCHIVE_FILTERS = {
        "*.zip", "*.rar", "*.7z", "*.tar", "*.gz", "*.bz2"
    };
    
    // 开发文件格式
    const QStringList DEV_EXTENSIONS = {
        "cpp", "h", "hpp", "java", "py", "js", "html", "css", "json", "xml"
    };
    
    const QStringList DEV_FILTERS = {
        "*.cpp", "*.h", "*.hpp", "*.java", "*.py", "*.js", "*.html", "*.css", "*.json", "*.xml"
    };
    
    // 辅助函数
    inline bool isImageFile(const QString &extension) {
        return IMAGE_EXTENSIONS.contains(extension.toLower());
    }
    
    inline bool isVideoFile(const QString &extension) {
        return VIDEO_EXTENSIONS.contains(extension.toLower());
    }
    
    inline bool isDocumentFile(const QString &extension) {
        return DOCUMENT_EXTENSIONS.contains(extension.toLower());
    }
    
    inline bool isAudioFile(const QString &extension) {
        return AUDIO_EXTENSIONS.contains(extension.toLower());
    }
    
    inline bool isArchiveFile(const QString &extension) {
        return ARCHIVE_EXTENSIONS.contains(extension.toLower());
    }
    
    inline bool isDevFile(const QString &extension) {
        return DEV_EXTENSIONS.contains(extension.toLower());
    }
    
    // 获取所有支持的文件过滤器
    inline QStringList getAllFilters() {
        QStringList filters;
        filters << IMAGE_FILTERS << VIDEO_FILTERS << DOCUMENT_FILTERS
                << AUDIO_FILTERS << ARCHIVE_FILTERS << DEV_FILTERS;
        return filters;
    }
    
    // 获取文件类型的显示名称
    inline QString getFileTypeName(const QString &extension) {
        QString ext = extension.toLower();
        if (isImageFile(ext)) return "图片";
        if (isVideoFile(ext)) return "视频";
        if (isDocumentFile(ext)) return "文档";
        if (isAudioFile(ext)) return "音频";
        if (isArchiveFile(ext)) return "压缩包";
        if (isDevFile(ext)) return "开发文件";
        return "其他";
    }
} 