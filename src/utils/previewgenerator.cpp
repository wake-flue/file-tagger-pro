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
#include "spritegenerator.h"

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
    
    QString hash = QCryptographicHash::hash(fileData->filePath().toUtf8(), QCryptographicHash::Md5).toHex();
    QString cachePath = m_cacheDir + "/" + hash + ".jpg";
    
    if (QFile::exists(cachePath)) {
        fileData->setPreviewPath(cachePath);
        return;
    }
    
    QString filePath = fileData->filePath();
    m_currentFile = fileData;
    fileData->setPreviewLoading(true);
    
    QFuture<QString> future = QtConcurrent::run([this, fileData]() {
        if (!fileData) return QString();
        
        QString fileType = QFileInfo(fileData->filePath()).suffix().toLower();
        try {
            if (FileTypes::isImageFile(fileType)) {
                return generateImagePreview(fileData->filePath());
            } else if (FileTypes::isVideoFile(fileType)) {
                return generateVideoPreview(fileData->filePath());
            }
        } catch (const std::exception &e) {
            qWarning() << "预览生成失败:" << e.what();
        }
        return QString();
    });
    
    QTimer::singleShot(5000, this, [this, fileData]() {
        if (fileData && fileData->previewLoading()) {
            fileData->setPreviewLoading(false);
            fileData->setPreviewPath(QString());
        }
    });
    
    m_watcher.setFuture(future);
}

QString PreviewGenerator::generateImagePreview(const QString &path) {
    QImage image(path);
    if (image.isNull()) {
        qWarning() << "无法加载图片:" << path;
        return QString();
    }
    
    QSize targetSize(240, 240);
    QImage scaled = image.scaled(targetSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    
    if (scaled.isNull()) {
        qWarning() << "图片缩放失败:" << path;
        return QString();
    }
    
    QString hash = QCryptographicHash::hash(path.toUtf8(), QCryptographicHash::Md5).toHex();
    QString cachePath = m_cacheDir + "/" + hash + ".jpg";
    
    QDir().mkpath(QFileInfo(cachePath).absolutePath());
    
    if (scaled.save(cachePath, "JPG", 90)) {
        return cachePath;
    }
    
    qWarning() << "预览图保存失败:" << cachePath;
    return QString();
}

QString PreviewGenerator::generateVideoPreview(const QString &path) {
    AVFormatContext *formatContext = nullptr;
    if (avformat_open_input(&formatContext, path.toUtf8().constData(), nullptr, nullptr) < 0) {
        qWarning() << "无法打开视频文件:" << path;
        return QString();
    }
    
    if (avformat_find_stream_info(formatContext, nullptr) < 0) {
        qWarning() << "无法获取视频流信息:" << path;
        avformat_close_input(&formatContext);
        return QString();
    }
    
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
    
    AVCodecParameters *codecParams = formatContext->streams[videoStream]->codecpar;
    const AVCodec *codec = avcodec_find_decoder(codecParams->codec_id);
    if (!codec) {
        qWarning() << "未找到解码器:" << path;
        avformat_close_input(&formatContext);
        return QString();
    }
    
    AVCodecContext *codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        qWarning() << "无法分配解码器上下文:" << path;
        avformat_close_input(&formatContext);
        return QString();
    }
    
    if (avcodec_parameters_to_context(codecContext, codecParams) < 0) {
        qWarning() << "无法复制编解码器参数:" << path;
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    if (avcodec_open2(codecContext, codec, nullptr) < 0) {
        qWarning() << "无法打开解码器:" << path;
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
    int64_t duration = formatContext->duration;
    int64_t seekTarget = duration > 0 ? duration / 3 : 0;
    av_seek_frame(formatContext, -1, seekTarget, AVSEEK_FLAG_BACKWARD);
    
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
    
    int width = codecContext->width;
    int height = codecContext->height;
    int targetWidth = 240;
    int targetHeight = height * targetWidth / width;
    
    int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, targetWidth, targetHeight, 1);
    uint8_t *buffer = (uint8_t *)av_malloc(numBytes);
    
    if (!buffer) {
        qWarning() << "无法分配图像缓冲区:" << path;
        av_frame_free(&frameRGB);
        av_frame_free(&frame);
        avcodec_free_context(&codecContext);
        avformat_close_input(&formatContext);
        return QString();
    }
    
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
    
    SwsContext *swsContext = sws_getContext(
        width, height, codecContext->pix_fmt,
        targetWidth, targetHeight, AV_PIX_FMT_RGB24,
        SWS_LANCZOS | SWS_ACCURATE_RND,
        nullptr, nullptr, nullptr
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
                sws_scale(swsContext, frame->data, frame->linesize, 0, height,
                         frameRGB->data, frameRGB->linesize);
                
                QImage image(frameRGB->data[0], targetWidth, targetHeight,
                           frameRGB->linesize[0], QImage::Format_RGB888);
                
                QString hash = QCryptographicHash::hash(path.toUtf8(), QCryptographicHash::Md5).toHex();
                QString cachePath = m_cacheDir + "/" + hash + ".jpg";
                
                if (image.save(cachePath, "JPG", 95)) {
                    frameExtracted = true;
                    av_packet_unref(packet);
                    
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
        if (!dir.mkpath(m_cacheDir)) {
            qWarning() << "缓存目录创建失败";
        }
    }
}

QString PreviewGenerator::getCachePath() {
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/previews";
}

QStringList PreviewGenerator::generateVideoSprites(const QString &path, int count)
{
    if (!m_spriteGenerator) {
        m_spriteGenerator = std::make_unique<SpriteGenerator>();
        
        connect(m_spriteGenerator.get(), &SpriteGenerator::progressChanged,
                this, [this](int current, int total) {
                    emit spriteProgress(current, total);
                });
                
        connect(m_spriteGenerator.get(), &SpriteGenerator::error,
                this, [this](const QString &message) {
            qWarning() << "雪碧图生成错误:" << message;
        });
    }
    
    QStringList paths = m_spriteGenerator->generateSprites(path, count);
    emit spritesGenerated(paths);
    return paths;
}

double PreviewGenerator::getSpriteTimestamp(const QString &spritePath) const
{
    if (!m_spriteGenerator) return 0.0;
    return m_spriteGenerator->getSpriteTimestamp(spritePath);
} 