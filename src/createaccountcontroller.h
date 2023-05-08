#ifndef GREEN_CREATEACCOUNTCONTROLLER_H
#define GREEN_CREATEACCOUNTCONTROLLER_H

#include <QQmlEngine>

#include "controller.h"

class Account;

class MnemonicGenerator : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int size READ size WRITE setSize NOTIFY sizeChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic NOTIFY mnemonicChanged)
    QML_ELEMENT
public:
    MnemonicGenerator(QObject* parent = nullptr);

    int size() const { return m_size; }
    void setSize(int size);

    QStringList mnemonic() const { return m_mnemonic; }

public slots:
    void generate();

signals:
    void sizeChanged();
    void mnemonicChanged();

private:
    int m_size{12};
    QStringList m_mnemonic;
};

class CreateAccountController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QStringList recoveryMnemonic READ recoveryMnemonic WRITE setRecoveryMnemonic NOTIFY recoveryMnemonicChanged)
    Q_PROPERTY(QString recoveryXpub READ recoveryXpub WRITE setRecoveryXpub NOTIFY recoveryXpubChanged)
    Q_PROPERTY(Account* account READ account NOTIFY accountChanged)
    QML_ELEMENT

public:
    explicit CreateAccountController(QObject *parent = nullptr);
    QString name() const { return m_name; }
    void setName(const QString& name);
    QString type() const { return m_type; }
    void setType(const QString& type);
    QStringList recoveryMnemonic() const { return m_recovery_mnemonic; }
    void setRecoveryMnemonic(const QStringList& recovery_mnemonic);
    QString recoveryXpub() const { return m_recovery_xpub; }
    void setRecoveryXpub(const QString& recovery_xpub);

    Account* account() const { return m_account; }
    Q_INVOKABLE QStringList generateMnemonic(int size) const;

signals:
    void nameChanged();
    void typeChanged();
    void created(Account* account);
    void recoveryMnemonicChanged();
    void recoveryXpubChanged();
    void errorChanged(const QString& error);
    void accountChanged();

public slots:
    void create();

private:
    QString m_name;
    QString m_type;
    QStringList m_recovery_mnemonic;
    QString m_recovery_xpub;
    Account* m_account{nullptr};
};

#endif // GREEN_CREATEACCOUNTCONTROLLER_H
