#include "logger.h"
#include <QDateTime>

Logger::Logger(QObject *parent)
    : QObject(parent)
{
}

void Logger::addMessage(const QString &message)
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");
    QString formattedMessage = QString("[%1] %2").arg(timestamp).arg(message);
    
    m_messages.prepend(formattedMessage);
    
    while (m_messages.size() > MAX_MESSAGES) {
        m_messages.removeLast();
    }
    
    emit messagesChanged();
}

void Logger::clear()
{
    m_messages.clear();
    emit messagesChanged();
}
