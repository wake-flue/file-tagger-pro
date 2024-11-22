#ifndef TAG_H
#define TAG_H

#include <QString>
#include <QDateTime>
#include <QColor>
#include <QObject>

class Tag : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)

public:
    explicit Tag(QObject *parent = nullptr);
    
    int id() const { return m_id; }
    void setId(int id) { 
        if (m_id != id) {
            m_id = id; 
            emit idChanged();
        }
    }
    
    QString name() const { return m_name; }
    void setName(const QString &name) { 
        if (m_name != name) {
            m_name = name; 
            emit nameChanged();
        }
    }
    
    QColor color() const { return m_color; }
    void setColor(const QColor &color) { 
        if (m_color != color) {
            m_color = color; 
            emit colorChanged();
        }
    }
    
    QString description() const { return m_description; }
    void setDescription(const QString &description) { 
        if (m_description != description) {
            m_description = description; 
            emit descriptionChanged();
        }
    }
    
    QDateTime createdAt() const { return m_createdAt; }
    void setCreatedAt(const QDateTime &dt) { m_createdAt = dt; }
    
    QDateTime updatedAt() const { return m_updatedAt; }
    void setUpdatedAt(const QDateTime &dt) { m_updatedAt = dt; }

signals:
    void idChanged();
    void nameChanged();
    void colorChanged();
    void descriptionChanged();

private:
    int m_id{-1};
    QString m_name;
    QColor m_color{Qt::blue};
    QString m_description;
    QDateTime m_createdAt;
    QDateTime m_updatedAt;
};

Q_DECLARE_METATYPE(Tag*)
Q_DECLARE_METATYPE(QVector<Tag*>)

#endif // TAG_H 