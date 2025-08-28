#ifndef GREEN_APPLICATIONCONTROLLER_H
#define GREEN_APPLICATIONCONTROLLER_H

#include <QObject>
#include <QQmlEngine>

class ApplicationController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    ApplicationController(QObject* parent = nullptr);
    virtual ~ApplicationController();
public slots:
    void triggerQuit();
    void quit();
    void triggerCrash();
    void reportCrashes();
signals:
    void quitRequested();
    void quitTriggered();
protected:
    bool eventFilter(QObject *obj, QEvent *event);
private:
    bool m_quit_triggered{false};
};

#endif // GREEN_APPLICATIONCONTROLLER_H
