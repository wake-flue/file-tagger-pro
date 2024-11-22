#ifndef FILELISTMODEL_H
#define FILELISTMODEL_H

#include <QAbstractListModel>
#include <QColor>
#include <QSharedPointer>
#include "filedata.h"

class FileListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(ViewMode viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(SortRole sortRole READ sortRole WRITE setSortRole NOTIFY sortRoleChanged)
    Q_PROPERTY(Qt::SortOrder sortOrder READ sortOrder WRITE setSortOrder NOTIFY sortOrderChanged)
    Q_PROPERTY(QString filterPattern READ filterPattern WRITE setFilterPattern NOTIFY filterPatternChanged)
    Q_PROPERTY(QString searchPattern READ searchPattern WRITE setSearchPattern NOTIFY searchPatternChanged)

public:
    // 视图模式枚举
    enum ViewMode {
        ListView,
        LargeIconView
    };
    Q_ENUM(ViewMode)

    enum Roles {
        FileNameRole = Qt::UserRole + 1,
        FileSizeRole,
        FileTypeRole,
        FilePathRole,
        DisplaySizeRole,
        DisplayDateRole,
        IndexRole,
        PreviewPathRole,
        PreviewLoadingRole,
        FileIdRole
    };

    enum SortRole {
        SortByName,
        SortBySize,
        SortByType,
        SortByDate
    };
    Q_ENUM(SortRole)

    explicit FileListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_files.count(); }
    ViewMode viewMode() const { return m_viewMode; }
    SortRole sortRole() const { return m_sortRole; }
    Qt::SortOrder sortOrder() const { return m_sortOrder; }
    QString filterPattern() const { return m_filterPattern; }
    QString searchPattern() const { return m_searchPattern; }

    Q_INVOKABLE FileData* getFileData(int index) const;
    QString getFileId(const QString &filePath) const;
    void updateFiles(const QVector<QSharedPointer<FileData>>& newFiles);

protected:
    QString formatFileSize(qint64 size) const;
    QVariant defaultValue(int role) const;
    void applyFilters();

public slots:
    void setViewMode(ViewMode mode);
    void setSortRole(SortRole role);
    void setSortOrder(Qt::SortOrder order);
    void setFilterPattern(const QString &pattern);
    void setSearchPattern(const QString &pattern);
    void setFiles(const QVector<QSharedPointer<FileData>> &files);
    void clear();
    void clearPreviews();
    void setFilterByFileIds(const QStringList &fileIds, bool showAllIfEmpty = false);
    void clearFilter() {
        setFilterPattern("");
        setSearchPattern("");
        setFilterByFileIds(QStringList(), true);
    }

signals:
    void countChanged();
    void viewModeChanged();
    void sortRoleChanged();
    void sortOrderChanged();
    void filterPatternChanged();
    void searchPatternChanged();
    void needGeneratePreviews();

private:
    QVector<QSharedPointer<FileData>> m_files;
    QVector<QSharedPointer<FileData>> m_allFiles;
    QVector<QSharedPointer<FileData>> m_filteredFiles;
    ViewMode m_viewMode = ListView;
    SortRole m_sortRole = SortByName;
    Qt::SortOrder m_sortOrder = Qt::AscendingOrder;
    QString m_filterPattern;
    QString m_searchPattern;
    QHash<QString, QString> m_fileIdCache;
    
    void initialize();
    void sort();
    bool matchesFilter(const QString &fileName) const;
};

#endif // FILELISTMODEL_H
