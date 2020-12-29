#ifndef GREEN_ACTIVITY_H
#define GREEN_ACTIVITY_H

#include <QObject>

QT_FORWARD_DECLARE_CLASS(Device)

class Activity : public QObject
{
    Q_OBJECT
public:
    enum class Status {
        Pending,
        Finished,
        Failed,
    };
    Activity(Device* device);
    Device* device() const;
    virtual void exec() = 0;
protected:
    Status status() const;
    void finish();
    void fail();
signals:
    void finished();
    void failed();
private:
    Device* const m_device;
    Status m_status{Status::Pending};
};

#endif // GREEN_ACTIVITY_H
