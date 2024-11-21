#ifndef DEFAULTAPPS_H
#define DEFAULTAPPS_H

#include <QObject>
#include <QStringList>

class DefaultApps : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList imageViewers READ imageViewers NOTIFY imageViewersChanged)
    Q_PROPERTY(QStringList videoPlayers READ videoPlayers NOTIFY videoPlayersChanged)

public:
    explicit DefaultApps(QObject *parent = nullptr);

    QStringList imageViewers() const { return m_imageViewers; }
    QStringList videoPlayers() const { return m_videoPlayers; }

    Q_INVOKABLE void searchDefaultApps();
    Q_INVOKABLE void addImageViewer(const QString &path);
    Q_INVOKABLE void addVideoPlayer(const QString &path);

signals:
    void imageViewersChanged();
    void videoPlayersChanged();

private:
    QStringList m_imageViewers;
    QStringList m_videoPlayers;
};

#endif // DEFAULTAPPS_H 