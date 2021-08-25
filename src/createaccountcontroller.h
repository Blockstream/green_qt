#ifndef GREEN_CREATEACCOUNTCONTROLLER_H
#define GREEN_CREATEACCOUNTCONTROLLER_H

#include "controller.h"

#include <QtQml>

class CreateAccountController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QStringList recoveryMnemonic READ recoveryMnemonic NOTIFY recoveryMnemonicChanged)
    QML_ELEMENT
public:
    explicit CreateAccountController(QObject *parent = nullptr);
    QString name() const { return m_name; }
    void setName(const QString& name);
    QString type() const { return m_type; }
    void setType(const QString& type);
    QStringList recoveryMnemonic() const { return m_recovery_mnemonic; }
signals:
    void nameChanged(const QString& name);
    void typeChanged(const QString& type);
    void created(Handler* handler);
    void recoveryMnemonicChanged(const QStringList& recovery_mnemonic);
public slots:
    void create();
private:
    QString m_name;
    QString m_type;
    QStringList m_recovery_mnemonic;
};

#endif // GREEN_CREATEACCOUNTCONTROLLER_H
