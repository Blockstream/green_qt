#ifndef GREEN_JADEBLUETOOTHPAIRING_WIN_H
#define GREEN_JADEBLUETOOTHPAIRING_WIN_H

#include <QtGlobal>

#ifdef Q_OS_WIN
#include <QBluetoothAddress>
#include <QObject>

#include <memory>

// Bonds a Jade through WinRT custom pairing, confirming the code it shows.
// QBluetoothLocalDevice::requestPairing only offers ConfirmOnly, so Windows
// pairs Just Works and the key it stores is refused by Jade's authenticated
// characteristics.
class JadeBluetoothPairing : public QObject
{
    Q_OBJECT
public:
    JadeBluetoothPairing(const QBluetoothAddress& address, QObject* parent = nullptr);
    ~JadeBluetoothPairing();
    void start();
public slots:
    void confirmPin(bool match);
signals:
    void pinRequested(const QString& pin);
    void finished(bool paired, const QBluetoothAddress& address);
private:
    struct Private;
    const std::shared_ptr<Private> d;
};
#endif // Q_OS_WIN

#endif // GREEN_JADEBLUETOOTHPAIRING_WIN_H
