#include "defaultapps.h"
#include <QSettings>
#include <QDir>
#include <QDebug>

DefaultApps::DefaultApps(QObject *parent) : QObject(parent)
{
}

void DefaultApps::searchDefaultApps()
{
    m_imageViewers.clear();
    m_videoPlayers.clear();

    // 只添加一些常见的播放器路径作为建议
    QStringList commonImageViewers = {
        "C:\\Program Files\\IrfanView\\i_view64.exe",
        "C:\\Program Files\\FastStone Image Viewer\\FSViewer.exe",
        "C:\\Program Files\\Honeyview\\Honeyview.exe"
    };

    QStringList commonVideoPlayers = {
        "C:\\Program Files\\VideoLAN\\VLC\\vlc.exe",
        "C:\\Program Files\\MPC-HC\\mpc-hc64.exe",
        "C:\\Program Files\\DAUM\\PotPlayer\\PotPlayerMini64.exe"
    };

    // 检查并添加常见程序
    for (const QString &path : commonImageViewers) {
        if (QFile::exists(path) && !m_imageViewers.contains(path)) {
            m_imageViewers.append(path);
        }
    }

    for (const QString &path : commonVideoPlayers) {
        if (QFile::exists(path) && !m_videoPlayers.contains(path)) {
            m_videoPlayers.append(path);
        }
    }

    emit imageViewersChanged();
    emit videoPlayersChanged();
}

void DefaultApps::addImageViewer(const QString &path)
{
    if (!path.isEmpty() && !m_imageViewers.contains(path)) {
        m_imageViewers.append(path);
        emit imageViewersChanged();
    }
}

void DefaultApps::addVideoPlayer(const QString &path)
{
    if (!path.isEmpty() && !m_videoPlayers.contains(path)) {
        m_videoPlayers.append(path);
        emit videoPlayersChanged();
    }
} 