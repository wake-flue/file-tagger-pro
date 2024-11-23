#include "logger.h"
#include <QDir>
#include <QFileInfo>
#include <QTextStream>
#include <QStandardPaths>

Logger::Logger(QObject *parent)
    : QObject(parent)
    , m_logLevel(Info)
    , m_maxFileSize(DEFAULT_MAX_FILE_SIZE)
    , m_maxLogFiles(DEFAULT_MAX_LOG_FILES)
{
    // 设置默认日志目录
    QString logDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/logs";
    QDir().mkpath(logDir);
    setLogFilePath(logDir + "/app.log");
}

Logger::~Logger()
{
    if (m_logFile.isOpen()) {
        m_logFile.close();
    }
}

void Logger::setLogFilePath(const QString &path)
{
    if (m_logFilePath != path) {
        m_logFilePath = path;
        initializeLogFile();
        emit logFilePathChanged();
    }
}

void Logger::initializeLogFile()
{
    if (m_logFile.isOpen()) {
        m_logFile.close();
    }

    QFileInfo fileInfo(m_logFilePath);
    QDir().mkpath(fileInfo.absolutePath());  // 确保目录存在

    m_logFile.setFileName(m_logFilePath);
    if (!m_logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        qWarning() << "无法打开日志文件:" << m_logFilePath << ", 错误:" << m_logFile.errorString();
        return;
    }
    
    qDebug() << "成功打开日志文件:" << m_logFilePath;
    updateFileMessages();  // 初始化后立即更新文件消息
}

void Logger::writeToFile(const QString &message)
{
    if (!m_logFile.isOpen()) {
        return;
    }

    // 检查文件大小是否超过限制
    if (m_logFile.size() + message.length() > m_maxFileSize) {
        rotateLogFiles();
    }

    QTextStream stream(&m_logFile);
    stream << message << Qt::endl;
    stream.flush();

    updateFileMessages();
}

void Logger::rotateLogFiles()
{
    m_logFile.close();

    // 获取当前日志文件列表
    QFileInfo logFileInfo(m_logFilePath);
    QString baseName = logFileInfo.baseName();
    QString suffix = logFileInfo.suffix();
    QDir logDir = logFileInfo.dir();

    // 删除最老的日志文件
    QStringList filters;
    filters << QString("%1.*.%2").arg(baseName, suffix);
    QFileInfoList files = logDir.entryInfoList(filters, QDir::Files, QDir::Time);
    
    while (files.size() >= m_maxLogFiles - 1) {
        QFile::remove(files.last().filePath());
        files.removeLast();
    }

    // 重命名现有的日志文件
    QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");
    QString rotatedFileName = QString("%1.%2.%3").arg(baseName, timestamp, suffix);
    QString rotatedFilePath = logDir.filePath(rotatedFileName);
    
    QFile::rename(m_logFilePath, rotatedFilePath);

    // 创建新的日志文件
    initializeLogFile();
    
    emit logFileRotated(m_logFilePath);
}

void Logger::addMessage(LogLevel level, const QString &message)
{
    if (level < m_logLevel) {
        return;
    }
    
    LogMessage logMsg;
    logMsg.level = level;
    logMsg.timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
    logMsg.message = message;
    
    // 添加到内存缓存
    m_messages.prepend(logMsg);
    while (m_messages.size() > MAX_MESSAGES) {
        m_messages.removeLast();
    }
    
    // 写入文件
    writeToFile(logMsg.formatted());
    
    // 更新最新消息
    m_lastMessage = message;
    emit lastMessageChanged();
    
    emit messagesChanged();
}

void Logger::setLogFileMaxSize(qint64 bytes)
{
    m_maxFileSize = bytes;
}

void Logger::setMaxLogFiles(int count)
{
    m_maxLogFiles = qBound(1, count, 100);  // 限制范围1-100
}

QStringList Logger::getLogFiles() const
{
    QFileInfo logFileInfo(m_logFilePath);
    if (!logFileInfo.exists()) {
        qWarning() << "日志文件不存在:" << m_logFilePath;
        return QStringList();
    }

    QString baseName = logFileInfo.baseName();
    QString suffix = logFileInfo.suffix();
    QDir logDir = logFileInfo.dir();

    QStringList filters;
    filters << QString("%1*.%2").arg(baseName, suffix);
    QStringList files = logDir.entryList(filters, QDir::Files, QDir::Time);
    
    qDebug() << "找到日志文件:" << files;
    return files;
}

QString Logger::getCurrentLogFile() const
{
    return m_logFilePath;
}

void Logger::clearLogFiles()
{
    // 关闭当前日志文件
    m_logFile.close();

    // 删除所有日志文件
    QFileInfo logFileInfo(m_logFilePath);
    QString baseName = logFileInfo.baseName();
    QString suffix = logFileInfo.suffix();
    QDir logDir = logFileInfo.dir();

    QStringList filters;
    filters << QString("%1*.%2").arg(baseName, suffix);
    QFileInfoList files = logDir.entryInfoList(filters, QDir::Files);
    
    for (const QFileInfo &file : files) {
        QFile::remove(file.filePath());
    }

    // 重新初始化日志文件
    initializeLogFile();
}

QString Logger::LogMessage::formatted() const
{
    static const QMap<LogLevel, QString> levelStrings = {
        {Debug, "[DEBUG]"},
        {Info, "[INFO]"},
        {Warning, "[WARN]"},
        {Error, "[ERROR]"},
        {Fatal, "[FATAL]"}
    };
    
    return QString("[%1] %2 %3")
        .arg(timestamp)
        .arg(levelStrings[level])
        .arg(message);
}

QStringList Logger::messages() const
{
    QStringList result;
    for (const auto &msg : m_messages) {
        if (msg.level >= m_logLevel) {
            result.append(msg.formatted());
        }
    }
    return result;
}

void Logger::setLogLevel(int level)
{
    if (m_logLevel != level) {
        m_logLevel = level;
        updateFileMessages();
        emit logLevelChanged();
    }
}

void Logger::debug(const QString &message) { addMessage(Debug, message); }
void Logger::info(const QString &message) { addMessage(Info, message); }
void Logger::warning(const QString &message) { addMessage(Warning, message); }
void Logger::error(const QString &message) { addMessage(Error, message); }
void Logger::fatal(const QString &message) { addMessage(Fatal, message); }

QStringList Logger::getFilteredMessages(int level) const
{
    QStringList result;
    for (const auto &msg : m_messages) {
        if (msg.level >= level) {
            result.append(msg.formatted());
        }
    }
    return result;
}

void Logger::clear()
{
    m_messages.clear();
    emit messagesChanged();
}

QStringList Logger::readLogFile(int maxLines) const
{
    QFile file(m_logFilePath);
    if (!file.exists()) {
        qWarning() << "日志文件不存在:" << m_logFilePath;
        return QStringList();
    }
    
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "无法打开日志文件:" << m_logFilePath << ", 错误:" << file.errorString();
        return QStringList();
    }

    QStringList lines;
    QTextStream in(&file);
    
    // 先读取所有行
    QStringList allLines;
    while (!in.atEnd()) {
        QString line = in.readLine();
        if (!line.isEmpty()) {
            allLines.prepend(line);  // 倒序存储，最新的在前面
        }
    }
    
    qDebug() << "读取日志文件，总行数:" << allLines.size();
    return allLines.mid(0, maxLines);
}

QStringList Logger::readLogFileFiltered(int level, int maxLines) const
{
    QFile file(m_logFilePath);
    if (!file.exists() || !file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "无法读取日志文件:" << m_logFilePath;
        return QStringList();
    }

    QStringList filteredLines;
    QTextStream in(&file);
    
    while (!in.atEnd() && filteredLines.size() < maxLines) {
        QString line = in.readLine();
        if (line.isEmpty()) continue;
        
        LogLevel msgLevel = Info; // 默认级别
        
        if (line.contains("[DEBUG]")) msgLevel = Debug;
        else if (line.contains("[INFO]")) msgLevel = Info;
        else if (line.contains("[WARN]")) msgLevel = Warning;
        else if (line.contains("[ERROR]")) msgLevel = Error;
        else if (line.contains("[FATAL]")) msgLevel = Fatal;
        
        if (msgLevel >= level) {
            filteredLines.prepend(line);  // 新消息在前
        }
    }
    
    return filteredLines;
}

void Logger::updateFileMessages()
{
    QStringList newMessages;
    if (m_searchPattern.isEmpty()) {
        newMessages = readLogFileFiltered(m_logLevel);
    } else {
        newMessages = searchLogs(m_searchPattern);
    }
    
    if (m_fileMessages != newMessages) {
        m_fileMessages = newMessages;
        emit fileMessagesChanged();
        emit logStatsChanged();
    }
}

void Logger::refreshFileMessages()
{
    updateFileMessages();
}

void Logger::setSearchPattern(const QString &pattern)
{
    if (m_searchPattern != pattern) {
        m_searchPattern = pattern;
        updateFileMessages();
        emit searchPatternChanged();
    }
}

QVariantMap Logger::logStats() const
{
    QVariantMap stats;
    int debugCount = 0, infoCount = 0, warnCount = 0, errorCount = 0, fatalCount = 0;
    
    for (const QString &msg : m_fileMessages) {
        if (msg.contains("[DEBUG]")) debugCount++;
        else if (msg.contains("[INFO]")) infoCount++;
        else if (msg.contains("[WARN]")) warnCount++;
        else if (msg.contains("[ERROR]")) errorCount++;
        else if (msg.contains("[FATAL]")) fatalCount++;
    }
    
    stats["debug"] = debugCount;
    stats["info"] = infoCount;
    stats["warn"] = warnCount;
    stats["error"] = errorCount;
    stats["fatal"] = fatalCount;
    stats["total"] = m_fileMessages.size();
    
    return stats;
}

QStringList Logger::searchLogs(const QString &pattern, int maxResults) const
{
    if (pattern.isEmpty()) {
        return m_fileMessages.mid(0, maxResults);
    }
    
    QStringList results;
    QRegularExpression regex(pattern, QRegularExpression::CaseInsensitiveOption);
    
    for (const QString &msg : m_fileMessages) {
        if (results.size() >= maxResults) break;
        if (msg.contains(regex)) {
            results.append(msg);
        }
    }
    
    return results;
}

QVariantMap Logger::getLogStatsByTimeRange(const QDateTime &start, const QDateTime &end) const
{
    QVariantMap stats;
    int debugCount = 0, infoCount = 0, warnCount = 0, errorCount = 0, fatalCount = 0;
    
    for (const QString &msg : m_fileMessages) {
        // 解析日志消息中的时间戳
        // 假设时间戳格式为 "yyyy-MM-dd hh:mm:ss"
        QDateTime msgTime = QDateTime::fromString(msg.mid(1, 19), "yyyy-MM-dd hh:mm:ss");
        
        if (msgTime >= start && msgTime <= end) {
            if (msg.contains("[DEBUG]")) debugCount++;
            else if (msg.contains("[INFO]")) infoCount++;
            else if (msg.contains("[WARN]")) warnCount++;
            else if (msg.contains("[ERROR]")) errorCount++;
            else if (msg.contains("[FATAL]")) fatalCount++;
        }
    }
    
    stats["debug"] = debugCount;
    stats["info"] = infoCount;
    stats["warn"] = warnCount;
    stats["error"] = errorCount;
    stats["fatal"] = fatalCount;
    stats["total"] = debugCount + infoCount + warnCount + errorCount + fatalCount;
    
    // 添加时间范围信息
    stats["startTime"] = start.toString("yyyy-MM-dd hh:mm:ss");
    stats["endTime"] = end.toString("yyyy-MM-dd hh:mm:ss");
    
    return stats;
}
