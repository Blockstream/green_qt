#ifndef GREEN_SIGNMESSAGERESOLVER_H
#define GREEN_SIGNMESSAGERESOLVER_H

#include "resolver.h"

class SignMessageResolver : public DeviceResolver
{
    Q_OBJECT
    QML_ELEMENT
public:
    SignMessageResolver(Handler* handler, const QJsonObject& result);
    void resolve() override;
private:
    const QString m_message;
    const QVector<uint32_t> m_path;
    const bool m_use_ae_protocol;
    const QByteArray m_ae_host_commitment;
    const QByteArray m_ae_host_entropy;
};

#endif // GREEN_SIGNMESSAGERESOLVER_H
