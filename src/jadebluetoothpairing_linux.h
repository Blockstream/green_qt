#ifndef GREEN_JADEBLUETOOTHPAIRING_LINUX_H
#define GREEN_JADEBLUETOOTHPAIRING_LINUX_H

#include <QtGlobal>

#ifdef Q_OS_LINUX
#include <QBluetoothAddress>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QObject>

// Bonds a Jade through BlueZ, confirming the code it shows. Qt registers no
// agent, so without one from the desktop BlueZ pairs Just Works, which Jade
// refuses: it requires numeric comparison.
class JadeBluetoothPairing : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.bluez.Agent1")
public:
    JadeBluetoothPairing(const QBluetoothAddress& address, QObject* parent = nullptr);
    ~JadeBluetoothPairing();
    void start();
public slots:
    void confirmPin(bool match);
    // org.bluez.Agent1, named as BlueZ calls them
    void Release() {}
    void Cancel();
    void RequestConfirmation(const QDBusObjectPath& device, uint passkey, const QDBusMessage& message);
signals:
    void pinRequested(const QString& pin);
    void finished(bool paired, const QBluetoothAddress& address);
private:
    void reply(const char* error);
    void release();
    const QBluetoothAddress m_address;
    QDBusMessage m_request;
    bool m_released{false};
};
#endif // Q_OS_LINUX

#endif // GREEN_JADEBLUETOOTHPAIRING_LINUX_H
