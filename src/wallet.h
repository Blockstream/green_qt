#ifndef GREEN_WALLET_H
#define GREEN_WALLET_H

#include <QObject>
#include <QThread>

struct GA_session;

class Wallet : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)

public:
    explicit Wallet(QObject *parent = nullptr);
    virtual ~Wallet();

    bool isConnected() const { return m_connected; }

signals:
    void connectedChanged(bool connected);

public slots:
    void connect();

private:
    QThread* m_thread{new QThread};
    QObject* m_context{new QObject};
    GA_session* m_session{nullptr};
    bool m_connected{false};
};

#endif // GREEN_WALLET_H
