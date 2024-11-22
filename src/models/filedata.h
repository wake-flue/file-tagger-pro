#ifndef FILEDATA_H
#define FILEDATA_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QImage>

class FileData : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString fileName READ fileName WRITE setFileName NOTIFY fileNameChanged)
    Q_PROPERTY(QString fileIcon READ fileIcon WRITE setFileIcon NOTIFY fileIconChanged)
    Q_PROPERTY(qint64 fileSize READ fileSize WRITE setFileSize NOTIFY fileSizeChanged)
    Q_PROPERTY(QString fileType READ fileType WRITE setFileType NOTIFY fileTypeChanged)
    Q_PROPERTY(QString filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(QDateTime modifiedDate READ modifiedDate WRITE setModifiedDate NOTIFY modifiedDateChanged)
    Q_PROPERTY(QString fileId READ fileId WRITE setFileId NOTIFY fileIdChanged)
    Q_PROPERTY(QString relativePath READ relativePath WRITE setRelativePath NOTIFY relativePathChanged)
    Q_PROPERTY(QString displaySize READ displaySize NOTIFY fileSizeChanged)
    Q_PROPERTY(QString previewPath READ previewPath WRITE setPreviewPath NOTIFY previewPathChanged)
    Q_PROPERTY(bool previewLoading READ previewLoading WRITE setPreviewLoading NOTIFY previewLoadingChanged)

public:
    explicit FileData(QObject *parent = nullptr);
    
    // 移除删除的复制构造函数和赋值运算符
    FileData(const FileData &other);
    FileData& operator=(const FileData &other);
    
    // 保留移动构造函数和移动赋值运算符
    FileData(FileData &&other) noexcept;
    FileData& operator=(FileData &&other) noexcept;

    QString fileName() const { return m_fileName; }
    QString fileIcon() const { return m_fileIcon; }
    qint64 fileSize() const { return m_fileSize; }
    QString fileType() const { return m_fileType; }
    QString filePath() const { return m_filePath; }
    QDateTime modifiedDate() const { return m_modifiedDate; }
    QString fileId() const { return m_fileId; }
    QString relativePath() const { return m_relativePath; }
    QString displaySize() const {
        const QStringList units = {"B", "KB", "MB", "GB", "TB"};
        int unitIndex = 0;
        double size = m_fileSize;

        while (size >= 1024.0 && unitIndex < units.size() - 1) {
            size /= 1024.0;
            unitIndex++;
        }

        return QString("%1 %2").arg(size, 0, 'f', 1).arg(units[unitIndex]);
    }
    QString previewPath() const { return m_previewPath; }
    void setPreviewPath(const QString &path);
    bool previewLoading() const { return m_previewLoading; }
    void setPreviewLoading(bool loading);

    void setFileName(const QString &fileName);
    void setFileIcon(const QString &fileIcon);
    void setFileSize(qint64 fileSize);
    void setFileType(const QString &fileType);
    void setFilePath(const QString &filePath);
    void setModifiedDate(const QDateTime &modifiedDate);
    void setFileId(const QString &fileId);
    void setRelativePath(const QString &relativePath);

    void clearPreview();

signals:
    void fileNameChanged();
    void fileIconChanged();
    void fileSizeChanged();
    void fileTypeChanged();
    void filePathChanged();
    void modifiedDateChanged();
    void fileIdChanged();
    void relativePathChanged();
    void previewPathChanged();
    void previewLoadingChanged();

private:
    QString m_fileName;
    QString m_fileIcon;
    qint64 m_fileSize;
    QString m_fileType;
    QString m_filePath;
    QDateTime m_modifiedDate;
    QString m_fileId;
    QString m_relativePath;
    QString m_previewPath;
    bool m_previewLoading = false;
    QImage m_preview;
    bool m_previewGenerated = false;
};

Q_DECLARE_METATYPE(FileData)

#endif // FILEDATA_H
