#ifndef GREEN_SIGNMESSAGECONTROLLER_H
#define GREEN_SIGNMESSAGECONTROLLER_H

#include "../controller.h"

#include <QQmlEngine>

class SignMessageController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Address* address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(QString message READ message WRITE setMessage NOTIFY messageChanged)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    Q_PROPERTY(QString signature READ signature NOTIFY signatureChanged)
    QML_ELEMENT
public:
    explicit SignMessageController(QObject* parent = nullptr);
    Address* address() const { return m_address; }
    void setAddress(Address* address);
    QString message() const { return m_message; }
    void setMessage(const QString& message);
    bool isValid() const { return m_valid; }
    QString signature() const { return m_signature; }
public slots:
    void sign();
signals:
    void addressChanged();
    void messageChanged();
    void validChanged();
    void signatureChanged();
    void cleared();
    void accepted(const QString& signature);
    void rejected();
private:
    void updateValid();
    void setSignature(const QString& signature);
    void clearSignature();
private:
    Address* m_address{nullptr};
    QString m_message;
    bool m_valid{false};
    QString m_signature;
};

#endif // GREEN_SIGNMESSAGECONTROLLER_H
