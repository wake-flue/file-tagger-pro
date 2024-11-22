#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QString>

class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    static DatabaseManager& instance();
    
    bool initialize();
    bool isInitialized() const { return m_initialized; }
    
    // 数据库版本管理
    int currentVersion() const;
    bool upgradeDatabase(int fromVersion, int toVersion);
    
    // 获取数据库连接
    QSqlDatabase database() const { return m_db; }

private:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();
    
    // 禁用拷贝
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;

    bool createTables();
    bool createTagsTable();
    bool createFileTagsTable();
    bool createSettingsTable();
    
    // 数据库升级相关
    bool applyMigration(int version);
    
    QSqlDatabase m_db;
    bool m_initialized;
    static const int CURRENT_DB_VERSION = 1;
};

#endif // DATABASEMANAGER_H 