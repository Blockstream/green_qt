#ifndef GREEN_ACTIVITY_H
#define GREEN_ACTIVITY_H

#include <QObject>
#include <QtQml>

#include "progress.h"

class ActivityManager;

class Activity : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString type READ type CONSTANT)
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(Progress* progress READ progress CONSTANT)
    Q_PROPERTY(QJsonObject message READ message NOTIFY messageChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    // TODO: maybe split Pending to Ready and Active
    enum class Status {
        Pending,
        Finished,
        Failed,
    };
    Q_ENUM(Status)
    Activity(QObject* parent = nullptr);
    QString type() const;
    Status status() const;
    Progress* progress() { return &m_progress; }
    QJsonObject message() const { return m_message; }
    void setMessage(const QJsonObject& message);
    void finish();
    void fail();
private:
    virtual void exec() = 0;
signals:
    void statusChanged(Status status);
    void finished();
    void failed();
    void messageChanged(const QJsonObject& message);
private:
    Status m_status{Status::Pending};
    Progress m_progress;
    QJsonObject m_message;

    friend class ActivityManager;
};

#endif // GREEN_ACTIVITY_H
