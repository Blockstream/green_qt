#ifndef GREEN_ACTIVITY_H
#define GREEN_ACTIVITY_H

#include <QObject>

class Activity : public QObject
{
    Q_OBJECT
public:
    enum class Status {
        Pending,
        Finished,
        Failed,
    };
    Activity(QObject* parent);
    virtual void exec() = 0;
protected:
    Status status() const;
    void finish();
    void fail();
signals:
    void finished();
    void failed();
private:
    Status m_status{Status::Pending};
};

#endif // GREEN_ACTIVITY_H
