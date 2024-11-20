#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QString>
#include <QStringList>

class Logger : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList messages READ messages NOTIFY messagesChanged)

public:
    explicit Logger(QObject *parent = nullptr);
    
    QStringList messages() const { return m_messages; }
    
    void addMessage(const QString &message);
    void clear();

signals:
    void messagesChanged();

private:
    QStringList m_messages;
    static const int MAX_MESSAGES = 100;
};

#endif // LOGGER_H
