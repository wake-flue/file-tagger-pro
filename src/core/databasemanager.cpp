#include "databasemanager.h"

// Qt Core
#include <QStandardPaths>
#include <QDir>
#include <QDebug>
#include <QDateTime>

// Qt SQL
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlDatabase>

// Project includes
#include "../utils/logger.h"

DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
    , m_initialized(false)
    , m_logger(new Logger(this))
{
    m_logger->setLogFilePath(Logger::getLogFilePath(Logger::Database));
    m_logger->setLogLevel(Logger::Info);
    m_logger->info("数据库管理器初始化开始");
}

DatabaseManager& DatabaseManager::instance()
{
    static DatabaseManager instance;
    return instance;
}

bool DatabaseManager::initialize()
{
    if (m_initialized) {
        m_logger->debug("数据库管理器已经初始化");
        return true;
    }

    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(dataPath);
    if (!dir.exists()) {
        dir.mkpath(".");
    }

    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dataPath + "/filetags.db");

    if (!m_db.open()) {
        m_logger->error(QString("数据库连接失败: %1").arg(m_db.lastError().text()));
        return false;
    }

    // 启用外键约束
    QSqlQuery query(m_db);
    query.exec("PRAGMA foreign_keys = ON");

    // 创建表结构
    if (!createTables()) {
        m_logger->error("数据库表创建失败");
        return false;
    }

    // 检查并执行数据库升级
    int dbVersion = currentVersion();
    if (dbVersion < CURRENT_DB_VERSION) {
        m_logger->info(QString("数据库开始升级: 从 v%1 到 v%2").arg(dbVersion).arg(CURRENT_DB_VERSION));
        if (!upgradeDatabase(dbVersion, CURRENT_DB_VERSION)) {
            m_logger->error("数据库升级失败");
            return false;
        }
        m_logger->info("数据库升级完成");
    }

    m_initialized = true;
    m_logger->info("数据库管理器初始化完成");
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
    bool success = query.exec(
        "CREATE TABLE IF NOT EXISTS settings ("
        "    key TEXT PRIMARY KEY,"
        "    value TEXT,"
        "    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")"
    );
    
    if (!success) {
        m_logger->error(QString("创建settings表失败: %1").arg(query.lastError().text()));
    } else {
        m_logger->debug("创建settings表成功");
    }
    return success;
}

bool DatabaseManager::createTagsTable()
{
    QSqlQuery query;
    bool success = query.exec(
        "CREATE TABLE IF NOT EXISTS tags ("
        "    id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "    name TEXT NOT NULL UNIQUE,"
        "    color TEXT,"
        "    description TEXT,"
        "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
        ")"
    );
    
    if (!success) {
        m_logger->error(QString("创建tags表失败: %1").arg(query.lastError().text()));
    } else {
        m_logger->debug("创建tags表成功");
    }
    return success;
}

bool DatabaseManager::createFileTagsTable()
{
    QSqlQuery query;
    bool success = query.exec(
        "CREATE TABLE IF NOT EXISTS file_tags ("
        "    file_id TEXT NOT NULL,"
        "    tag_id INTEGER NOT NULL,"
        "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
        "    PRIMARY KEY (file_id, tag_id),"
        "    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE"
        ")"
    );
    
    if (!success) {
        m_logger->error(QString("创建file_tags表失败: %1").arg(query.lastError().text()));
    } else {
        m_logger->debug("创建file_tags表成功");
    }
    return success;
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
        m_logger->info(QString("[DatabaseManager] 正在应用数据库迁移: 版本 %1").arg(version));
        if (!applyMigration(version)) {
            m_logger->error(QString("[DatabaseManager] 数据库迁移失败: 版本 %1").arg(version));
            m_db.rollback();
            return false;
        }
    }

    // 更新数据库版本
    QSqlQuery query;
    query.prepare("INSERT OR REPLACE INTO settings (key, value) VALUES ('schema_version', :version)");
    query.bindValue(":version", toVersion);
    
    if (!query.exec()) {
        m_logger->error(QString("[DatabaseManager] 更新数据库版本失败: %1").arg(query.lastError().text()));
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
                m_logger->error(QString("[DatabaseManager] 创建临时表失败: %1").arg(query.lastError().text()));
                return false;
            }
            
            // 复制数据
            if (!query.exec("INSERT INTO file_tags_temp (file_id, tag_id, created_at) "
                          "SELECT file_id, tag_id, created_at FROM file_tags")) {
                m_logger->error(QString("[DatabaseManager] 复制数据失败: %1").arg(query.lastError().text()));
                return false;
            }
            
            // 删除旧表
            if (!query.exec("DROP TABLE file_tags")) {
                m_logger->error(QString("[DatabaseManager] 删除旧表失败: %1").arg(query.lastError().text()));
                return false;
            }
            
            // 重命名新表
            if (!query.exec("ALTER TABLE file_tags_temp RENAME TO file_tags")) {
                m_logger->error(QString("[DatabaseManager] 重命名表失败: %1").arg(query.lastError().text()));
                return false;
            }
            
            // 重新创建索引
            if (!query.exec("CREATE INDEX idx_file_tags_file_id ON file_tags(file_id)")) {
                m_logger->error(QString("[DatabaseManager] 创建file_id索引失败: %1").arg(query.lastError().text()));
                return false;
            }
            if (!query.exec("CREATE INDEX idx_file_tags_tag_id ON file_tags(tag_id)")) {
                m_logger->error(QString("[DatabaseManager] 创建tag_id索引失败: %1").arg(query.lastError().text()));
                return false;
            }
            
            return true;
            
        default:
            m_logger->error(QString("[DatabaseManager] 未知的数据库版本: %1").arg(version));
            return false;
    }
}

bool DatabaseManager::execute(const QString& query, const QVariantList& params)
{
    QSqlQuery sqlQuery(m_db);
    
    if (!sqlQuery.prepare(query)) {
        m_logger->error(QString("系统|数据库|SQL准备失败|%1|%2").arg(sqlQuery.lastError().text(), query));
        return false;
    }
    
    for (const QVariant& param : params) {
        sqlQuery.addBindValue(param);
    }
    
    if (!sqlQuery.exec()) {
        m_logger->error(QString("系统|数据库|SQL执行失败|%1|%2").arg(sqlQuery.lastError().text(), query));
        return false;
    }
    
    return true;
}

DatabaseManager::~DatabaseManager()
{
    if (m_db.isOpen()) {
        m_db.close();
        m_logger->info("系统|数据库|连接关闭");
    }
} 