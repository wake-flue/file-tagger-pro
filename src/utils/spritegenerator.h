#pragma once
#include <QObject>
#include <QString>
#include <QStringList>

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
}; 