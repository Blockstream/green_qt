#ifndef GREEN_HANDLER_H
#define GREEN_HANDLER_H

#include <QtQml>
#include <QJsonObject>

struct GA_session;
struct GA_auth_handler;

class Resolver;
class TwoFactorResolver;
class Wallet;

class Handler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Wallet* wallet READ wallet CONSTANT)
    Q_PROPERTY(QJsonObject result READ result NOTIFY resultChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Handler is an abstract base class.")
    Q_ENUMS(Status)
public:
    Handler(Wallet* wallet);
    virtual ~Handler();
    Wallet* wallet() const { return m_wallet; }
    void exec();
    const QJsonObject& result() const { Q_ASSERT(!m_result.empty()); return m_result; }
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
private:
    virtual void init(GA_session* session) = 0;
    void step();
    Resolver* createResolver(const QJsonObject& result);
    void setResult(const QJsonObject &result);
protected:
    GA_auth_handler* m_handler{nullptr};
    QJsonObject m_result;
private:
    TwoFactorResolver* m_two_factor_resolver{nullptr};
public:
    Wallet* const m_wallet;
};

#endif // GREEN_HANDLER_H
