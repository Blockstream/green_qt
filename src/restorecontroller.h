#ifndef GREEN_RESTORECONTROLLER_H
#define GREEN_RESTORECONTROLLER_H

#include <QtQml>
#include <QObject>

class Network;
class Wallet;

class RestoreController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Network* network READ network WRITE setNetwork NOTIFY networkChanged)
    Q_PROPERTY(QString defaultName READ defaultName NOTIFY defaultNameChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(Wallet* wallet READ wallet NOTIFY walletChanged)
    QML_ELEMENT
public:
    explicit RestoreController(QObject *parent = nullptr);
    Network* network() const;
    void setNetwork(Network* network);
    QString defaultName() const;
    QString name() const;
    void setName(const QString& name);
    Wallet* wallet() const;
public slots:
    void setPin(const QByteArray& pin);
    void restore();
signals:
    void networkChanged(Network* network);
    void defaultNameChanged(const QString& name);
    void nameChanged(const QString& name);
    void walletChanged(Wallet* wallet);
    void finished();
    void pinSet();
private:
    Network* m_network{nullptr};
    QString m_name;
    QString m_default_name;
    Wallet* m_wallet{nullptr};
};

#endif // GREEN_RESTORECONTROLLER_H
