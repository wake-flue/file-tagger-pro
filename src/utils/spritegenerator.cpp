#include "spritegenerator.h"
#include <QDir>
#include <QStandardPaths>
#include <QCryptographicHash>
#include <QImage>
#include <QDebug>
#include <QThreadPool>

SpriteGenerator::SpriteGenerator(QObject *parent) : QObject(parent), 
    m_completedTasks(0), m_totalTasks(0)
{
    ensureCacheDirectory();
    m_threadPool = new QThreadPool(this);
    m_threadPool->setMaxThreadCount(QThread::idealThreadCount());
}

SpriteGenerator::~SpriteGenerator()
{
    m_threadPool->waitForDone();
}

void SpriteGenerator::ensureCacheDirectory()
{
    if (m_cacheDir.isEmpty()) {
        m_cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) 
                    + "/sprites";
    }
    
    QDir dir;
    if (!dir.exists(m_cacheDir)) {
        if (!dir.mkpath(m_cacheDir)) {
            emit error("无法创建缓存目录");
        }
    }
}

QStringList SpriteGenerator::generateSprites(const QString &videoPath, int count)
{
    QStringList spritePaths;
    QString hash = QCryptographicHash::hash(videoPath.toUtf8(), QCryptographicHash::Md5).toHex();
    
    m_completedTasks = 0;
    m_totalTasks = count;
    
    // 创建并提交所有任务
    for (int i = 0; i < count; i++) {
        // 为每个任务创建新的 AVFormatContext
        AVFormatContext *formatContext = nullptr;
        if (avformat_open_input(&formatContext, videoPath.toUtf8().constData(), nullptr, nullptr) < 0) {
            emit error("无法打开视频文件");
            continue;
        }
        
        if (avformat_find_stream_info(formatContext, nullptr) < 0) {
            emit error("无法获取视频流信息");
            avformat_close_input(&formatContext);
            continue;
        }
        
        int videoStream = -1;
        for (unsigned int j = 0; j < formatContext->nb_streams; j++) {
            if (formatContext->streams[j]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                videoStream = j;
                break;
            }
        }
        
        if (videoStream == -1) {
            emit error("未找到视频流");
            avformat_close_input(&formatContext);
            continue;
        }
        
        AVStream *stream = formatContext->streams[videoStream];
        int64_t duration;
        if (stream->duration != AV_NOPTS_VALUE) {
            duration = stream->duration;
        } else if (formatContext->duration != AV_NOPTS_VALUE) {
            duration = av_rescale_q(formatContext->duration, AV_TIME_BASE_Q, stream->time_base);
        } else {
            emit error("无法获取视频时长");
            avformat_close_input(&formatContext);
            continue;
        }
        
        int64_t interval = duration / (count + 1);
        int64_t timestamp = interval * (i + 1);
        QString spritePath = m_cacheDir + "/" + hash + "_sprite_" + QString::number(i) + ".jpg";
        spritePaths.append(spritePath);
        
        SpriteGeneratorTask *task = new SpriteGeneratorTask(
            this, formatContext, videoStream, timestamp, spritePath);
        task->setAutoDelete(true);
        m_threadPool->start(task);
    }
    
    // 等待所有任务完成
    m_threadPool->waitForDone();
    
    return spritePaths;
}

QString SpriteGenerator::generateSingleSprite(AVFormatContext *formatContext, 
                                            int videoStream,
                                            qint64 timestamp,
                                            const QString &outputPath)
{
    AVStream *stream = formatContext->streams[videoStream];
    AVCodecParameters *codecParams = stream->codecpar;
    
    const AVCodec *codec = avcodec_find_decoder(codecParams->codec_id);
    if (!codec) {
        emit error("无法找到解码器");
        return QString();
    }
    
    AVCodecContext *codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        emit error("无法创建解码器上下文");
        return QString();
    }
    
    if (avcodec_parameters_to_context(codecContext, codecParams) < 0) {
        emit error("无法复制编解码器参数");
        avcodec_free_context(&codecContext);
        return QString();
    }
    
    if (avcodec_open2(codecContext, codec, nullptr) < 0) {
        emit error("无法打开解码器");
        avcodec_free_context(&codecContext);
        return QString();
    }
    
    int seekFlags = AVSEEK_FLAG_BACKWARD;
    int maxRetries = 3;
    bool seekSuccess = false;
    
    for (int retry = 0; retry < maxRetries && !seekSuccess; retry++) {
        int currentFlags = seekFlags;
        int64_t currentTimestamp = timestamp;
        
        if (retry == 1) {
            currentFlags |= AVSEEK_FLAG_ANY;
        } else if (retry == 2) {
            currentTimestamp = av_rescale_q(av_rescale_q(timestamp, stream->time_base, AV_TIME_BASE_Q),
                                          AV_TIME_BASE_Q, stream->time_base);
        }
        
        if (av_seek_frame(formatContext, videoStream, currentTimestamp, currentFlags) >= 0) {
            seekSuccess = true;
            break;
        }
    }
    
    if (!seekSuccess) {
        emit error("无法定位到指定时间戳");
        avcodec_free_context(&codecContext);
        return QString();
    }
    
    avcodec_flush_buffers(codecContext);
    
    AVFrame *frame = av_frame_alloc();
    AVFrame *rgbFrame = av_frame_alloc();
    AVFrame *bestFrame = av_frame_alloc();
    AVPacket *packet = av_packet_alloc();
    
    SwsContext *swsContext = sws_getContext(
        codecContext->width, codecContext->height, codecContext->pix_fmt,
        codecContext->width, codecContext->height, AV_PIX_FMT_RGB24,
        SWS_BILINEAR, nullptr, nullptr, nullptr
    );
    
    int numBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, codecContext->width, codecContext->height, 1);
    uint8_t *buffer = (uint8_t *)av_malloc(numBytes);
    av_image_fill_arrays(rgbFrame->data, rgbFrame->linesize, buffer,
                        AV_PIX_FMT_RGB24, codecContext->width, codecContext->height, 1);
    
    bool frameExtracted = false;
    int maxFramesToRead = 200;
    int framesRead = 0;
    int64_t bestDiff = INT64_MAX;
    
    while (av_read_frame(formatContext, packet) >= 0 && !frameExtracted && framesRead < maxFramesToRead) {
        if (packet->stream_index == videoStream) {
            int sendResult = avcodec_send_packet(codecContext, packet);
            if (sendResult < 0) {
                av_packet_unref(packet);
                continue;
            }
            
            while (true) {
                int receiveResult = avcodec_receive_frame(codecContext, frame);
                if (receiveResult == AVERROR(EAGAIN) || receiveResult == AVERROR_EOF) {
                    break;
                } else if (receiveResult < 0) {
                    break;
                }
                
                // 计算当前帧与目标时间戳的差值
                int64_t diff = llabs(frame->pts - timestamp);
                if (diff < bestDiff) {
                    av_frame_unref(bestFrame);
                    av_frame_ref(bestFrame, frame);
                    bestDiff = diff;
                    
                    if (diff < 1) {  // 如果找到足够接近的帧
                        frameExtracted = true;
                        break;
                    }
                }
            }
        }
        av_packet_unref(packet);
        framesRead++;
        
        if (frameExtracted) break;
    }
    
    bool saveSuccess = false;
    if (bestDiff != INT64_MAX) {
        int scaleResult = sws_scale(swsContext, bestFrame->data, bestFrame->linesize, 0,
                                  codecContext->height, rgbFrame->data, rgbFrame->linesize);
        
        if (scaleResult > 0) {
            QImage image(rgbFrame->data[0], 
                        codecContext->width, 
                        codecContext->height,
                        rgbFrame->linesize[0], 
                        QImage::Format_RGB888);
            
            saveSuccess = image.save(outputPath, "JPG", 40);
        }
    }
    
    av_frame_free(&bestFrame);
    av_frame_free(&frame);
    av_frame_free(&rgbFrame);
    av_packet_free(&packet);
    av_free(buffer);
    sws_freeContext(swsContext);
    avcodec_free_context(&codecContext);
    
    return saveSuccess ? outputPath : QString();
}

double SpriteGenerator::getSpriteTimestamp(const QString &spritePath) const
{
    return m_spriteTimestamps.value(spritePath, 0.0);
}

SpriteGeneratorTask::SpriteGeneratorTask(SpriteGenerator *generator,
                                       AVFormatContext *formatContext,
                                       int videoStream,
                                       qint64 timestamp,
                                       const QString &outputPath)
    : m_generator(generator),
      m_formatContext(formatContext),
      m_videoStream(videoStream),
      m_timestamp(timestamp),
      m_outputPath(outputPath)
{
}

void SpriteGeneratorTask::run()
{
    QString generatedPath = m_generator->generateSingleSprite(
        m_formatContext, m_videoStream, m_timestamp, m_outputPath);
        
    if (!generatedPath.isEmpty()) {
        QMutexLocker locker(&m_generator->m_mutex);
        double timeInSeconds = m_timestamp * 
            av_q2d(m_formatContext->streams[m_videoStream]->time_base);
        m_generator->m_spriteTimestamps[generatedPath] = timeInSeconds;
        m_generator->m_completedTasks++;
        QMetaObject::invokeMethod(m_generator, "progressChanged",
                                Qt::QueuedConnection,
                                Q_ARG(int, m_generator->m_completedTasks),
                                Q_ARG(int, m_generator->m_totalTasks));
    }
}

SpriteGeneratorTask::~SpriteGeneratorTask()
{
    if (m_formatContext) {
        avformat_close_input(&m_formatContext);
    }
}