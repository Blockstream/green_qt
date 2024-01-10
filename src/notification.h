#ifndef GREEN_NOTIFICATION_H
#define GREEN_NOTIFICATION_H

#include "green.h"
#include "controller.h"

#include <QObject>
#include <QStandardItemModel>
#include <QQmlEngine>

class Notification : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context CONSTANT)
    Q_PROPERTY(Level level READ level NOTIFY levelChanged)
    Q_PROPERTY(bool seen READ seen NOTIFY seenChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool dismissable READ dismissable NOTIFY dismissableChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum Level {
        Info,
        Notice,
        Alert,
    }
    Q_ENUMS(Level);
    explicit Notification(Context* context);
    Context* context() const { return m_context; }
    Level level() const { return m_level; }
    void setLevel(Level level);
    bool seen() const { return m_seen; }
    void setSeen(bool seen);
    bool busy() const { return m_busy; }
    void setBusy(bool busy);
    bool dismissable() const { return m_dismissable; }
    void setDismissable(bool dismissable);
public slots:
    void dismiss();
signals:
    void levelChanged();
    void seenChanged();
    void busyChanged();
    void dismissableChanged();
protected:
    Context* const m_context;
    Level m_level{Info};
    bool m_seen{false};
    bool m_busy{false};
    bool m_dismissable{false};
};

class NotificationsController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QStandardItemModel* model READ model CONSTANT)
    QML_ELEMENT
public:
    NotificationsController(QObject* parent = nullptr);
    QStandardItemModel* model() const { return m_model; }
    void reset();
public slots:
    void updateSeen();
private:
    QStandardItemModel* const m_model;
    QMap<Notification*, QStandardItem*> m_items;
};
#endif // GREEN_NOTIFICATION_H
