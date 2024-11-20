#include "filedata.h"

// 由于 FileData 是一个 Q_GADGET 结构体，目前不需要额外的实现
// 但保留这个文件以便将来可能的扩展

FileData::FileData(QObject *parent)
    : QObject(parent)
    , m_fileSize(0)
{
}

FileData::FileData(const FileData &other)
    : QObject(other.parent())
    , m_fileName(other.m_fileName)
    , m_fileIcon(other.m_fileIcon)
    , m_fileSize(other.m_fileSize)
    , m_fileType(other.m_fileType)
    , m_filePath(other.m_filePath)
    , m_modifiedDate(other.m_modifiedDate)
    , m_fileId(other.m_fileId)
    , m_relativePath(other.m_relativePath)
{
}

FileData& FileData::operator=(const FileData &other)
{
    if (this != &other) {
        setParent(other.parent());
        m_fileName = other.m_fileName;
        m_fileIcon = other.m_fileIcon;
        m_fileSize = other.m_fileSize;
        m_fileType = other.m_fileType;
        m_filePath = other.m_filePath;
        m_modifiedDate = other.m_modifiedDate;
        m_fileId = other.m_fileId;
        m_relativePath = other.m_relativePath;
    }
    return *this;
}

FileData::FileData(FileData &&other) noexcept
    : QObject(other.parent())
{
    m_fileName = std::move(other.m_fileName);
    m_fileIcon = std::move(other.m_fileIcon);
    m_fileSize = other.m_fileSize;
    m_fileType = std::move(other.m_fileType);
    m_filePath = std::move(other.m_filePath);
    m_modifiedDate = other.m_modifiedDate;
    m_fileId = std::move(other.m_fileId);
    m_relativePath = std::move(other.m_relativePath);
    
    other.setParent(nullptr);
}

FileData& FileData::operator=(FileData &&other) noexcept
{
    if (this != &other) {
        setParent(other.parent());
        m_fileName = std::move(other.m_fileName);
        m_fileIcon = std::move(other.m_fileIcon);
        m_fileSize = other.m_fileSize;
        m_fileType = std::move(other.m_fileType);
        m_filePath = std::move(other.m_filePath);
        m_modifiedDate = other.m_modifiedDate;
        m_fileId = std::move(other.m_fileId);
        m_relativePath = std::move(other.m_relativePath);
        
        other.setParent(nullptr);
    }
    return *this;
}

void FileData::setFileName(const QString &fileName)
{
    if (m_fileName != fileName) {
        m_fileName = fileName;
        emit fileNameChanged();
    }
}

void FileData::setFileIcon(const QString &fileIcon)
{
    if (m_fileIcon != fileIcon) {
        m_fileIcon = fileIcon;
        emit fileIconChanged();
    }
}

void FileData::setFileSize(qint64 fileSize)
{
    if (m_fileSize != fileSize) {
        m_fileSize = fileSize;
        emit fileSizeChanged();
    }
}

void FileData::setFileType(const QString &fileType)
{
    if (m_fileType != fileType) {
        m_fileType = fileType;
        emit fileTypeChanged();
    }
}

void FileData::setFilePath(const QString &filePath)
{
    if (m_filePath != filePath) {
        m_filePath = filePath;
        emit filePathChanged();
    }
}

void FileData::setModifiedDate(const QDateTime &modifiedDate)
{
    if (m_modifiedDate != modifiedDate) {
        m_modifiedDate = modifiedDate;
        emit modifiedDateChanged();
    }
}

void FileData::setFileId(const QString &fileId)
{
    if (m_fileId != fileId) {
        m_fileId = fileId;
        emit fileIdChanged();
    }
}

void FileData::setRelativePath(const QString &relativePath)
{
    if (m_relativePath != relativePath) {
        m_relativePath = relativePath;
        emit relativePathChanged();
    }
}
