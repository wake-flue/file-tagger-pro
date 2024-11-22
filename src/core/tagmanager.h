#ifndef TAGMANAGER_H
#define TAGMANAGER_H

#include <QObject>
#include <QVector>
#include <QHash>
#include <QSharedPointer>
#include "../models/tag.h"

#ifdef Q_OS_WIN
#include <windows.h>
#endif

class TagManager : public QObject
{
    Q_OBJECT

public:
    static TagManager& instance();
    
public slots:
    // 标签操作
    bool addTag(const QString &name, const QColor &color = Qt::blue, const QString &description = QString());
    bool removeTag(int tagId);
    bool updateTag(int tagId, const QString &name, const QColor &color, const QString &description);
    
    // 文件标签操作（只保留基于fileId的方法）
    QList<Tag*> getFileTags(const QString &fileId);
    QStringList getFilesByTag(int tagId);
    
    // 查询操作
    QVector<Tag*> getAllTags();
    Tag* getTagById(int tagId);
    Tag* getTagByName(const QString &name);
    
    // 数据库查询
    QList<QPair<QString, int>> getTagStats();  // 获取每个标签的使用次数
    QStringList getRecentFiles(int limit = 10);  // 获取最近标记的文件
    
    Q_INVOKABLE bool isTagNameExists(const QString &name) const;
    Q_INVOKABLE bool deleteTag(int tagId);
    
    // 基于fileId的标签操作方法
    Q_INVOKABLE bool addTagToFileById(const QString &fileId, int tagId);
    Q_INVOKABLE bool removeTagFromFileById(const QString &fileId, int tagId);
    Q_INVOKABLE QVector<Tag*> getFileTagsById(const QString &fileId);
    Q_INVOKABLE QVector<QString> getFilesByTagId(int tagId);
    
    // 基础文件标签操作
    bool addFileTag(const QString &fileId, int tagId);
    bool removeFileTag(const QString &fileId, int tagId);
    bool clearFileTags(const QString &fileId);

signals:
    void tagAdded(Tag* tag);
    void tagRemoved(int tagId);
    void tagUpdated(Tag* tag);
    void fileTagsChanged(const QString &fileId);
    void tagError(const QString &message);
    void tagsChanged();
    void tagDeleted(int tagId);

private:
    explicit TagManager(QObject *parent = nullptr);
    ~TagManager();
    
    // 禁用拷贝
    TagManager(const TagManager&) = delete;
    TagManager& operator=(const TagManager&) = delete;
    
    // 缓存相关
    void loadTagsCache();
    void clearCache();
    
    QHash<int, QSharedPointer<Tag>> m_tagsCache;
    bool m_cacheInitialized;
    
    bool ensureFileIdentifier(const QString &filePath);
    void migrateOldData(); // 数据迁移
};

#endif // TAGMANAGER_H 