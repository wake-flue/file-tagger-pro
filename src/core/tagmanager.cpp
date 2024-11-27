#include "tagmanager.h"
#include "databasemanager.h"

// Qt Core
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>

// Qt SQL
#include <QSqlQuery>
#include <QSqlError>

// Qt Gui
#include <QColor>

// Windows API
#ifdef Q_OS_WIN
#include <windows.h>
#endif

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
        emit tagError(QString("系统|标签|加载失败|%1").arg(query.lastError().text()));
    }
    
    m_cacheInitialized = true;
}

bool TagManager::addTag(const QString &name, const QColor &color, const QString &description)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("INSERT INTO tags (name, color, description, created_at, updated_at) VALUES (?, ?, ?, ?, ?)");
    
    query.addBindValue(name);
    query.addBindValue(color.name(QColor::HexRgb));
    query.addBindValue(description);
    QDateTime now = QDateTime::currentDateTime();
    query.addBindValue(now);
    query.addBindValue(now);
    
    if (!query.exec()) {
        emit tagError(QString("系统|标签|添加失败|%1").arg(query.lastError().text()));
        return false;
    }
    
    int newTagId = query.lastInsertId().toInt();
    
    auto tag = QSharedPointer<Tag>::create();
    tag->setId(newTagId);
    tag->setName(name);
    tag->setColor(color);
    tag->setDescription(description);
    tag->setCreatedAt(now);
    tag->setUpdatedAt(now);
    
    m_tagsCache.insert(newTagId, tag);
    
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
        emit tagError(QString("系统|标签|删除失败|%1").arg(query.lastError().text()));
        return false;
    }
    
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
        emit tagError(QString("系统|标签|更新失败|%1").arg(query.lastError().text()));
        return false;
    }
    
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

bool TagManager::addFileTag(const QString &fileId, int tagId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("INSERT OR IGNORE INTO file_tags (file_id, tag_id) VALUES (?, ?)");
    query.addBindValue(fileId);
    query.addBindValue(tagId);
    
    if (!query.exec()) {
        emit tagError(QString("系统|标签|添加文件标签失败|%1").arg(query.lastError().text()));
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
        emit tagError(QString("系统|标签|移除文件标签失败|%1").arg(query.lastError().text()));
        return false;
    }
    
    emit fileTagsChanged(fileId);
    return true;
}

bool TagManager::clearFileTags(const QString &fileId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("DELETE FROM file_tags WHERE file_id = ?");
    query.addBindValue(fileId);
    
    if (!query.exec()) {
        emit tagError(QString("系统|标签|清除文件标签失败|%1").arg(query.lastError().text()));
        return false;
    }
    
    emit fileTagsChanged(fileId);
    return true;
}

bool TagManager::addTagToFileById(const QString &fileId, int tagId)
{
    if (fileId.isEmpty()) {
        emit tagError("系统|标签|添加失败|文件ID为空");
        return false;
    }
    
    if (tagId <= 0) {
        emit tagError(QString("系统|标签|添加失败|无效的标签ID: %1").arg(tagId));
        return false;
    }
    
    if (!m_tagsCache.contains(tagId)) {
        emit tagError(QString("系统|标签|添加失败|标签不存在: %1").arg(tagId));
        return false;
    }
    
    return addFileTag(fileId, tagId);
}

bool TagManager::deleteTag(int tagId)
{
    if (tagId <= 0) {
        emit tagError("系统|标签|删除失败|无效的标签ID");
        return false;
    }
    
    DatabaseManager& db = DatabaseManager::instance();
    
    if (!db.execute("DELETE FROM file_tags WHERE tag_id = ?", {tagId})) {
        emit tagError("系统|标签|删除失败|无法删除标签关联");
        return false;
    }
    
    if (!db.execute("DELETE FROM tags WHERE id = ?", {tagId})) {
        emit tagError("系统|标签|删除失败|无法删除标签");
        return false;
    }
    
    if (m_tagsCache.contains(tagId)) {
        m_tagsCache.remove(tagId);
    }
    
    emit tagDeleted(tagId);
    emit tagRemoved(tagId);
    emit tagsChanged();
    
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

bool TagManager::removeTagFromFileById(const QString &fileId, int tagId)
{
    if (fileId.isEmpty()) {
        emit tagError("系统|标签|移除失败|文件ID为空");
        return false;
    }
    
    if (tagId <= 0) {
        emit tagError(QString("系统|标签|移除失败|无效的标签ID: %1").arg(tagId));
        return false;
    }
    
    if (!m_tagsCache.contains(tagId)) {
        emit tagError(QString("系统|标签|移除失败|标签不存在: %1").arg(tagId));
        return false;
    }
    
    return removeFileTag(fileId, tagId);
}
  