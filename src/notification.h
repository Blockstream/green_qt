#ifndef GREEN_NOTIFICATION_H
#define GREEN_NOTIFICATION_H

#include "green.h"
#include "controller.h"

#include <QObject>
#include <QSortFilterProxyModel>
#include <QStandardItemModel>
#include <QQmlEngine>

class Notification : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Level level READ level NOTIFY levelChanged)
    Q_PROPERTY(bool seen READ seen NOTIFY seenChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool dismissable READ dismissable NOTIFY dismissableChanged)
    Q_PROPERTY(bool dismissed READ dismissed NOTIFY dismissedChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    enum Level {
        Info,
        Notice,
        Alert,
    };
    Q_ENUMS(Level);
    explicit Notification(QObject* parent);
    Level level() const { return m_level; }
    void setLevel(Level level);
    bool seen() const { return m_seen; }
    void setSeen(bool seen);
    bool busy() const { return m_busy; }
    void setBusy(bool busy);
    bool dismissable() const { return m_dismissable; }
    void setDismissable(bool dismissable);
    bool dismissed() const { return m_dismissed; }
public slots:
    void dismiss();
signals:
    void levelChanged();
    void seenChanged();
    void busyChanged();
    void dismissableChanged();
    void dismissedChanged();
protected:
    Level m_level{Info};
    bool m_seen{false};
    bool m_busy{false};
    bool m_dismissable{false};
    bool m_dismissed{false};
};

class ContextNotification : public Notification
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit ContextNotification(Context* context);
    Context* context() const { return m_context; }
protected:
    Context* const m_context;
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

class NotificationsModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QStandardItemModel* source READ source WRITE setSource NOTIFY sourceChanged)
    QML_ELEMENT
public:
    NotificationsModel(QObject* parent = nullptr);
    QStandardItemModel* source() const { return m_source; }
    void setSource(QStandardItemModel* source);
signals:
    void sourceChanged();
private:
    QStandardItemModel* m_source{nullptr};
};

class NetworkNotification : public ContextNotification
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit NetworkNotification(Network* network, Context* context);
    Network* network() const { return m_network; }
protected:
    Network* const m_network;
};

class SystemNotification : public NetworkNotification
{
    Q_OBJECT
    Q_PROPERTY(QString message READ message CONSTANT)
    Q_PROPERTY(bool accepted READ accepted NOTIFY acceptedChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    explicit SystemNotification(const QString& message, Network* network, Context* context);
    QString message() const { return m_message; }
    bool accepted() const { return m_accepted; }
    void setAccepted(bool accepted);
public slots:
    void accept(TaskGroupMonitor* monitor);
signals:
    void acceptedChanged();
protected:
    QString const m_message;
    bool m_accepted{false};
};

class TwoFactorResetNotification : public NetworkNotification
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    TwoFactorResetNotification(Network* network, Context* context);
};

#endif // GREEN_NOTIFICATION_H
