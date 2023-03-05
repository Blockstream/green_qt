#ifndef GREEN_HANDLER_H
#define GREEN_HANDLER_H

#include <QJsonObject>
#include <QObject>
#include <QtQml>

class Resolver;
class TwoFactorResolver;
class Session;

QT_FORWARD_DECLARE_STRUCT(GA_session)
QT_FORWARD_DECLARE_STRUCT(GA_auth_handler)

#include <QFutureWatcher>

class Handler : public QFutureWatcher<void>
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Handler is an abstract base class.")
public:
    Handler(Session* Session);
    virtual ~Handler();
    Session* session() const { return m_session; }
    void exec();
    void fail();
    const QJsonObject& result() const;
public slots:
    void request(const QByteArray& method);
    void resolve(const QJsonObject& data);
    void resolve(const QByteArray& data);
signals:
    void resultChanged(const QJsonObject& result);
    void done();
    void error();
    void requestCode();
    void invalidCode();
    void resolver(Resolver* resolver);
    void deviceRequested();
private:
    virtual void call(GA_session* session, GA_auth_handler** auth_handler) = 0;
    void step();
    void handleResolveCode(const QJsonObject& result);
    void setResult(const QJsonObject &result);
private:
    bool m_already_exec{false};
    Session* const m_session;
    GA_auth_handler* m_auth_handler{nullptr};
    TwoFactorResolver* m_two_factor_resolver{nullptr};
    QJsonObject m_result;
    QJsonObject m_error_details;
};

class GetSubAccountsHandler : public Handler
{
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    GetSubAccountsHandler(Session* session, bool refresh);
    QJsonArray subAccounts() const;
private:
    const bool m_refresh;
};

class EncryptWithPinHandler : public Handler
{
    const QJsonObject m_plaintext;
    const QString m_pin;
    QByteArray m_pin_data;
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
public:
    EncryptWithPinHandler(const QJsonObject& plaintext, const QString& pin, Session* session);
    QByteArray pinData() const;
};

class GetCredentialsHandler : public Handler
{
    Q_OBJECT
    Q_PROPERTY(QString mnemonic READ mnemonic CONSTANT)
public:
    GetCredentialsHandler(Session* session);
    QJsonObject credentials() const;
    QString mnemonic() const;
protected:
    void call(GA_session* session, GA_auth_handler** auth_handler) override;
};

#endif // GREEN_HANDLER_H
