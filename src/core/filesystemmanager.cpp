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

FileSystemManager::FileSystemManager(QObject *parent)
    : QObject(parent)
    , m_fileWatcher(new QFileSystemWatcher(this))
    , m_logger(new Logger(this))
    , m_fileModel(new FileListModel(this))
    , m_previewGenerator(new PreviewGenerator(this))
{
    qDebug() << "FileSystemManager 构造函数 - 创建的文件模型:" << m_fileModel;
    
    connect(m_fileWatcher, &QFileSystemWatcher::fileChanged,
            this, &FileSystemManager::fileChanged);
    connect(m_fileWatcher, &QFileSystemWatcher::directoryChanged,
            this, &FileSystemManager::directoryChanged);
            
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
    qDebug() << "设置监控路径:" << path;
    if (m_currentPath != path) {
        if (!m_currentPath.isEmpty()) {
            // 移除旧路径的监控
            m_fileWatcher->removePaths(m_fileWatcher->files());
            m_fileWatcher->removePaths(m_fileWatcher->directories());
            addLogMessage(QString("停止监控目录: %1").arg(m_currentPath));
        }
        m_currentPath = path;
        if (!path.isEmpty()) {
            // 添加新路径的监控
            m_fileWatcher->addPath(path);
            // 同时监控子目录
            QDirIterator it(path, QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
            while (it.hasNext()) {
                QString subDir = it.next();
                m_fileWatcher->addPath(subDir);
            }
            addLogMessage(QString("开始监控目录: %1").arg(path));
            qDebug() << "即将扫描目录:" << path;
            scanDirectory(path);
            qDebug() << "目录扫描完成";
            
            // 扫描完目录后，检查是否需要生成预览
            if (m_fileModel && m_fileModel->viewMode() == FileListModel::LargeIconView) {
                qDebug() << "当前为大图标视图，开始生成预览...";
                generatePreviews();
            }
        }
        emit currentPathChanged();
    }
}

QString FileSystemManager::getFileId(const QString &filePath)
{
    HANDLE hFile = CreateFileW(reinterpret_cast<LPCWSTR>(filePath.utf16()),
                             FILE_READ_ATTRIBUTES,
                             FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                             NULL,
                             OPEN_EXISTING,
                             FILE_ATTRIBUTE_NORMAL,
                             NULL);
    
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
    if (path.isEmpty()) {
        qDebug() << "路径为空，无法扫描";
        return QVector<QSharedPointer<FileData>>();
    }

    addLogMessage(QString("开始扫描目录: %1").arg(path));
    
    // 如果没有指定筛选器，使用默认的图片和视频筛选器
    QStringList actualFilters = filters;
    if (actualFilters.isEmpty()) {
        actualFilters = FileTypes::getAllFilters();
    }
    
    QDir dir(path);
    if (!dir.exists()) {
        qDebug() << "目录不存在:" << path;
        addLogMessage(QString("错误：目录不存在 %1").arg(path));
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

    addLogMessage(QString("扫描完成，共发现 %1 个文件，其中 %2 个文件发生变化")
                 .arg(fileCount)
                 .arg(changedCount));

    // 检查文件变化
    bool hasChanges = (m_fileList.size() != files.size()) || (changedCount > 0);
    
    if (hasChanges) {
        m_fileList = files;
        qDebug() << "文件列表已更新，数量:" << files.size();
        
        if (m_fileModel) {
            qDebug() << "正在更新文件模型...";

            m_fileModel->setFiles(files);
            qDebug() << "文件模型更新完成";
        } else {
            qDebug() << "错误：文模型为空!";
        }
        emit fileListChanged();
        
        // 输出变化详情
        if (changedCount > 0) {
            addLogMessage(QString("修改文件: %1 个").arg(changedCount));
        }
    } else {
        addLogMessage("文件列表无变化");
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
    // 确保设置目录存在
    QDir settingsDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    if (!settingsDir.exists()) {
        settingsDir.mkpath(".");
    }
    
    // 使用相同的配置文件路径
    QString iniPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) 
                     + "/FileTaggingPro.ini";
    QSettings settings(iniPath, QSettings::IniFormat);
    settings.beginGroup("Players");  // 使用相同的类别
                      
    qDebug() << "Settings 文件路径:" << settings.fileName();
    qDebug() << "Settings 目录:" << settingsDir.absolutePath();
    qDebug() << "所有键:" << settings.allKeys();
    
    QString program;
    
    // 根据文件类型选择合适的播放器
    if (FileTypes::isImageFile(fileType)) {
        program = settings.value("imagePlayer").toString();
        qDebug() << "读取到的图片播放器路径:" << program;
    } else if (FileTypes::isVideoFile(fileType)) {
        program = settings.value("videoPlayer").toString();
        qDebug() << "读取到的视频播放器路径:" << program;
    }
    
    settings.endGroup();  // 结束分组
    
    if (program.isEmpty()) {
        addLogMessage(QString("未配置%1文件的播放器 (类型: %2)").arg(fileType, filePath));
        return;
    }
    
    QProcess *process = new QProcess(this);
    process->setProgram(program);
    process->setArguments(QStringList() << filePath);
    
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            process, &QProcess::deleteLater);
            
    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError error) {
        addLogMessage(QString("打开文件失败: %1").arg(process->errorString()));
        process->deleteLater();
    });
    
    process->start();
    addLogMessage(QString("正在使用 %1 打开文件: %2").arg(program, filePath));
}

void FileSystemManager::generateVideoSprites(const QString &filePath, int count) {
    if (!m_previewGenerator) return;
    
    QStringList paths = m_previewGenerator->generateVideoSprites(filePath, count);
    emit spritesGenerated(paths);
}
