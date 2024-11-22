#include "databasemanager.h"
#include <QStandardPaths>
#include <QDir>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
    , m_initialized(false)
{
}

DatabaseManager& DatabaseManager::instance()
{
    static DatabaseManager instance;
    return instance;
}

bool DatabaseManager::initialize()
{
    if (m_initialized) {
        return true;
    }

    // 确保数据目录存在
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    // 初始化数据库连接
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dataPath + "/filetags.db");

    if (!m_db.open()) {
        qWarning() << "无法打开数据库:" << m_db.lastError().text();
        return false;
    }

    // 启用外键约束
    QSqlQuery query(m_db);
    query.exec("PRAGMA foreign_keys = ON");

    // 创建表结构
    if (!createTables()) {
        qWarning() << "创建数据库表失败";
        return false;
    }

    // 创建索引以提高性能
    query.exec("CREATE INDEX IF NOT EXISTS idx_file_tags_file_id ON file_tags(file_id)");
    query.exec("CREATE INDEX IF NOT EXISTS idx_file_tags_tag_id ON file_tags(tag_id)");

    // 检查并执行数据库升级
    int dbVersion = currentVersion();
    if (dbVersion < CURRENT_DB_VERSION) {
        if (!upgradeDatabase(dbVersion, CURRENT_DB_VERSION)) {
            qWarning() << "数据库升级失败";
            return false;
        }
    }

    m_initialized = true;
    return true;
}

bool DatabaseManager::createTables()
{
    return createSettingsTable() &&
           createTagsTable() &&
           createFileTagsTable();
}

bool DatabaseManager::createSettingsTable()
{
    QSqlQuery query;
    return query.exec(
        "CREATE TABLE IF NOT EXISTS settings ("
        "    key TEXT PRIMARY KEY,"
        "    value TEXT,"
        "    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")"
    );
}

bool DatabaseManager::createTagsTable()
{
    QSqlQuery query;
    return query.exec(
        "CREATE TABLE IF NOT EXISTS tags ("
        "    id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    name TEXT NOT NULL UNIQUE,"
        "    color TEXT,"
        "    description TEXT,"
        "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")"
    );
}

bool DatabaseManager::createFileTagsTable()
{
    QSqlQuery query;
    return query.exec(
        "CREATE TABLE IF NOT EXISTS file_tags ("
        "    file_id TEXT NOT NULL,"  // 文件的唯一标识符
        "    tag_id INTEGER NOT NULL,"
        "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "    PRIMARY KEY (file_id, tag_id),"
        "    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE"
        ")"
    );
}

int DatabaseManager::currentVersion() const
{
    QSqlQuery query;
    query.prepare("SELECT value FROM settings WHERE key = 'schema_version'");
    if (query.exec() && query.next()) {
        return query.value(0).toInt();
    }
    return 0;
}

bool DatabaseManager::upgradeDatabase(int fromVersion, int toVersion)
{
    m_db.transaction();

    for (int version = fromVersion + 1; version <= toVersion; ++version) {
        if (!applyMigration(version)) {
            m_db.rollback();
            return false;
        }
    }

    // 更新数据库版本
    QSqlQuery query;
    query.prepare("INSERT OR REPLACE INTO settings (key, value) VALUES ('schema_version', :version)");
    query.bindValue(":version", toVersion);
    
    if (!query.exec()) {
        m_db.rollback();
        return false;
    }

    return m_db.commit();
}

bool DatabaseManager::applyMigration(int version)
{
    QSqlQuery query;
    
    switch (version) {
        case 1:
            return true;
            
        case 2:
            // 创建临时表
            if (!query.exec("CREATE TABLE file_tags_temp ("
                          "file_id TEXT NOT NULL,"
                          "tag_id INTEGER NOT NULL,"
                          "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
                          "PRIMARY KEY (file_id, tag_id),"
                          "FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE)")) {
                return false;
            }
            
            // 复制数据
            if (!query.exec("INSERT INTO file_tags_temp (file_id, tag_id, created_at) "
                          "SELECT file_id, tag_id, created_at FROM file_tags")) {
                return false;
            }
            
            // 删除旧表
            if (!query.exec("DROP TABLE file_tags")) {
                return false;
            }
            
            // 重命名新表
            if (!query.exec("ALTER TABLE file_tags_temp RENAME TO file_tags")) {
                return false;
            }
            
            // 重新创建索引
            if (!query.exec("CREATE INDEX idx_file_tags_file_id ON file_tags(file_id)")) {
                return false;
            }
            if (!query.exec("CREATE INDEX idx_file_tags_tag_id ON file_tags(tag_id)")) {
                return false;
            }
            
            return true;
            
        default:
            qWarning() << "未知的数据库版本:" << version;
            return false;
    }
}

bool DatabaseManager::execute(const QString& query, const QVariantList& params)
{
    QSqlQuery sqlQuery(m_db);
    
    if (!sqlQuery.prepare(query)) {
        qWarning() << "Failed to prepare query:" << query;
        qWarning() << "Error:" << sqlQuery.lastError().text();
        return false;
    }
    
    // 绑定参数
    for (const QVariant& param : params) {
        sqlQuery.addBindValue(param);
    }
    
    if (!sqlQuery.exec()) {
        qWarning() << "Failed to execute query:" << query;
        qWarning() << "Error:" << sqlQuery.lastError().text();
        return false;
    }
    
    return true;
}

DatabaseManager::~DatabaseManager()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
} 