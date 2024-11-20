#include "previewgenerator.h"
#include <QDir>
#include <QStandardPaths>
#include <QImage>
#include <QCryptographicHash>
#include <QtConcurrent>
#include <QDebug>
#include <QElapsedTimer>
#include <QTimer>
#include "filetypes.h"

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

PreviewGenerator::PreviewGenerator(QObject *parent) : QObject(parent) {
    connect(&m_watcher, &QFutureWatcher<QString>::finished, this, [this]() {
        QString previewPath = m_watcher.result();
        auto fileData = m_currentFile.lock();
        if (fileData) {
            fileData->setPreviewPath(previewPath);
            fileData->setPreviewLoading(false);
        }
    });
    
    ensureCacheDirectory();
}

void PreviewGenerator::generatePreview(QSharedPointer<FileData> fileData) {
    if (!fileData) {
        qWarning() << "PreviewGenerator: Null fileData pointer";
        return;
    }
    
    // 检查缓存是否已存在
    QString hash = QCryptographicHash::hash(fileData->filePath().toUtf8(), QCryptographicHash::Md5).toHex();
    QString cachePath = m_cacheDir + "/" + hash + ".jpg";
    
    if (QFile::exists(cachePath)) {
        qDebug() << "使用缓存的预览图:" << fileData->fileName();
        fileData->setPreviewPath(cachePath);
        return;
    }
    
    QString filePath = fileData->filePath();
    qDebug() << "开始生成预览:" << filePath;
    
    m_currentFile = fileData;
    fileData->setPreviewLoading(true);
    
    // 使用超时处理的异步任务
    QFuture<QString> future = QtConcurrent::run([this, fileData]() {
        if (!fileData) return QString();
        
        QString fileType = QFileInfo(fileData->filePath()).suffix().toLower();
        try {
            if (FileTypes::isImageFile(fileType)) {
                qDebug() << "生成图片预览:" << fileData->filePath();
                return generateImagePreview(fileData->filePath());
            } else if (FileTypes::isVideoFile(fileType)) {
                qDebug() << "生成视频预览:" << fileData->filePath();
                return generateVideoPreview(fileData->filePath());
            }
        } catch (const std::exception &e) {
            qWarning() << "预览生成失败:" << e.what();
        }
        return QString();
    });
    
    // 设置任务超时
    QTimer::singleShot(5000, this, [this, fileData]() {
        if (fileData && fileData->previewLoading()) {
            qWarning() << "预览生成任务超时:" << fileData->fileName();
            fileData->setPreviewLoading(false);
            fileData->setPreviewPath(QString());
        }
    });
    
    m_watcher.setFuture(future);
}

QString PreviewGenerator::generateImagePreview(const QString &path) {
    qDebug() << "开始生成图片预览:" << path;
    
    QImage image(path);
    if (image.isNull()) {
        qWarning() << "无法加载图片:" << path;
        return QString();
    }
    
    // 调整缩放逻辑，确保生成合适大小的预览图
    QSize targetSize(160, 160);
    QImage scaled = image.scaled(targetSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    
    if (scaled.isNull()) {
        qWarning() << "图片缩放失败:" << path;
        return QString();
    }
    
    QString hash = QCryptographicHash::hash(path.toUtf8(), QCryptographicHash::Md5).toHex();
    QString cachePath = m_cacheDir + "/" + hash + ".jpg";
    
    // 确保缓存目录存在
    QDir().mkpath(QFileInfo(cachePath).absolutePath());
    
    qDebug() << "保存预览图到:" << cachePath;
    
    // 使用较高的质量设置保存预览图
    if (scaled.save(cachePath, "JPG", 90)) {
        qDebug() << "预览图生成成功:" << cachePath;
        return cachePath;
    }
    
    qWarning() << "预览图保存失败:" << cachePath;
    return QString();
}

QString PreviewGenerator::generateVideoPreview(const QString &path) {
    qDebug() << "开始生成视频预览:" << path;
    
    AVFormatContext *formatContext = nullptr;
    if (avformat_open_input(&formatContext, path.toUtf8().constData(), nullptr, nullptr) < 0) {
        qWarning() << "无法打开视频文件:" << path;
        return QString();
    }
    
    // 获取视频信息
    if (avformat_find_stream_info(formatContext, nullptr) < 0) {
        qWarning() << "无法获取视频流信息:" << path;
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 查找视频流
    int videoStream = -1;
    for (unsigned int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
            break;
        }
    }
    
    if (videoStream == -1) {
        qWarning() << "未找到视频流:" << path;
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 获取解码器
    AVCodecParameters *codecParams = formatContext->streams[videoStream]->codecpar;
    const AVCodec *codec = avcodec_find_decoder(codecParams->codec_id);
    if (!codec) {
        qWarning() << "未找到解码器:" << path;
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 创建解码器上下文
    AVCodecContext *codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        qWarning() << "无法分配解码器上下文:" << path;
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 将编解码器参数复制到上下文
    if (avcodec_parameters_to_context(codecContext, codecParams) < 0) {
        qWarning() << "无法复制编解码器参数:" << path;
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 打开解码器
    if (avcodec_open2(codecContext, codec, nullptr) < 0) {
        qWarning() << "无法打开解码器:" << path;
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 定位到视频的大约 1/3 处
    int64_t duration = formatContext->duration;
    int64_t seekTarget = duration > 0 ? duration / 3 : 0;
    av_seek_frame(formatContext, -1, seekTarget, AVSEEK_FLAG_BACKWARD);
    
    // 分配帧缓冲
    AVFrame *frame = av_frame_alloc();
    AVFrame *frameRGB = av_frame_alloc();
    if (!frame || !frameRGB) {
        qWarning() << "无法分配帧缓冲:" << path;
        av_frame_free(&frameRGB);
        av_frame_free(&frame);
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 设置输出格式
    int width = codecContext->width;
    int height = codecContext->height;
    int targetWidth = 160;
    int targetHeight = height * targetWidth / width;
    
    // 分配转换后的帧缓冲
    int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, targetWidth, targetHeight, 1);
    uint8_t *buffer = (uint8_t *)av_malloc(numBytes);
    
    // 检查内存分配
    if (!buffer) {
        qWarning() << "无法分配图像缓冲区:" << path;
        av_frame_free(&frameRGB);
        av_frame_free(&frame);
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 设置帧缓冲区
    int ret = av_image_fill_arrays(frameRGB->data, frameRGB->linesize, buffer,
                                 AV_PIX_FMT_RGB24, targetWidth, targetHeight, 1);
    if (ret < 0) {
        qWarning() << "无法设置帧缓冲区:" << path;
        av_free(buffer);
        av_frame_free(&frameRGB);
        av_frame_free(&frame);
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 创建缩放上下文
    SwsContext *swsContext = sws_getContext(
        width, height, codecContext->pix_fmt,
        targetWidth, targetHeight, AV_PIX_FMT_RGB24,
        SWS_BILINEAR, nullptr, nullptr, nullptr
    );
    
    if (!swsContext) {
        qWarning() << "无法创建缩放上下文:" << path;
        av_free(buffer);
        av_frame_free(&frameRGB);
        av_frame_free(&frame);
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    // 读取帧
    AVPacket *packet = av_packet_alloc();
    bool frameExtracted = false;
    
    while (av_read_frame(formatContext, packet) >= 0 && !frameExtracted) {
        if (packet->stream_index == videoStream) {
            int response = avcodec_send_packet(codecContext, packet);
            if (response < 0) {
                qWarning() << "发送数据包错误:" << path;
                break;
            }
            
            response = avcodec_receive_frame(codecContext, frame);
            if (response >= 0) {
                // 转换帧格式
                sws_scale(swsContext, frame->data, frame->linesize, 0, height,
                         frameRGB->data, frameRGB->linesize);
                
                // 创建QImage
                QImage image(frameRGB->data[0], targetWidth, targetHeight,
                           frameRGB->linesize[0], QImage::Format_RGB888);
                
                // 保存预览图
                QString hash = QCryptographicHash::hash(path.toUtf8(), QCryptographicHash::Md5).toHex();
                QString cachePath = m_cacheDir + "/" + hash + ".jpg";
                
                if (image.save(cachePath, "JPG", 90)) {
                    qDebug() << "视频预览生成成功:" << cachePath;
                    frameExtracted = true;
                    av_packet_unref(packet);
                    
                    // 清理资源
                    av_packet_free(&packet);
                    av_free(buffer);
                    sws_freeContext(swsContext);
                    av_frame_free(&frameRGB);
                    av_frame_free(&frame);
                    avcodec_free_context(&codecContext);
                    avformat_close_input(&formatContext);
                    
                    return cachePath;
                }
            }
        }
        av_packet_unref(packet);
    }
    
    // 清理资源
    av_packet_free(&packet);
    av_free(buffer);
    sws_freeContext(swsContext);
    av_frame_free(&frameRGB);
    av_frame_free(&frame);
    avcodec_free_context(&codecContext);
    avformat_close_input(&formatContext);
    
    qWarning() << "无法提取视频帧:" << path;
    return QString();
}

void PreviewGenerator::ensureCacheDirectory() {
    m_cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/previews";
    QDir dir;
    if (!dir.exists(m_cacheDir)) {
        qDebug() << "创建缓存目录:" << m_cacheDir;
        if (dir.mkpath(m_cacheDir)) {
            qDebug() << "缓存目录创建成功";
        } else {
            qWarning() << "缓存目录创建失败";
        }
    }
    qDebug() << "使用缓存目录:" << m_cacheDir;
}

QString PreviewGenerator::getCachePath() {
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/previews";
} 