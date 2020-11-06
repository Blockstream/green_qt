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
};

#endif // GREEN_SIGNMESSAGERESOLVER_H
