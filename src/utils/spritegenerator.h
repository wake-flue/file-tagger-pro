#pragma once
#include <QObject>
#include <QString>
#include <QStringList>
#include <QMap>
#include <QMutex>
#include <QThreadPool>
#include <QRunnable>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

class SpriteGeneratorTask;

class SpriteGenerator : public QObject {
    Q_OBJECT
public:
    explicit SpriteGenerator(QObject *parent = nullptr);
    ~SpriteGenerator();
    
    QStringList generateSprites(const QString &videoPath, int count);
    double getSpriteTimestamp(const QString &spritePath) const;
    void setCacheDirectory(const QString &path) { m_cacheDir = path; }
    QString cacheDirectory() const { return m_cacheDir; }

signals:
    void progressChanged(int current, int total);
    void error(const QString &message);

private:
    friend class SpriteGeneratorTask;
    void ensureCacheDirectory();
    QString generateSingleSprite(AVFormatContext *formatContext, 
                               int videoStream,
                               qint64 timestamp,
                               const QString &outputPath);
                               
    QString m_cacheDir;
    QMap<QString, double> m_spriteTimestamps;
    QMutex m_mutex;
    QThreadPool *m_threadPool;
    int m_completedTasks;
    int m_totalTasks;
};

class SpriteGeneratorTask : public QRunnable {
public:
    SpriteGeneratorTask(SpriteGenerator *generator,
                       AVFormatContext *formatContext,
                       int videoStream,
                       qint64 timestamp,
                       const QString &outputPath);
    ~SpriteGeneratorTask();
    void run() override;

private:
    SpriteGenerator *m_generator;
    AVFormatContext *m_formatContext;
    int m_videoStream;
    qint64 m_timestamp;
    QString m_outputPath;
}; 