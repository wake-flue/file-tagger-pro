#include "filelistmodel.h"
#include <QHash>
#include <QString>
#include <QByteArray>
#include <QVector>
#include <QDebug>
#include <algorithm>
#include <QRegularExpression>

FileListModel::FileListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int FileListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_files.count();
}

QVariant FileListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_files.count())
        return QVariant();

    const auto &file = m_files.at(index.row());
    
    switch (role) {
        case FileNameRole:
            return file->fileName();
        case FileSizeRole:
            return file->fileSize();
        case FileTypeRole:
            return file->fileType();
        case FilePathRole:
            return file->filePath();
        case DisplaySizeRole:
            return file->displaySize();
        case DisplayDateRole:
            return file->modifiedDate().toString("yyyy-MM-dd hh:mm:ss");
        default:
            return QVariant();
    }
}

// 添加辅助函数用于格式化文件大小
QString FileListModel::formatFileSize(qint64 size) const
{
    const QStringList units = {"B", "KB", "MB", "GB", "TB"};
    int unitIndex = 0;
    double fileSize = size;

    while (fileSize >= 1024.0 && unitIndex < units.size() - 1) {
        fileSize /= 1024.0;
        unitIndex++;
    }

    return QString("%1 %2").arg(fileSize, 0, 'f', 1).arg(units[unitIndex]);
}

void FileListModel::setFiles(const QVector<QSharedPointer<FileData>> &files)
{
    beginResetModel();
    m_files = files;  // 直接赋值
    endResetModel();
    emit countChanged();
}

void FileListModel::clear()
{
    beginResetModel();
    m_files.clear();
    endResetModel();
    emit countChanged();
}

void FileListModel::setViewMode(ViewMode mode)
{
    if (m_viewMode == mode)
        return;
    m_viewMode = mode;
    beginResetModel();
    endResetModel();
    emit viewModeChanged();
}

QHash<int, QByteArray> FileListModel::roleNames() const
{
    return {
        {FileNameRole, "fileName"},
        {FileSizeRole, "fileSize"},
        {FileTypeRole, "fileType"},
        {FilePathRole, "filePath"},
        {DisplaySizeRole, "displaySize"},
        {DisplayDateRole, "displayDate"}
    };
}

FileData* FileListModel::getFileData(int index) const {
    if (index < 0 || index >= m_files.size()) {
        return nullptr;
    }
    
    return m_files[index].data();
}

void FileListModel::setSortRole(SortRole role)
{
    if (m_sortRole != role) {
        m_sortRole = role;
        sort();
        emit sortRoleChanged();
    }
}

void FileListModel::setSortOrder(Qt::SortOrder order)
{
    if (m_sortOrder != order) {
        m_sortOrder = order;
        sort();
        emit sortOrderChanged();
    }
}

void FileListModel::sort()
{
    beginResetModel();
    std::sort(m_files.begin(), m_files.end(), 
        [this](const QSharedPointer<FileData> &a, const QSharedPointer<FileData> &b) {
            bool result = false;
            switch (m_sortRole) {
                case SortByName:
                    result = a->fileName().toLower() < b->fileName().toLower();
                    break;
                case SortBySize:
                    result = a->fileSize() < b->fileSize();
                    break;
                case SortByType:
                    result = a->fileType().toLower() < b->fileType().toLower();
                    break;
                case SortByDate:
                    result = a->modifiedDate() < b->modifiedDate();
                    break;
            }
            return m_sortOrder == Qt::AscendingOrder ? result : !result;
        });
    endResetModel();
}

void FileListModel::setFilterPattern(const QString &pattern)
{
    if (m_filterPattern != pattern) {
        m_filterPattern = pattern;
        
        // 重新过滤文件列表
        beginResetModel();
        // 过滤逻辑在这里实现
        QVector<QSharedPointer<FileData>> filteredFiles;
        for (const auto &file : m_files) {
            if (matchesFilter(file->fileName())) {
                filteredFiles.append(file);
            }
        }
        m_files = filteredFiles;
        endResetModel();
        
        emit filterPatternChanged();
        emit countChanged();
    }
}

bool FileListModel::matchesFilter(const QString &fileName) const
{
    if (m_filterPattern.isEmpty()) {
        return true;
    }
    
    QStringList patterns = m_filterPattern.split(';', Qt::SkipEmptyParts);
    for (const QString &pattern : patterns) {
        // 将通配符模式转换为正则表达式模式
        QString regexPattern = QRegularExpression::wildcardToRegularExpression(pattern.trimmed());
        QRegularExpression rx(regexPattern, QRegularExpression::CaseInsensitiveOption);
        if (rx.match(fileName).hasMatch()) {
            return true;
        }
    }
    return false;
}

void FileListModel::updateFiles(const QVector<QSharedPointer<FileData>>& newFiles)
{
    beginResetModel();
    m_files = newFiles;
    endResetModel();
    emit countChanged();
}

// 添加默认值处理函数
QVariant FileListModel::defaultValue(int role) const
{
    switch (role) {
        case IndexRole:
            return -1;
        case FileNameRole:
            return QString();
        case FileSizeRole:
            return 0;
        case FileTypeRole:
            return QString();
        case FilePathRole:
            return QString();
        case DisplaySizeRole:
            return QString("0 B");
        case DisplayDateRole:
            return QString();
        case Qt::DisplayRole:
            return QString();
        default:
            return QVariant();
    }
}
