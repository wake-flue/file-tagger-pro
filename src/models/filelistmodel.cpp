#include "filelistmodel.h"
#include <QHash>
#include <QString>
#include <QByteArray>
#include <QVector>
#include <QDebug>
#include <algorithm>
#include <QRegularExpression>
#include <QImageReader>

FileListModel::FileListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    initialize();
}

void FileListModel::initialize()
{
    QImageReader::setAllocationLimit(64);
}

int FileListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_filteredFiles.count();
}

QVariant FileListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_filteredFiles.count())
        return defaultValue(role);

    const auto &file = m_filteredFiles.at(index.row());
    if (!file)
        return defaultValue(role);
    
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
        case PreviewPathRole: {
            QString path = file->previewPath();
            // if (!path.isEmpty()) {
            //     qDebug() << "返回预览路径:" << file->fileName() << path;
            // }
            return path;
        }
        case PreviewLoadingRole:
            return file->previewLoading();
        default:
            return defaultValue(role);
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
    m_allFiles = files;
    applyFilters();
    endResetModel();
    emit countChanged();
}

void FileListModel::clear()
{
    beginResetModel();
    m_filteredFiles.clear();
    endResetModel();
    emit countChanged();
}

void FileListModel::setViewMode(ViewMode mode)
{
    if (m_viewMode == mode)
        return;
        
    m_viewMode = mode;
    beginResetModel();
    
    // 如果切换到大图标视图，通知需要生成预览
    if (mode == LargeIconView) {
        emit needGeneratePreviews();
    }
    
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
        {DisplayDateRole, "displayDate"},
        {IndexRole, "index"},
        {PreviewPathRole, "previewPath"},
        {PreviewLoadingRole, "previewLoading"}
    };
}

FileData* FileListModel::getFileData(int index) const {
    if (index < 0 || index >= m_filteredFiles.size()) {
        return nullptr;
    }
    
    return m_filteredFiles[index].data();
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
    std::sort(m_filteredFiles.begin(), m_filteredFiles.end(), 
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
        for (const auto &file : m_filteredFiles) {
            if (matchesFilter(file->fileName())) {
                filteredFiles.append(file);
            }
        }
        m_filteredFiles = filteredFiles;
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
    m_filteredFiles = newFiles;
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
        case PreviewPathRole:
            return QString();
        case PreviewLoadingRole:
            return false;
        default:
            return QVariant();
    }
}

void FileListModel::setSearchPattern(const QString &pattern)
{
    if (m_searchPattern != pattern) {
        m_searchPattern = pattern;
        applyFilters();
        emit searchPatternChanged();
    }
}

void FileListModel::applyFilters()
{
    m_filteredFiles.clear();
    
    for (const auto &file : m_allFiles) {
        bool matchesSearchPattern = m_searchPattern.isEmpty() ||
            file->fileName().contains(m_searchPattern, Qt::CaseInsensitive);
        bool matchesFilterPattern = m_filterPattern.isEmpty() || 
            this->matchesFilter(file->fileName());  // 使用 this-> 明确指定是成员函数
        
        if (matchesSearchPattern && matchesFilterPattern) {
            m_filteredFiles.append(file);
        }
    }
    
    // 更新视图
    beginResetModel();
    m_files = m_filteredFiles;
    endResetModel();
}

void FileListModel::clearPreviews()
{
    // 清除所有文件的预览缓存
    for (auto &file : m_files) {
        if (file) {
            file->clearPreview();
        }
    }
    
    // 触发视图更新
    if (!m_files.isEmpty()) {
        emit dataChanged(index(0), index(m_files.size() - 1));
    }
}
