#include "filesystemmanager.h"
#include <QDir>
#include <QDirIterator>
#include <QDebug>
#include <QDateTime>
#include <QCoreApplication>
#include "models/filelistmodel.h"
#include "../utils/previewgenerator.h"
#include "utils/filetypes.h"
#include <QSettings>
#include <QStandardPaths>
#include "tagmanager.h"

FileSystemManager::FileSystemManager(QObject *parent)
    : QObject(parent)
    , m_fileWatcher(new QFileSystemWatcher(this))
    , m_logger(new Logger(this))
    , m_fileModel(new FileListModel(this))
    , m_previewGenerator(new PreviewGenerator(this))
{
    m_logger->setLogFilePath(Logger::getLogFilePath(Logger::FileSystem));
    m_logger->setLogLevel(Logger::Info);
    m_logger->info("文件系统管理器初始化开始");
    
    // 连接信号
    connect(m_fileWatcher, &QFileSystemWatcher::fileChanged,
            this, &FileSystemManager::onFileChanged);
    connect(m_fileWatcher, &QFileSystemWatcher::directoryChanged,
            this, &FileSystemManager::onDirectoryChanged);
    
    // 连接视图模式变更信号
    connect(m_fileModel, &FileListModel::needGeneratePreviews,
            this, &FileSystemManager::generatePreviews);

    // 连接 PreviewGenerator 的信号
    connect(m_previewGenerator, &PreviewGenerator::spritesGenerated,
            this, &FileSystemManager::spritesGenerated);
    connect(m_previewGenerator, &PreviewGenerator::spriteProgress,
            this, &FileSystemManager::spriteProgress);
            
    m_logger->info("文件系统管理器初始化完成");
}

void FileSystemManager::setCurrentPath(const QString &path) { 
    if (m_currentPath != path) {
        m_currentPath = path;
        if (!m_isScanning && !m_isUpdatingTree) {
            QVector<QSharedPointer<FileData>> files = scanDirectory(path);
            m_fileModel->setFiles(files);
        }
        emit currentPathChanged(path);
    }
}

FileSystemManager::~FileSystemManager()
{
    if (m_fileWatcher) {
        m_fileWatcher->deleteLater();
    }
    if (m_logger) {
        m_logger->deleteLater();
    }
    if (m_fileModel) {
        m_fileModel->deleteLater();
    }
    if (m_previewGenerator) {
        m_previewGenerator->deleteLater();
    }
}

void FileSystemManager::addLogMessage(const QString &message)
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
    m_logger->info(message);
    
    m_messages.prepend(message);
    while (m_messages.size() > 100) {
        m_messages.removeLast();
    }
    
    emit logMessagesChanged();
}

void FileSystemManager::clearLogs()
{
    m_messages.clear();
    emit logMessagesChanged();
}

void FileSystemManager::setWatchPath(const QString &path)
{
    m_logger->info(QString("置监控路径: %1").arg(path));
    
    if (m_currentPath != path) {
        m_currentPath = path;
        emit currentPathChanged(path);
        
        // 检查是否有文件被监视
        QStringList watchedFiles = m_fileWatcher->files();
        if (!watchedFiles.isEmpty()) {
            m_fileWatcher->removePaths(watchedFiles);
            m_logger->info(QString("停止监控文件: %1").arg(watchedFiles.join(", ")));
        }
        
        // 检查是否有目录被监视
        QStringList watchedDirs = m_fileWatcher->directories();
        if (!watchedDirs.isEmpty()) {
            m_fileWatcher->removePaths(watchedDirs);
            m_logger->info(QString("停止监控目录: %1").arg(watchedDirs.join(", ")));
        }
        
        if (!path.isEmpty()) {
            // 添加新路径的监控
            if (!m_fileWatcher->addPath(path)) {
                m_logger->error(QString("监控路径失败: %1").arg(path));
            } else {
                m_logger->info(QString("开始监控路径: %1").arg(path));
            }
        }
    }
}

QString FileSystemManager::getFileId(const QString &filePath)
{
    if (m_fileModel) {
        QString cachedId = m_fileModel->getFileId(filePath);
        if (!cachedId.isEmpty()) {
            m_logger->debug(QString("使用缓存的文件ID: %1 -> %2").arg(filePath, cachedId));
            return cachedId;
        }
    }
    
    HANDLE hFile = CreateFileW(
        reinterpret_cast<LPCWSTR>(filePath.utf16()),
        FILE_READ_ATTRIBUTES,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        NULL,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULL
    );
    
    if (hFile == INVALID_HANDLE_VALUE) {
        m_logger->error(QString("无法获取文件ID: %1").arg(filePath));
        return QString();
    }

    BY_HANDLE_FILE_INFORMATION fileInfo;
    if (!GetFileInformationByHandle(hFile, &fileInfo)) {
        CloseHandle(hFile);
        m_logger->error(QString("获取文件信息失败: %1").arg(filePath));
        return QString();
    }

    CloseHandle(hFile);
    QString fileId = QString("%1-%2").arg(fileInfo.nFileIndexHigh).arg(fileInfo.nFileIndexLow);
    m_logger->debug(QString("生成文件ID: %1 -> %2").arg(filePath, fileId));
    return fileId;
}

void FileSystemManager::updateFileTree(const QString &path)
{
    if (!m_fileTree || m_isUpdatingTree) return;
    
    m_isUpdatingTree = true;
    QMetaObject::invokeMethod(m_fileTree, "loadDirectory",
                             Q_ARG(QVariant, path),
                             Q_ARG(QVariant, true));
    m_logger->info(QString("已更新文件树视图: %1").arg(path));
    m_isUpdatingTree = false;
}

QVector<QSharedPointer<FileData>> FileSystemManager::scanDirectory(const QString &path, const QStringList &filters)
{
    if (m_isScanning) return QVector<QSharedPointer<FileData>>();
    
    m_isScanning = true;
    m_logger->info(QString("开始扫描目录: %1").arg(path));
    
    // 设置监控路径
    setWatchPath(path);
    
    // 更新文件树
    if (!m_isUpdatingTree) {
        updateFileTree(path);
    }
    
    m_logger->debug(QString("使用过滤器: %1").arg(filters.join(", ")));
    
    QStringList actualFilters = filters;
    if (actualFilters.isEmpty()) {
        actualFilters = FileTypes::getAllFilters();
        m_logger->debug(QString("使用默认过滤器: %1").arg(actualFilters.join(", ")));
    }
    
    QDir dir(path);
    if (!dir.exists()) {
        m_logger->error(QString("目录不存在: %1").arg(path));
        return QVector<QSharedPointer<FileData>>();
    }

    // 设置文件筛选器
    dir.setNameFilters(actualFilters);
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    // 使用智能指针管理内存
    const int BATCH_SIZE = 1000;
    QVector<QSharedPointer<FileData>> files;
    QHash<QString, FileData> previousFiles;
    
    // 分配一个合理的初始容量
    files.reserve(qMin(m_fileList.size(), 10000));
    previousFiles.reserve(qMin(m_fileList.size(), 10000));
    
    // 将之前的文件列表转换为哈希表
    for (const auto &file : m_fileList) {
        previousFiles.insert(file->filePath(), *file);
    }

    // 递归扫描
    QDirIterator it(path, 
                   filters, 
                   QDir::Files | QDir::NoDotAndDotDot,
                   QDirIterator::Subdirectories);

    int fileCount = 0;
    int changedCount = 0;
    QVector<QSharedPointer<FileData>> batch;
    batch.reserve(BATCH_SIZE);
    
    while (it.hasNext()) {
        QString filePath = it.next();
        m_logger->debug(QString("系统|扫描|处理文件|%1").arg(filePath));
        
        // 每处理1000个文件输出一次进度
        if (fileCount % 1000 == 0) {
            m_logger->info(QString("系统|扫描|进度|已处理 %1 个文件").arg(fileCount));
        }
        
        QFileInfo fileInfo = it.fileInfo();
        
        FileData data;
        // 使用 setter 方法来设置属性
        data.setFilePath(fileInfo.absoluteFilePath());
        data.setFileName(fileInfo.fileName());
        data.setFileType(fileInfo.suffix().toLower());
        data.setFileSize(fileInfo.size());
        data.setModifiedDate(fileInfo.lastModified());
        
        // 检查文件是否发生变化
        auto previousFile = previousFiles.find(data.filePath());
        if (previousFile == previousFiles.end() || 
            previousFile->fileSize() != data.fileSize() ||    
            previousFile->modifiedDate() != data.modifiedDate()) {  
        
            data.setFileId(getFileId(data.filePath()));
            changedCount++;
        } else {
            data.setFileId(previousFile->fileId()); 
        }
        
        // 使用 make_shared 创建对象
        batch.append(QSharedPointer<FileData>::create(data));
        fileCount++;
        
        // 批量处理
        if (batch.size() >= BATCH_SIZE) {
            files.append(batch);
            batch.clear();
            batch.reserve(BATCH_SIZE);
            
            // 输出进度
            addLogMessage(QString("正在扫描...已处理 %1 个文件").arg(fileCount));
            QCoreApplication::processEvents();  // 让UI保持响应
        }
    }
    
    // 处理最后一批
    if (!batch.isEmpty()) {
        files.append(batch);
    }

    m_logger->info(QString("系统|扫描|完成|共处理 %1 个文件|新增修改 %2 个")
                  .arg(fileCount)
                  .arg(changedCount));

    // 检查文件变化
    bool hasChanges = (m_fileList.size() != files.size()) || (changedCount > 0);
    
    if (hasChanges) {
        m_logger->info("正在更新文件列表...");
        m_fileList = files;
        
        if (m_fileModel) {
            m_fileModel->updateFiles(m_fileList);
        }
        
        // 更新文件树
        updateFileTree(path);
    }
    
    if (m_fileModel && m_fileModel->viewMode() == FileListModel::LargeIconView) {
        for (const auto &fileData : m_fileList) {
            QString type = fileData->fileType().toLower();
            if (FileTypes::isImageFile(type) || FileTypes::isVideoFile(type)) {
                m_previewGenerator->generatePreview(fileData);
            }
        }
    }
    
    m_isScanning = false;
    return files;
}

void FileSystemManager::openFileWithProgram(const QString &filePath, const QString &programPath)
{
    QProcess *process = new QProcess(this);  // 使用指针并设置父对象
    QStringList arguments;
    arguments << filePath;
    
    qDebug() << "Opening file:" << filePath << "with program:" << programPath;
    
    if (!process->startDetached(programPath, arguments)) {
        addLogMessage(QString("无法打开文件: %1").arg(filePath));
        qDebug() << "Failed to open file:" << process->errorString();
        process->deleteLater();  // 清理内存
    } else {
        process->deleteLater();  // 成功启动后也要清理
    }
}

QString FileSystemManager::getFfmpegPath() const
{
    return m_ffmpegPath;
}

void FileSystemManager::setFfmpegPath(const QString &path)
{
    if (m_ffmpegPath != path) {
        m_ffmpegPath = path;
        addLogMessage(QString("FFmpeg 路径已更新: %1").arg(path));
    }
}

void FileSystemManager::generatePreviews()
{
    if (!m_previewGenerator || !m_fileModel) return;
    
    qDebug() << "开始为所有文件生成预览...";
    
    for (const auto &fileData : m_fileList) {
        QString type = fileData->fileType().toLower();
        if (FileTypes::isImageFile(type) || FileTypes::isVideoFile(type)) {
            // qDebug() << "为文件生成预览:" << fileData->fileName();
            m_previewGenerator->generatePreview(fileData);
        }
    }
}

void FileSystemManager::openFile(const QString &filePath, const QString &fileType)
{
    m_logger->info(QString("操作|打开文件|%1|%2").arg(filePath, fileType));
    
    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) 
                      + "/FileTaggingPro.ini", QSettings::IniFormat);
    settings.beginGroup("Players");
    
    QString program;
    if (FileTypes::isImageFile(fileType)) {
        program = settings.value("imagePlayer").toString();
        m_logger->debug(QString("系统|配置|图片查看器|%1").arg(program));
    } else if (FileTypes::isVideoFile(fileType)) {
        program = settings.value("videoPlayer").toString();
        m_logger->debug(QString("系统|配置|视频放器|%1").arg(program));
    }
    
    settings.endGroup();
    
    if (program.isEmpty()) {
        m_logger->warning(QString("系统|配置|未配置播放器|%1").arg(fileType));
        return;
    }
    
    QProcess *process = new QProcess(this);
    process->setProgram(program);
    process->setArguments(QStringList() << filePath);
    
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            [this, process, filePath](int exitCode, QProcess::ExitStatus exitStatus) {
        if (exitStatus == QProcess::CrashExit) {
            m_logger->error(QString("系统|进程|崩溃|%1").arg(process->errorString()));
        } else if (exitCode != 0) {
            m_logger->warning(QString("系统|进程|异常退出|%1").arg(exitCode));
        } else {
            m_logger->debug("系统|进程|正常退出");
        }
        process->deleteLater();
    });
    
    connect(process, &QProcess::errorOccurred, 
            [this, process](QProcess::ProcessError error) {
        m_logger->error(QString("系统|进程|启动失败|%1").arg(process->errorString()));
        process->deleteLater();
    });
    
    process->start();
    m_logger->info(QString("操作|启动程序|%1|%2").arg(program, filePath));
}

void FileSystemManager::generateVideoSprites(const QString &filePath, int count) {
    if (!m_previewGenerator) return;
    
    m_logger->info(QString("系统|预览|生成精灵图|%1|数量:%2").arg(filePath).arg(count));
    QStringList paths = m_previewGenerator->generateVideoSprites(filePath, count);
    emit spritesGenerated(paths);
}

void FileSystemManager::openVideoAtTime(const QString &filePath, double timestamp)
{
    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) 
                      + "/FileTaggingPro.ini", QSettings::IniFormat);
    settings.beginGroup("Players");
    QString program = settings.value("videoPlayer").toString();
    settings.endGroup();
    
    if (program.isEmpty()) {
        m_logger->warning("系统|配置|未配置视频播放器");
        return;
    }
    
    QProcess *process = new QProcess(this);
    QStringList arguments;
    
    QString normalizedPath = QDir::toNativeSeparators(QFileInfo(filePath).absoluteFilePath());
    
    if (program.contains("vlc", Qt::CaseInsensitive)) {
        arguments << "--start-time" << QString::number(timestamp) << normalizedPath;
        m_logger->debug("系统|播放器|VLC|使用时间参数");
    } else if (program.contains("mpc-hc", Qt::CaseInsensitive)) {
        arguments << "/start" << QString::number(qRound(timestamp * 1000)) << normalizedPath;
        m_logger->debug("系统|播放器|MPC-HC|使用时间参数");
    } else if (program.contains("PotPlayer", Qt::CaseInsensitive)) {
        arguments << normalizedPath << "/seek=" + QString::number(qRound(timestamp));
        m_logger->debug("系统|播放器|PotPlayer|使用时间参数");
    } else {
        arguments << normalizedPath;
        m_logger->warning("系统|播放器|不支持时间定位");
    }
    
    process->setProgram(program);
    process->setArguments(arguments);
    
    m_logger->debug(QString("系统|播放器|启动命令|%1 %2").arg(program, arguments.join(" ")));
    
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            process, &QProcess::deleteLater);
            
    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
        m_logger->error(QString("系统|播放器|启动失败|%1").arg(process->errorString()));
        process->deleteLater();
    });
    
    if (!process->startDetached()) {
        m_logger->error(QString("系统|播放器|无法启动|%1").arg(process->errorString()));
        process->deleteLater();
    } else {
        m_logger->info(QString("操作|播放视频|%1|%2|%3秒")
                     .arg(QFileInfo(program).fileName())
                     .arg(filePath)
                     .arg(timestamp));
    }
}

double FileSystemManager::getSpriteTimestamp(const QString &spritePath) const
{
    if (!m_previewGenerator) return 0.0;
    
    // 通过 PreviewGenerator 获取时间戳
    return m_previewGenerator->getSpriteTimestamp(spritePath);
}

void FileSystemManager::onFileRenamed(const QString &oldPath, const QString &newPath)
{
    // 由我们使用 fileId 系统，文件重命名不需要更新数据库
    // 只需要更新界面显示
    emit fileRenamed(oldPath, newPath);
}

void FileSystemManager::onFileChanged(const QString &path)
{
    m_logger->debug(QString("系统|文件变更|%1").arg(path));
    
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        m_logger->warning(QString("系统|文件删除|%1").arg(path));
    } else {
        m_logger->debug(QString("系统|文件修改|%1|%2").arg(path)
            .arg(fileInfo.lastModified().toString("yyyy-MM-dd hh:mm:ss")));
    }
}

void FileSystemManager::onDirectoryChanged(const QString &path)
{
    m_logger->info(QString("系统|目录变更|%1").arg(path));
    
    QDir dir(path);
    if (!dir.exists()) {
        m_logger->warning(QString("系统|目录删除|%1").arg(path));
    }
}
