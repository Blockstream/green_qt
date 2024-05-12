#ifndef GREEN_JADELOGINCONTROLLER_H
#define GREEN_JADELOGINCONTROLLER_H

#include "green.h"

#include <QObject>
#include <QtQml/qqml.h>

#include "controller.h"
#include "task.h"

class JadeDevice;

class JadeHttpRequest : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject params READ params CONSTANT)
    Q_PROPERTY(QStringList hosts READ hosts CONSTANT)
    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeHttpRequest(const QJsonObject& params, Session* session);
    QJsonObject params() const { return m_params; }
    QStringList hosts() const;
    QString path() const;
    bool busy() const { return m_busy; }
public slots:
    void accept(bool remember);
    void reject();
signals:
    void busyChanged();
    void accepted(bool remember);
    void rejected();
    void finished(const QJsonObject& response);
private:
    Session* const m_session;
    const QJsonObject m_params;
    bool m_busy{false};
};

class JadeController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(JadeDevice* device READ device WRITE setDevice NOTIFY deviceChanged)
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeController(QObject* parent = nullptr);
    JadeDevice* device() const { return m_device; }
    void setDevice(JadeDevice* device);
    Network* network() const { return m_network; }
    JadeHttpRequest* handleHttpRequest(const QJsonObject& params);
signals:
    void httpRequest(JadeHttpRequest* request);
    void disconnected();
    void deviceChanged();
    void setPin(QVariantMap info);

protected:
    JadeDevice* m_device{nullptr};
    Network* m_network{nullptr};
};

class JadeQRController : public JadeController
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeQRController(QObject* parent = nullptr);
public slots:
    void process(const QJsonObject& result);
signals:
    void resultEncoded(const QJsonObject& result);
private:
    void processJadePin(const QJsonObject& result);
};

class JadeSetupController : public JadeController
{
    Q_OBJECT
    QML_ELEMENT
public:
    JadeSetupController(QObject* parent = nullptr);
public slots:
    void setup(const QString& deployment);
signals:
    void setupFinished(Context* context);
};

class JadeSetupTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeSetupTask(JadeSetupController* controller);
private:
    void update() override;
private:
    JadeSetupController* const m_controller;
};

class JadeUnlockController : public JadeController
{
    Q_OBJECT
    Q_PROPERTY(bool remember READ remember WRITE setRemember NOTIFY rememberChanged)
    QML_ELEMENT
public:
    JadeUnlockController(QObject* parent = nullptr);
    bool remember() const { return m_remember; }
    void setRemember(bool remember);
    Network* network() const { return m_network; }
public slots:
    void unlock();
signals:
    void rememberChanged();
    void unlocked(Context* context);
    void invalidPin();
private:
    bool m_remember{false};
};

class JadeUnlockTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeUnlockTask(JadeUnlockController* controller);
private:
    void update() override;
private:
    JadeUnlockController* const m_controller;
};

class JadeIdentifyTask : public Task
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    JadeIdentifyTask(JadeController* controller);
private:
    void update() override;
private:
    JadeController* const m_controller;
};

#endif // GREEN_JADELOGINCONTROLLER_H
