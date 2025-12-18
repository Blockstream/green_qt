#ifndef GREEN_RESTORECONTROLLER_H
#define GREEN_RESTORECONTROLLER_H

#include "green.h"

#include <QObject>
#include <QQmlEngine>

#include "controller.h"
#include "task.h"

class RestoreController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet WRITE setWallet NOTIFY walletChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic WRITE setMnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    QML_ELEMENT

public:
    explicit RestoreController(QObject *parent = nullptr);
    QStringList mnemonic() const { return m_mnemonic; }
    void setMnemonic(const QStringList& mnemonic);
    QString password() const { return m_password; }
    void setPassword(const QString& password);
    Wallet* wallet() const { return m_wallet; }
    void setWallet(Wallet* wallet);
public slots:
    void restore(const QString& deployment);
signals:
    void walletChanged();
    void mnemonicChanged();
    void passwordChanged();
    void walletRestored(Wallet* wallet);
    void restoreFinished(Context* context);
    void alreadyRestored(Wallet* wallet);
    void mismatch();
private:
    QStringList m_mnemonic;
    QString m_password;
    Wallet* m_wallet{nullptr};
    TaskGroup* check(Network* network);
    QList<Account*> m_accounts;
};

#endif // GREEN_RESTORECONTROLLER_H
