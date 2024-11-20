#pragma once
#include <QObject>
#include <QFuture>
#include <QFutureWatcher>
#include <memory>
#include <QWeakPointer>
#include "../models/filedata.h"
#include "filetypes.h"

class PreviewGenerator : public QObject {
    Q_OBJECT
public:
    explicit PreviewGenerator(QObject *parent = nullptr);
    void generatePreview(QSharedPointer<FileData> fileData);
    static QString getCachePath();

private:
    QString generateImagePreview(const QString &path);
    QString generateVideoPreview(const QString &path);
    void ensureCacheDirectory();
    
    QFutureWatcher<QString> m_watcher;
    QString m_cacheDir;
    QWeakPointer<FileData> m_currentFile;
}; 