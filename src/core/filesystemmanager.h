#ifndef FILESYSTEMMANAGER_H
#define FILESYSTEMMANAGER_H

#include <QObject>
#include <QFileSystemWatcher>
#include <QFileInfo>
#include <QString>
#include <QVector>
#include <QDateTime>
#include <QProcess>
#include <QSettings>
#include <windows.h>
#include "models/filedata.h"
#include "utils/logger.h"
#include "models/filelistmodel.h"
#include <memory>
#include "../utils/previewgenerator.h"
#include "utils/filetypes.h"

class FileSystemManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentPath READ currentPath WRITE setCurrentPath NOTIFY currentPathChanged)
    Q_PROPERTY(FileListModel* fileModel READ fileModel CONSTANT)
    Q_PROPERTY(QStringList logMessages READ logMessages NOTIFY logMessagesChanged)
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY isScanningChanged)

public:
    explicit FileSystemManager(QObject *parent = nullptr);
    ~FileSystemManager();
    
    QString currentPath() const { return m_currentPath; }
    void setCurrentPath(const QString &path) { 
        if (m_currentPath != path) {
            m_currentPath = path;
            emit currentPathChanged();
        }
    }
    QStringList logMessages() const { return m_messages; }
    FileListModel* fileModel() const { return m_fileModel; }
    bool isScanning() const { return m_isScanning; }
    
    Q_INVOKABLE void setWatchPath(const QString &path);
    Q_INVOKABLE QVector<QSharedPointer<FileData>> scanDirectory(const QString &path, const QStringList &filters = QStringList());
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE QString getFfmpegPath() const;
    Q_INVOKABLE void setFfmpegPath(const QString &path);
    Q_INVOKABLE void generateVideoSprites(const QString &filePath, int count);

public slots:
    Q_INVOKABLE void openFileWithProgram(const QString &filePath, const QString &programPath);
    void generatePreviews();
    void openFile(const QString &filePath, const QString &fileType);
    void openVideoAtTime(const QString &filePath, double timestamp);
    double getSpriteTimestamp(const QString &spritePath) const;
    void onFileRenamed(const QString &oldPath, const QString &newPath);

signals:
    void fileChanged(const QString &path);
    void directoryChanged(const QString &path);
    void fileListChanged();
    void currentPathChanged();
    void logMessagesChanged();
    void error(const QString &errorMessage);
    void isScanningChanged();
    void spritesGenerated(const QStringList &paths);
    void spriteProgress(int current, int total);
    void fileRenamed(const QString &oldPath, const QString &newPath);

private:
    void addLogMessage(const QString &message);
    QString getFileId(const QString &filePath);
    void setupFileWatcher();
    
    QFileSystemWatcher *m_fileWatcher;
    QString m_currentPath;
    QStringList m_messages;
    Logger *m_logger;
    FileListModel *m_fileModel;
    QVector<QSharedPointer<FileData>> m_fileList;
    QString m_ffmpegPath;
    PreviewGenerator *m_previewGenerator;
    bool m_isScanning = false;
};

#endif // FILESYSTEMMANAGER_H
