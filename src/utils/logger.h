#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QFile>
#include <QDateTime>
#include <QVariantMap>
#include <QRegularExpression>

class Logger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList messages READ messages NOTIFY messagesChanged)
    Q_PROPERTY(int logLevel READ logLevel WRITE setLogLevel NOTIFY logLevelChanged)
    Q_PROPERTY(QString logFilePath READ logFilePath WRITE setLogFilePath NOTIFY logFilePathChanged)
    Q_PROPERTY(QStringList fileMessages READ fileMessages NOTIFY fileMessagesChanged)
    Q_PROPERTY(QString searchPattern READ searchPattern WRITE setSearchPattern NOTIFY searchPatternChanged)
    Q_PROPERTY(QVariantMap logStats READ logStats NOTIFY logStatsChanged)
    Q_PROPERTY(QString lastMessage READ lastMessage NOTIFY lastMessageChanged)
    
public:
    enum LogLevel {
        Debug = 0,
        Info = 1,
        Warning = 2,
        Error = 3,
        Fatal = 4
    };
    Q_ENUM(LogLevel)
    
    explicit Logger(QObject *parent = nullptr);
    ~Logger();
    
    QStringList messages() const;
    QStringList fileMessages() const { return m_fileMessages; }
    int logLevel() const { return m_logLevel; }
    void setLogLevel(int level);
    
    QString logFilePath() const { return m_logFilePath; }
    void setLogFilePath(const QString &path);
    
    // 日志文件设置
    Q_INVOKABLE void setLogFileMaxSize(qint64 bytes);  // 设置单个日志文件最大大小
    Q_INVOKABLE void setMaxLogFiles(int count);        // 设置最大日志文件数量
    Q_INVOKABLE QStringList getLogFiles() const;       // 获取所有日志文件列表
    Q_INVOKABLE QString getCurrentLogFile() const;      // 获取当前日志文件路径
    Q_INVOKABLE void clearLogFiles();                  // 清除所有日志文件
    
    // 日志方法
    Q_INVOKABLE void debug(const QString &message);
    Q_INVOKABLE void info(const QString &message);
    Q_INVOKABLE void warning(const QString &message);
    Q_INVOKABLE void error(const QString &message);
    Q_INVOKABLE void fatal(const QString &message);
    
    void clear();

    // 日志文件读取方法
    Q_INVOKABLE
    Q_INVOKABLE QStringList readLogFileFiltered(int level, int maxLines = 1000) const;
    
    QString searchPattern() const { return m_searchPattern; }
    void setSearchPattern(const QString &pattern);
    QVariantMap logStats() const;
    
    Q_INVOKABLE QStringList searchLogs(const QString &pattern, int maxResults = 1000) const;

    QString lastMessage() const { return m_lastMessage; }
    
    // 日志路径管理
    static QString getLogBasePath();
    static QString getModuleLogPath(const QString &moduleName);
    static void ensureLogDirectories();
    
    // 日志类型
    enum LogType {
        General,    // 通用日志
        Database,   // 数据库日志
        FileSystem, // 文件系统日志
        Network,    // 网络日志
        UI         // 界面日志
    };
    Q_ENUM(LogType)
    
    static QString getLogTypeString(LogType type);
    static QString getLogFilePath(LogType type);
    
signals:
    void messagesChanged();
    void logLevelChanged();
    void logFilePathChanged();
    void logFileRotated(const QString &newFile);
    void fileMessagesChanged();
    void searchPatternChanged();
    void logStatsChanged();
    void lastMessageChanged();

private:
    struct LogMessage {
        LogLevel level;
        QString timestamp;
        QString message;
        QString formatted() const;
    };
    
    void addMessage(LogLevel level, const QString &message);
    void writeToFile(const QString &message);
    void rotateLogFiles();
    void initializeLogFile();
    void updateFileMessages();
    void updateLogStats();
    
    QList<LogMessage> m_messages;
    int m_logLevel;
    QString m_logFilePath;
    QFile m_logFile;
    qint64 m_maxFileSize;
    int m_maxLogFiles;
    static const int MAX_MESSAGES = 100;
    static const qint64 DEFAULT_MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
    static const int DEFAULT_MAX_LOG_FILES = 5;
    QStringList m_fileMessages;
    QString m_searchPattern;
    QString m_lastMessage;
    
    // 日志文件扩展名
    static const QString LOG_FILE_EXTENSION;
};

#endif // LOGGER_H
