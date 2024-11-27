#include "tagmanager.h"
#include "databasemanager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QDateTime>
#include <QCryptographicHash>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <windows.h>

TagManager::TagManager(QObject *parent)
    : QObject(parent)
    , m_cacheInitialized(false)
{
}

TagManager& TagManager::instance()
{
    static TagManager instance;
    return instance;
}

void TagManager::loadTagsCache()
{
    if (m_cacheInitialized) {
        return;
    }

    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    if (query.exec("SELECT id, name, color, description, created_at, updated_at FROM tags")) {
        while (query.next()) {
            int id = query.value(0).toInt();
            QString name = query.value(1).toString();
            QString color = query.value(2).toString();
            QString desc = query.value(3).toString();

            auto tag = QSharedPointer<Tag>::create();
            tag->setId(query.value(0).toInt());
            tag->setName(query.value(1).toString());
            tag->setColor(QColor(query.value(2).toString()));
            tag->setDescription(query.value(3).toString());
            tag->setCreatedAt(query.value(4).toDateTime());
            tag->setUpdatedAt(query.value(5).toDateTime());
            
            m_tagsCache.insert(tag->id(), tag);
        }
    } else {
        qWarning() << "查询标签失败:" << query.lastError().text();
    }
    
    m_cacheInitialized = true;
}

bool TagManager::addTag(const QString &name, const QColor &color, const QString &description)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    // 准备SQL语句
    query.prepare("INSERT INTO tags (name, color, description, created_at, updated_at) VALUES (?, ?, ?, ?, ?)");
    
    // 绑定参数
    query.addBindValue(name);
    query.addBindValue(color.name(QColor::HexRgb));
    query.addBindValue(description);
    QDateTime now = QDateTime::currentDateTime();
    query.addBindValue(now);
    query.addBindValue(now);
    
    // 执行SQL
    if (!query.exec()) {
        qWarning() << "添加标签失败:" << query.lastError().text();
        emit tagError(QString("添加标签失败: %1").arg(query.lastError().text()));
        return false;
    }
    
    // 获取新插入的标签ID
    int newTagId = query.lastInsertId().toInt();
    
    // 创建新的Tag对象并添加到缓存
    auto tag = QSharedPointer<Tag>::create();
    tag->setId(newTagId);
    tag->setName(name);
    tag->setColor(color);
    tag->setDescription(description);
    tag->setCreatedAt(now);
    tag->setUpdatedAt(now);
    
    m_tagsCache.insert(newTagId, tag);
    
    // 发出信号通知标签列表已更新
    emit tagAdded(tag.data());
    emit tagsChanged();
    
    return true;
}

bool TagManager::removeTag(int tagId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("DELETE FROM tags WHERE id = ?");
    query.addBindValue(tagId);
    
    if (!query.exec()) {
        qWarning() << "删除标签失败:" << query.lastError().text();
        return false;
    }
    
    // 更新缓存
    m_tagsCache.remove(tagId);
    
    emit tagRemoved(tagId);
    return true;
}

bool TagManager::updateTag(int tagId, const QString &name, const QColor &color, const QString &description)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("UPDATE tags SET name = ?, color = ?, description = ?, "
                 "updated_at = CURRENT_TIMESTAMP WHERE id = ?");
    query.addBindValue(name);
    query.addBindValue(color.name());
    query.addBindValue(description);
    query.addBindValue(tagId);
    
    if (!query.exec()) {
        qWarning() << "更新标签失败:" << query.lastError().text();
        return false;
    }
    
    // 更新缓存
    if (m_tagsCache.contains(tagId)) {
        auto tag = m_tagsCache[tagId];
        tag->setName(name);
        tag->setColor(color);
        tag->setDescription(description);
        tag->setUpdatedAt(QDateTime::currentDateTime());
        
        emit tagUpdated(tag.data());
    }
    
    return true;
}

// 文件标签操作
bool TagManager::addFileTag(const QString &fileId, int tagId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("INSERT OR IGNORE INTO file_tags (file_id, tag_id) VALUES (?, ?)");
    query.addBindValue(fileId);
    query.addBindValue(tagId);
    
    if (!query.exec()) {
        qWarning() << "添加文件标签失败:" << query.lastError().text();
        return false;
    }
    
    emit fileTagsChanged(fileId);
    return true;
}

bool TagManager::removeFileTag(const QString &fileId, int tagId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("DELETE FROM file_tags WHERE file_id = ? AND tag_id = ?");
    query.addBindValue(fileId);
    query.addBindValue(tagId);
    
    if (!query.exec()) {
        qWarning() << "移除文件标签失败:" << query.lastError().text();
        return false;
    }
    
    emit fileTagsChanged(fileId);
    return true;
}

QList<Tag*> TagManager::getFileTags(const QString &fileId)
{
    QList<Tag*> tags;
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("SELECT t.* FROM tags t "
                 "INNER JOIN file_tags ft ON ft.tag_id = t.id "
                 "WHERE ft.file_id = ?");
    query.addBindValue(fileId);
    
    if (!query.exec()) {
        qWarning() << "获取文件标签失败:" << query.lastError().text();
        return tags;
    }
    
    while (query.next()) {
        auto tag = new Tag(this);
        tag->setId(query.value("id").toInt());
        tag->setName(query.value("name").toString());
        tag->setColor(query.value("color").toString());
        tag->setDescription(query.value("description").toString());
        tags.append(tag);
    }
    
    return tags;
}

QStringList TagManager::getFilesByTag(int tagId)
{
    QStringList fileIds;
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("SELECT DISTINCT file_id FROM file_tags "
                 "WHERE tag_id = ?");
    query.addBindValue(tagId);
    
    if (!query.exec()) {
        qWarning() << "获取标签文件失败:" << query.lastError().text();
        return fileIds;
    }
    
    while (query.next()) {
        fileIds.append(query.value("file_id").toString());
    }
    
    return fileIds;
}

bool TagManager::clearFileTags(const QString &fileId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("DELETE FROM file_tags WHERE file_id = ?");
    query.addBindValue(fileId);
    
    if (!query.exec()) {
        qWarning() << "清除文件标签失败:" << query.lastError().text();
        return false;
    }
    
    emit fileTagsChanged(fileId);
    return true;
}

QVector<Tag*> TagManager::getAllTags()
{
    loadTagsCache();
    QVector<Tag*> tags;
    for (const auto &tag : m_tagsCache) {
        tags.append(tag.data());
    }
    return tags;
}

Tag* TagManager::getTagById(int tagId)
{
    loadTagsCache();
    return m_tagsCache.value(tagId).data();
}

Tag* TagManager::getTagByName(const QString &name)
{
    loadTagsCache();
    for (const auto &tag : m_tagsCache) {
        if (tag->name() == name) {
            return tag.data();
        }
    }
    return nullptr;
}

QList<QPair<QString, int>> TagManager::getTagStats()
{
    QList<QPair<QString, int>> stats;
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare(
        "SELECT t.name, COUNT(ft.file_id) as count "
        "FROM tags t "
        "LEFT JOIN file_tags ft ON t.id = ft.tag_id "
        "GROUP BY t.id, t.name "
        "ORDER BY count DESC"
    );
    
    if (query.exec()) {
        while (query.next()) {
            stats.append({
                query.value(0).toString(),
                query.value(1).toInt()
            });
        }
    }
    
    return stats;
}

QStringList TagManager::getRecentFiles(int limit)
{
    QStringList files;
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare(
        "SELECT DISTINCT file_id "
        "FROM file_tags "
        "ORDER BY created_at DESC "
        "LIMIT ?"
    );
    query.addBindValue(limit);
    
    if (query.exec()) {
        while (query.next()) {
            files.append(query.value(0).toString());
        }
    }
    
    return files;
}

TagManager::~TagManager()
{
    clearCache();
}

void TagManager::clearCache()
{
    m_tagsCache.clear();
    m_cacheInitialized = false;
}

bool TagManager::isTagNameExists(const QString &name) const {
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("SELECT COUNT(*) FROM tags WHERE name = ?");
    query.addBindValue(name);
    
    if (query.exec() && query.next()) {
        return query.value(0).toInt() > 0;
    }
    return false;
}

bool TagManager::deleteTag(int tagId)
{
    if (tagId <= 0) {
        qWarning() << "Invalid tag ID:" << tagId;
        emit tagError("无效的标签ID");
        return false;
    }
    
    DatabaseManager& db = DatabaseManager::instance();
    
    // 首先删除标签与文件的关联
    if (!db.execute("DELETE FROM file_tags WHERE tag_id = ?", {tagId})) {
        qWarning() << "Failed to delete tag associations";
        emit tagError("删除标签关联失败");
        return false;
    }
    
    // 然后删除标签本身
    if (!db.execute("DELETE FROM tags WHERE id = ?", {tagId})) {
        qWarning() << "Failed to delete tag";
        emit tagError("删除标签失败");
        return false;
    }
    
    // 从缓存移除
    if (m_tagsCache.contains(tagId)) {
        m_tagsCache.remove(tagId);
    }
    
    emit tagDeleted(tagId);
    emit tagRemoved(tagId);  // 为了向后兼容
    emit tagsChanged();      // 通知所有监听者标签列表已更新
    
    return true;
}

bool TagManager::addTagToFileById(const QString &fileId, int tagId)
{
    if (fileId.isEmpty()) {
        qWarning() << "添加文件标签失败: fileId 为空";
        return false;
    }
    
    if (tagId <= 0) {
        qWarning() << "添加文件标签失败: 无效的 tagId:" << tagId;
        return false;
    }
    
    // 检查标签是否存在
    if (!m_tagsCache.contains(tagId)) {
        qWarning() << "添加文件标签失败: 标签不存在, tagId:" << tagId;
        return false;
    }
    
    return addFileTag(fileId, tagId);
}

bool TagManager::removeTagFromFileById(const QString &fileId, int tagId)
{
    return removeFileTag(fileId, tagId);
}

QVector<Tag*> TagManager::getFileTagsById(const QString &fileId)
{
    QVector<Tag*> tags;
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    // 确保标签缓存已加载
    loadTagsCache();
    
    query.prepare(
        "SELECT t.id FROM tags t "
        "INNER JOIN file_tags ft ON t.id = ft.tag_id "
        "WHERE ft.file_id = ?"
    );
    query.addBindValue(fileId);
    
    if (query.exec()) {
        while (query.next()) {
            int tagId = query.value("id").toInt();
            
            // 从缓存中获取标签对象
            if (m_tagsCache.contains(tagId)) {
                Tag* tag = m_tagsCache[tagId].data();
                tags.append(tag);
            }
        }
    } else {
        qWarning() << "Failed to execute query:" << query.lastError().text();
    }
    
    return tags;
}

QVector<QString> TagManager::getFilesByTagId(int tagId)
{
    // 直接复用现有的getFilesByTag函数
    return getFilesByTag(tagId);
}
  