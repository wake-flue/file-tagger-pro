#include "spritegenerator.h"
#include <QDir>
#include <QStandardPaths>
#include <QCryptographicHash>
#include <QImage>
#include <QDebug>

SpriteGenerator::SpriteGenerator(QObject *parent) : QObject(parent)
{
    ensureCacheDirectory();
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
    
    AVFormatContext *formatContext = nullptr;
    if (avformat_open_input(&formatContext, videoPath.toUtf8().constData(), nullptr, nullptr) < 0) {
        emit error("无法打开视频文件");
        return spritePaths;
    }
    
    if (avformat_find_stream_info(formatContext, nullptr) < 0) {
        emit error("无法获取视频流信息");
        avformat_close_input(&formatContext);
        return spritePaths;
    }
    
    int videoStream = -1;
    for (unsigned int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
            break;
        }
    }
    
    if (videoStream == -1) {
        emit error("未找到视频流");
        avformat_close_input(&formatContext);
        return spritePaths;
    }
    
    AVStream *stream = formatContext->streams[videoStream];
    AVRational timeBase = stream->time_base;
    
    int64_t duration;
    if (stream->duration != AV_NOPTS_VALUE) {
        duration = stream->duration;
    } else if (formatContext->duration != AV_NOPTS_VALUE) {
        duration = av_rescale_q(formatContext->duration, AV_TIME_BASE_Q, stream->time_base);
    } else {
        emit error("无法获取视频时长");
        avformat_close_input(&formatContext);
        return spritePaths;
    }
    
    int64_t interval = duration / (count + 1);
    QString hash = QCryptographicHash::hash(videoPath.toUtf8(), QCryptographicHash::Md5).toHex();
    
    for (int i = 0; i < count; i++) {
        int64_t timestamp = interval * (i + 1);
        QString spritePath = m_cacheDir + "/" + hash + "_sprite_" + QString::number(i) + ".jpg";
        
        QString generatedPath = generateSingleSprite(formatContext, videoStream, timestamp, spritePath);
        if (!generatedPath.isEmpty()) {
            spritePaths.append(generatedPath);
            double timeInSeconds = timestamp * av_q2d(stream->time_base);
            m_spriteTimestamps[generatedPath] = timeInSeconds;
        }
        
        emit progressChanged(i + 1, count);
    }
    
    avformat_close_input(&formatContext);
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
    
    int64_t timestampTolerance = av_rescale_q(2, AV_TIME_BASE_Q, stream->time_base);
    int64_t minTimestamp = timestamp - timestampTolerance;
    int64_t maxTimestamp = timestamp + timestampTolerance;
    
    AVFrame *bestFrame = av_frame_alloc();
    int64_t bestDiff = INT64_MAX;
    
    while (av_read_frame(formatContext, packet) >= 0 && !frameExtracted && framesRead < maxFramesToRead) {
        if (packet->stream_index == videoStream) {
            int sendResult = avcodec_send_packet(codecContext, packet);
            if (sendResult < 0) {
                av_packet_unref(packet);
                continue;
            }
            
            while (sendResult >= 0) {
                int receiveResult = avcodec_receive_frame(codecContext, frame);
                if (receiveResult == AVERROR(EAGAIN) || receiveResult == AVERROR_EOF) {
                    break;
                } else if (receiveResult < 0) {
                    break;
                }
                
                int64_t diff = llabs(frame->pts - timestamp);
                if (diff < bestDiff) {
                    av_frame_unref(bestFrame);
                    av_frame_ref(bestFrame, frame);
                    bestDiff = diff;
                    
                    if (diff < timestampTolerance / 10) {
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
            
            saveSuccess = image.save(outputPath, "JPG", 100);
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