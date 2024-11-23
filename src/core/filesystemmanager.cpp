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
    // 配置日志系统
    QString logDir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/logs";
    QDir().mkpath(logDir);  // 确保目录存在
    QString logPath = logDir + "/filemanager.log";
    
    qDebug() << "日志目录:" << logDir;
    qDebug() << "日志文件路径:" << logPath;
    
    m_logger->setLogFilePath(logPath);
    m_logger->setLogFileMaxSize(5 * 1024 * 1024);  // 5MB
    m_logger->setMaxLogFiles(10);
    
    // 初始化后立即写入一条日志以测试
    m_logger->info("文件管理器初始化完成");
    m_logger->refreshFileMessages();
    
    emit loggerChanged();  // 通知 logger 属性变化
    
    qDebug() << "FileSystemManager 构造函数 - 创建的文件模型:" << m_fileModel;
    
    connect(m_fileWatcher, &QFileSystemWatcher::fileChanged,
            this, &FileSystemManager::onFileChanged);
    connect(m_fileWatcher, &QFileSystemWatcher::directoryChanged,
            this, &FileSystemManager::onDirectoryChanged);
            
    addLogMessage("文件管理器初始化完成");
    
    // 连接视图模式变更信号
    connect(m_fileModel, &FileListModel::needGeneratePreviews,
            this, &FileSystemManager::generatePreviews);

    // 连接 PreviewGenerator 的信号
    connect(m_previewGenerator, &PreviewGenerator::spritesGenerated,
            this, &FileSystemManager::spritesGenerated);
    connect(m_previewGenerator, &PreviewGenerator::spriteProgress,
            this, &FileSystemManager::spriteProgress);
}

FileSystemManager::~FileSystemManager()
{
    delete m_fileWatcher;
    delete m_logger;
    delete m_previewGenerator;
}

void FileSystemManager::addLogMessage(const QString &message)
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
    QString logMessage = QString("[%1] %2").arg(timestamp).arg(message);
    
    m_messages.prepend(logMessage);
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
    m_logger->info(QString("开始设置监控路径: %1").arg(path));
    
    if (m_currentPath != path) {
        if (!m_currentPath.isEmpty()) {
            // 移除旧路径的监控
            m_fileWatcher->removePaths(m_fileWatcher->files());
            m_fileWatcher->removePaths(m_fileWatcher->directories());
            m_logger->info(QString("已停止监控旧路径: %1").arg(m_currentPath));
        }
        
        m_currentPath = path;
        
        if (!path.isEmpty()) {
            // 添加新路径的监控
            if (!m_fileWatcher->addPath(path)) {
                m_logger->error(QString("添加监控路径失败: %1").arg(path));
            } else {
                m_logger->info(QString("成功添加监控路径: %1").arg(path));
            }
            
            // 监控子目录
            QDirIterator it(path, QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
            int subDirCount = 0;
            while (it.hasNext()) {
                QString subDir = it.next();
                if (m_fileWatcher->addPath(subDir)) {
                    subDirCount++;
                } else {
                    m_logger->warning(QString("添加子目录监控失败: %1").arg(subDir));
                }
            }
            m_logger->info(QString("已添加 %1 个子目录到监控").arg(subDirCount));
            
            // 扫描目录
            m_logger->info("开始扫描目录...");
            scanDirectory(path);
            m_logger->info("目录扫描完成");
            
            // 检查是否需要生成预览
            if (m_fileModel && m_fileModel->viewMode() == FileListModel::LargeIconView) {
                m_logger->info("当前为大图标视图,开始生成预览...");
                generatePreviews();
            }
        }
        emit currentPathChanged();
    }
}

QString FileSystemManager::getFileId(const QString &filePath)
{
    if (m_fileModel) {
        QString cachedId = m_fileModel->getFileId(filePath);
        if (!cachedId.isEmpty()) {
            return cachedId;
        }
    }
    
    // 如果缓存中没有，再使用Windows API计算
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
        addLogMessage(QString("无法获取文件ID: %1").arg(filePath));
        return QString();
    }

    BY_HANDLE_FILE_INFORMATION fileInfo;
    if (!GetFileInformationByHandle(hFile, &fileInfo)) {
        CloseHandle(hFile);
        addLogMessage(QString("获取文件信息失败: %1").arg(filePath));
        return QString();
    }

    CloseHandle(hFile);
    return QString("%1-%2").arg(fileInfo.nFileIndexHigh).arg(fileInfo.nFileIndexLow);
}

QVector<QSharedPointer<FileData>> FileSystemManager::scanDirectory(const QString &path, const QStringList &filters)
{
    m_logger->info(QString("开始扫描目录: %1").arg(path));
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
        m_logger->debug(QString("正在处理文件: %1").arg(filePath));
        
        // 每处理1000个文件输出一次进度
        if (fileCount % 1000 == 0) {
            m_logger->info(QString("扫描进度: 已处理 %1 个文件").arg(fileCount));
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

    m_logger->info(QString("扫描完成: 共处理 %1 个文件, 新增/修改 %2 个")
                  .arg(fileCount)
                  .arg(changedCount));

    // 检查文件变化
    bool hasChanges = (m_fileList.size() != files.size()) || (changedCount > 0);
    
    if (hasChanges) {
        m_logger->info("正在更新文件列表...");
        m_fileList = files;
        
        if (m_fileModel) {
            m_logger->debug("正在更新文件模型...");
            m_fileModel->setFiles(files);
            m_logger->debug("文件模型更新完成");
        } else {
            m_logger->error("文件模型为空,无法更新!");
        }
        
        emit fileListChanged();
    } else {
        m_logger->info("文件列表无变化");
    }
    
    if (m_fileModel && m_fileModel->viewMode() == FileListModel::LargeIconView) {
        for (const auto &fileData : m_fileList) {
            QString type = fileData->fileType().toLower();
            if (FileTypes::isImageFile(type) || FileTypes::isVideoFile(type)) {
                m_previewGenerator->generatePreview(fileData);
            }
        }
    }
    
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
    m_logger->info(QString("尝试打开文件: %1 (类型: %2)").arg(filePath, fileType));
    
    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) 
                      + "/FileTaggingPro.ini", QSettings::IniFormat);
    settings.beginGroup("Players");
    
    QString program;
    if (FileTypes::isImageFile(fileType)) {
        program = settings.value("imagePlayer").toString();
        m_logger->debug(QString("使用图片查看器: %1").arg(program));
    } else if (FileTypes::isVideoFile(fileType)) {
        program = settings.value("videoPlayer").toString();
        m_logger->debug(QString("使用视频播放器: %1").arg(program));
    }
    
    settings.endGroup();
    
    if (program.isEmpty()) {
        m_logger->warning(QString("未配置%1文件的播放器").arg(fileType));
        return;
    }
    
    QProcess *process = new QProcess(this);
    process->setProgram(program);
    process->setArguments(QStringList() << filePath);
    
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            [this, process, filePath](int exitCode, QProcess::ExitStatus exitStatus) {
        if (exitStatus == QProcess::CrashExit) {
            m_logger->error(QString("程序崩溃: %1").arg(process->errorString()));
        } else if (exitCode != 0) {
            m_logger->warning(QString("程序退出码: %1").arg(exitCode));
        } else {
            m_logger->debug("程序正常退出");
        }
        process->deleteLater();
    });
    
    connect(process, &QProcess::errorOccurred, 
            [this, process](QProcess::ProcessError error) {
        m_logger->error(QString("打开文件失败: %1").arg(process->errorString()));
        process->deleteLater();
    });
    
    process->start();
    m_logger->info(QString("正在使用 %1 打开文件: %2").arg(program, filePath));
}

void FileSystemManager::generateVideoSprites(const QString &filePath, int count) {
    if (!m_previewGenerator) return;
    
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
        addLogMessage("未配置视频播放器");
        return;
    }
    
    QProcess *process = new QProcess(this);
    QStringList arguments;
    
    // 确保文件路径是绝对路径并且正确格式化
    QString normalizedPath = QDir::toNativeSeparators(QFileInfo(filePath).absoluteFilePath());
    
    // 根据不同播放器添加时间戳参数
    if (program.contains("vlc", Qt::CaseInsensitive)) {
        // VLC 播放器
        arguments << "--start-time" << QString::number(timestamp) << normalizedPath;
    } else if (program.contains("mpc-hc", Qt::CaseInsensitive)) {
        // MPC-HC 播放器
        arguments << "/start" << QString::number(qRound(timestamp * 1000)) << normalizedPath;
    } else if (program.contains("PotPlayer", Qt::CaseInsensitive)) {
        // PotPlayer 播放器
        // 修改 PotPlayer 的参数格式
        arguments << normalizedPath << "/seek=" + QString::number(qRound(timestamp));
    } else {
        // 默认情况，直接打开视频
        arguments << normalizedPath;
        addLogMessage("当前播放器可能不支持时间定位");
    }
    
    process->setProgram(program);
    process->setArguments(arguments);
    
    qDebug() << "启动播放器:" << program;
    qDebug() << "参数:" << arguments;
    
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            process, &QProcess::deleteLater);
            
    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
        addLogMessage("播放器启动失败: " + process->errorString());
        process->deleteLater();
    });
    
    if (!process->startDetached()) {
        addLogMessage("无法启动播放器: " + process->errorString());
        qDebug() << "启动失败原因:" << process->errorString();
        process->deleteLater();
    } else {
        addLogMessage(QString("正在使用 %1 打开视频，时间戳: %2 秒")
                     .arg(QFileInfo(program).fileName())
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
    m_logger->info(QString("检测到文件变更: %1").arg(path));
    
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        m_logger->warning(QString("文件已被删除: %1").arg(path));
    } else {
        m_logger->debug(QString("文件修改时间: %1").arg(
            fileInfo.lastModified().toString("yyyy-MM-dd hh:mm:ss")));
    }
}

void FileSystemManager::onDirectoryChanged(const QString &path)
{
    m_logger->info(QString("检测到目录变更: %1").arg(path));
    
    QDir dir(path);
    if (!dir.exists()) {
        m_logger->warning(QString("目录已被删除: %1").arg(path));
    }
}
