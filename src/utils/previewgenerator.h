#pragma once
#include <QObject>
#include <QFuture>
#include <QFutureWatcher>
#include <memory>
#include <QWeakPointer>
#include "../models/filedata.h"
#include "filetypes.h"
#include "spritegenerator.h"

class PreviewGenerator : public QObject {
    Q_OBJECT
public:
    explicit PreviewGenerator(QObject *parent = nullptr);
    void generatePreview(QSharedPointer<FileData> fileData);
    static QString getCachePath();
    Q_INVOKABLE QStringList generateVideoSprites(const QString &path, int count);
    double getSpriteTimestamp(const QString &spritePath) const;

signals:
    void spritesGenerated(const QStringList &paths);
    void spriteProgress(int current, int total);

private:
    QString generateImagePreview(const QString &path);
    QString generateVideoPreview(const QString &path);
    void ensureCacheDirectory();
    
    QFutureWatcher<QString> m_watcher;
    QString m_cacheDir;
    QWeakPointer<FileData> m_currentFile;
    std::unique_ptr<SpriteGenerator> m_spriteGenerator;
}; 