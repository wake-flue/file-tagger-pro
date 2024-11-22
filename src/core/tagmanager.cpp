#include "tagmanager.h"
#include "databasemanager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QDateTime>

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
    
    qDebug() << "数据库路径:" << db.databaseName();
    
    if (query.exec("SELECT id, name, color, description, created_at, updated_at FROM tags")) {
        qDebug() << "当前标签列表:";
        while (query.next()) {
            int id = query.value(0).toInt();
            QString name = query.value(1).toString();
            QString color = query.value(2).toString();
            QString desc = query.value(3).toString();
            qDebug() << "  标签:" << id << name << color << desc;
            
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
        qDebug() << "查询标签失败:" << query.lastError().text();
    }
    
    m_cacheInitialized = true;
}

bool TagManager::addTag(const QString &name, const QColor &color, const QString &description)
{
    try {
        QSqlDatabase db = DatabaseManager::instance().database();
        QSqlQuery query(db);
        
        db.transaction();
        
        query.prepare("INSERT INTO tags (name, color, description) VALUES (?, ?, ?)");
        query.addBindValue(name);
        query.addBindValue(color.name(QColor::HexRgb));
        query.addBindValue(description);
        
        if (!query.exec()) {
            db.rollback();
            emit tagError(query.lastError().text());
            return false;
        }
        
        db.commit();
        emit tagsChanged();
        return true;
    } catch (const std::exception &e) {
        emit tagError(QString("添加标签时发生错误: %1").arg(e.what()));
        return false;
    }
}

bool TagManager::removeTag(int tagId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("DELETE FROM tags WHERE id = :id");
    query.bindValue(":id", tagId);
    
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
    
    query.prepare("UPDATE tags SET name = :name, color = :color, description = :description, "
                 "updated_at = CURRENT_TIMESTAMP WHERE id = :id");
    query.bindValue(":name", name);
    query.bindValue(":color", color.name());
    query.bindValue(":description", description);
    query.bindValue(":id", tagId);
    
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
bool TagManager::addTagToFile(const QString &filePath, int tagId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("INSERT OR IGNORE INTO file_tags (file_path, tag_id) VALUES (:path, :tag_id)");
    query.bindValue(":path", filePath);
    query.bindValue(":tag_id", tagId);
    
    if (!query.exec()) {
        qWarning() << "添加文件标签失败:" << query.lastError().text();
        return false;
    }
    
    emit fileTagsChanged(filePath);
    return true;
}

bool TagManager::removeTagFromFile(const QString &filePath, int tagId)
{
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("DELETE FROM file_tags WHERE file_path = :path AND tag_id = :tag_id");
    query.bindValue(":path", filePath);
    query.bindValue(":tag_id", tagId);
    
    if (!query.exec()) {
        qWarning() << "移除文件标签失败:" << query.lastError().text();
        return false;
    }
    
    emit fileTagsChanged(filePath);
    return true;
}

QVector<Tag*> TagManager::getFileTags(const QString &filePath)
{
    loadTagsCache();
    
    QVector<Tag*> tags;
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("SELECT tag_id FROM file_tags WHERE file_path = :path");
    query.bindValue(":path", filePath);
    
    if (query.exec()) {
        while (query.next()) {
            int tagId = query.value(0).toInt();
            if (m_tagsCache.contains(tagId)) {
                tags.append(m_tagsCache[tagId].data());
            }
        }
    }
    
    return tags;
}

QVector<QString> TagManager::getFilesByTag(int tagId)
{
    QVector<QString> files;
    QSqlDatabase db = DatabaseManager::instance().database();
    QSqlQuery query(db);
    
    query.prepare("SELECT file_path FROM file_tags WHERE tag_id = :tag_id");
    query.bindValue(":tag_id", tagId);
    
    if (query.exec()) {
        while (query.next()) {
            files.append(query.value(0).toString());
        }
    }
    
    return files;
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
        "SELECT t.name, COUNT(ft.file_path) as count "
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
        "SELECT DISTINCT file_path "
        "FROM file_tags "
        "ORDER BY created_at DESC "
        "LIMIT :limit"
    );
    query.bindValue(":limit", limit);
    
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