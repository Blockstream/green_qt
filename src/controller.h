#ifndef GREEN_CONTROLLER_H
#define GREEN_CONTROLLER_H

#include "controllers/abstractcontroller.h"
#include "green.h"

#include <QQmlEngine>

Q_MOC_INCLUDE("resolver.h")
Q_MOC_INCLUDE("task.h")
Q_MOC_INCLUDE("wallet.h")

class Controller : public AbstractController
{
    Q_OBJECT
    Q_PROPERTY(Context* context READ context WRITE setContext NOTIFY contextChanged)
    Q_PROPERTY(TaskGroupMonitor* monitor READ monitor NOTIFY monitorChanged)
    QML_ELEMENT

public:
    explicit Controller(QObject* parent = nullptr);

    Context* context() const { return m_context; }
    void setContext(Context* context);

    TaskDispatcher* dispatcher() const;
    TaskGroupMonitor* monitor() const { return m_monitor; }
    void setMonitor(TaskGroupMonitor* monitor);

public slots:
    void changeSettings(const QJsonObject& data);
    void changeSessionSettings(Session* session, const QJsonObject& data);
    void setRecoveryEmail(const QString& email);
    void deleteWallet();
    void disableAllPins();
    void changePin(const QString& pin);

    bool setAccountName(Account* account, QString name, bool active_focus);
    void setAccountHidden(Account *account, bool hidden);

signals:
    void contextChanged();
    void monitorChanged();
    void resolver(Resolver* resolver);
    void finished();

protected:
    Context* m_context{nullptr};
    TaskGroupMonitor* m_monitor{nullptr};
};

class Asset;
class AddressValidationController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(QString input READ input WRITE setInput NOTIFY inputChanged)
    Q_PROPERTY(QQmlListProperty<Network> networks READ networks NOTIFY updated)
    Q_PROPERTY(QString address READ address NOTIFY updated)
    Q_PROPERTY(QVariantMap amount READ amount NOTIFY updated)
    Q_PROPERTY(QVariantMap bip21 READ bip21 NOTIFY updated)
    Q_PROPERTY(Asset* asset READ asset NOTIFY updated)
    Q_PROPERTY(QStringList errors READ errors NOTIFY updated)
    QML_ELEMENT
public:
    AddressValidationController(QObject* parent = nullptr);
    QString input() const { return m_input; }
    void setInput(const QString& input);
    QQmlListProperty<Network> networks();
    QString address() const { return m_address; }
    QVariantMap amount() const { return m_amount; }
    QVariantMap bip21() const { return m_bip21; }
    Asset* asset() const { return m_asset; }
    QStringList errors() const { return m_errors; }
signals:
    void inputChanged();
    void updated();
private:
    void update();
private:
    QString m_input;
    QJsonArray m_results;
    QList<Network*> m_networks;
    QString m_address;
    QVariantMap m_amount;
    QVariantMap m_bip21;
    Asset* m_asset{nullptr};
    QStringList m_errors;
};

#endif // GREEN_CONTROLLER_H
