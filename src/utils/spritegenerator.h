#pragma once
#include <QObject>
#include <QString>
#include <QStringList>
#include <QMap>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

class SpriteGenerator : public QObject {
    Q_OBJECT
public:
    explicit SpriteGenerator(QObject *parent = nullptr);
    
    // 生成雪碧图
    QStringList generateSprites(const QString &videoPath, int count);
    
    // 获取指定雪碧图的时间戳（秒）
    double getSpriteTimestamp(const QString &spritePath) const;
    
    // 设置和获取缓存目录
    void setCacheDirectory(const QString &path) { m_cacheDir = path; }
    QString cacheDirectory() const { return m_cacheDir; }

signals:
    void progressChanged(int current, int total);
    void error(const QString &message);

private:
    QString generateSingleSprite(AVFormatContext *formatContext, 
                               int videoStream,
                               qint64 timestamp,
                               const QString &outputPath);
                               
    void ensureCacheDirectory();
    QString m_cacheDir;
    QMap<QString, double> m_spriteTimestamps;  // 存储雪碧图路径和对应的时间戳
}; 