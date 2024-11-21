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
    Q_PROPERTY(QString currentPath READ currentPath NOTIFY currentPathChanged)
    Q_PROPERTY(QStringList logMessages READ logMessages NOTIFY logMessagesChanged)
    Q_PROPERTY(FileListModel* fileModel READ fileModel CONSTANT)

public:
    explicit FileSystemManager(QObject *parent = nullptr);
    ~FileSystemManager();
    
    QString currentPath() const { return m_currentPath; }
    QStringList logMessages() const { return m_messages; }
    FileListModel* fileModel() const { return m_fileModel; }
    
    Q_INVOKABLE void setWatchPath(const QString &path);
    Q_INVOKABLE QVector<QSharedPointer<FileData>> scanDirectory(const QString &path, const QStringList &filters = QStringList());
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE QString getFfmpegPath() const;
    Q_INVOKABLE void setFfmpegPath(const QString &path);

public slots:
    Q_INVOKABLE void openFileWithProgram(const QString &filePath, const QString &programPath);
    void generatePreviews();
    void openFile(const QString &filePath, const QString &fileType);

signals:
    void fileChanged(const QString &path);
    void directoryChanged(const QString &path);
    void fileListChanged();
    void currentPathChanged();
    void logMessagesChanged();

private:
    void addLogMessage(const QString &message);
    QString getFileId(const QString &filePath);
    void setupFileWatcher();
    
    QFileSystemWatcher *m_fileWatcher;
    QString m_currentPath;
    QStringList m_messages;
    Logger *m_logger;
    FileListModel *m_fileModel;
    QVector<QSharedPointer<FileData>> m_fileList;  // 添加文件列表成员变量
    QString m_ffmpegPath;
    std::unique_ptr<PreviewGenerator> m_previewGenerator;
};

#endif // FILESYSTEMMANAGER_H
