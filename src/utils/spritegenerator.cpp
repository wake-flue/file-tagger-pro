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
    
    // 获取视频流的时间基准
    AVStream *stream = formatContext->streams[videoStream];
    AVRational timeBase = stream->time_base;
    
    // 计算视频总时长（以流的时间基准为单位）
    int64_t duration = stream->duration;
    if (duration == AV_NOPTS_VALUE) {
        duration = av_rescale_q(formatContext->duration, AV_TIME_BASE_Q, timeBase);
    }
    
    // 计算时间间隔
    int64_t interval = duration / (count + 1);
    
    // 生成每一帧的雪碧图
    QString hash = QCryptographicHash::hash(videoPath.toUtf8(), QCryptographicHash::Md5).toHex();
    
    for (int i = 0; i < count; i++) {
        int64_t timestamp = interval * (i + 1);
        QString spritePath = m_cacheDir + "/" + hash + "_sprite_" + QString::number(i) + ".jpg";
        
        QString generatedPath = generateSingleSprite(formatContext, videoStream, timestamp, spritePath);
        if (!generatedPath.isEmpty()) {
            spritePaths.append(generatedPath);
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
    
    // 定位到指定时间戳
    if (av_seek_frame(formatContext, videoStream, timestamp, AVSEEK_FLAG_BACKWARD) < 0) {
        emit error("无法定位到指定时间戳");
        avcodec_free_context(&codecContext);
        return QString();
    }
    
    // 清空解码器缓冲区
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
    int maxFramesToRead = 100;  // 设置最大读取帧数
    int framesRead = 0;
    
    while (av_read_frame(formatContext, packet) >= 0 && !frameExtracted && framesRead < maxFramesToRead) {
        if (packet->stream_index == videoStream) {
            int sendResult = avcodec_send_packet(codecContext, packet);
            if (sendResult < 0) {
                av_packet_unref(packet);
                continue;
            }
            
            while (sendResult >= 0 && !frameExtracted) {
                int receiveResult = avcodec_receive_frame(codecContext, frame);
                if (receiveResult == AVERROR(EAGAIN) || receiveResult == AVERROR_EOF) {
                    break;
                } else if (receiveResult < 0) {
                    break;
                }
                
                // 检查是否达到目标时间戳
                if (frame->pts >= timestamp) {
                    sws_scale(swsContext, frame->data, frame->linesize, 0,
                             codecContext->height, rgbFrame->data, rgbFrame->linesize);
                    
                    QImage image(rgbFrame->data[0], codecContext->width, codecContext->height,
                                rgbFrame->linesize[0], QImage::Format_RGB888);
                    
                    if (image.save(outputPath, "JPG", 100)) {
                        frameExtracted = true;
                    }
                }
            }
        }
        av_packet_unref(packet);
        framesRead++;
    }
    
    // 清理资源
    av_frame_free(&frame);
    av_frame_free(&rgbFrame);
    av_packet_free(&packet);
    av_free(buffer);
    sws_freeContext(swsContext);
    avcodec_free_context(&codecContext);
    
    return frameExtracted ? outputPath : QString();
}