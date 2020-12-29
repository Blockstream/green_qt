#ifndef GREEN_COMMAND_H
#define GREEN_COMMAND_H

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

template <typename T>
class Command2 : public Activity
{
public:
    Command2(Device* device) : Activity(device)
    {
    }
    T result() const { return m_result; };
    void setResult(const T& result)
    {
        m_result = result;
        finish();
    }
private:
    T m_result;
};

#endif // GREEN_COMMAND_H
