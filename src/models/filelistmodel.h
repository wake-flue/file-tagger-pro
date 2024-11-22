#ifndef FILELISTMODEL_H
#define FILELISTMODEL_H

#include <QAbstractListModel>
#include <QColor>  // 添加 QColor 头文件
#include <QSharedPointer>  // 添加 QSharedPointer 头文件
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
        ListView,       // 列表视图
        LargeIconView  // 大图标视图
    };
    Q_ENUM(ViewMode)  // 使枚举可在QML中使用

    // 添加数据角色枚举
    enum Roles {
        FileNameRole = Qt::UserRole + 1,
        FileSizeRole,
        FileTypeRole,
        FilePathRole,
        DisplaySizeRole,
        DisplayDateRole,
        IndexRole,
        PreviewPathRole,      // 添加预览路径角色
        PreviewLoadingRole    // 添加预览加载状态角色
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
    void setViewMode(ViewMode mode);

    // 添加获取完整FileData的方法
    Q_INVOKABLE FileData* getFileData(int index) const;

    SortRole sortRole() const { return m_sortRole; }
    void setSortRole(SortRole role);
    
    Qt::SortOrder sortOrder() const { return m_sortOrder; }
    void setSortOrder(Qt::SortOrder order);

    QString filterPattern() const { return m_filterPattern; }
    void setFilterPattern(const QString &pattern);

    QString searchPattern() const { return m_searchPattern; }
    void setSearchPattern(const QString &pattern);

    // 添加新的函数声明
    void updateFiles(const QVector<QSharedPointer<FileData>>& newFiles);

protected:
    QString formatFileSize(qint64 size) const;  // 添加这行
    QVariant defaultValue(int role) const;      // 添加这行
    void applyFilters();                        // 添加这行

public slots:
    void setFiles(const QVector<QSharedPointer<FileData>> &files);
    void clear();
    void clearPreviews();  // 添加清除预览的方法声明

signals:
    void countChanged();
    void viewModeChanged();
    void sortRoleChanged();
    void sortOrderChanged();
    void filterPatternChanged();
    void searchPatternChanged();
    void needGeneratePreviews();  // 添加这个信号声明

private:
    QVector<QSharedPointer<FileData>> m_files;  // 使用QSharedPointer替代直接存储
    ViewMode m_viewMode = ListView;  // 默认使用列表视图
    SortRole m_sortRole = SortByName;
    Qt::SortOrder m_sortOrder = Qt::AscendingOrder;
    void sort();
    QString m_filterPattern;
    bool matchesFilter(const QString &fileName) const;
    QString m_searchPattern;
    QVector<QSharedPointer<FileData>> m_allFiles;  // 存储所有文件
    QVector<QSharedPointer<FileData>> m_filteredFiles;  // 存储筛选后的文件
    void initialize();  // 添加这行
};

#endif // FILELISTMODEL_H
