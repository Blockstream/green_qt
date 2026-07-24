#include "applicationcontroller.h"

#include <QApplication>
#include <QDebug>
#include <QEvent>

ApplicationController::ApplicationController(QObject* parent)
    : QObject(parent)
{
    qApp->installEventFilter(this);
}

ApplicationController::~ApplicationController()
{
    qApp->removeEventFilter(this);
}

void ApplicationController::triggerQuit()
{
    qDebug() << Q_FUNC_INFO << m_quit_triggered;
    m_quit_triggered = true;
    emit quitTriggered();
}

void ApplicationController::quit()
{
    qDebug() << Q_FUNC_INFO << m_quit_triggered;
    qApp->removeEventFilter(this);
    qApp->quit();
}

void ApplicationController::triggerCrash()
{
    qDebug() << Q_FUNC_INFO;
    // Force a real access violation so crashpad captures a complete, valid
    // minidump on every platform. abort() is a fast-fail on Windows whose
    // (often truncated) dump self-hosted Sentry rejects as "Invalid Minidump".
    volatile int* p = nullptr;
    *p = 0;
}

bool ApplicationController::eventFilter(QObject* obj, QEvent* event)
{
    if (event->type() == QEvent::Quit) {
        if (!m_quit_triggered) {
            emit quitRequested();
            return true;
        }
    }
    return QObject::eventFilter(obj, event);
}
