#ifndef GREEN_REQUESTSUPPORTCONTROLLER_H
#define GREEN_REQUESTSUPPORTCONTROLLER_H

#include <QObject>
#include <QtQml>

class RequestSupportController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    RequestSupportController(QObject* parent = nullptr);
public slots:
    void submit(bool share_logs, const QJsonObject& data);
signals:
    void failed(const QString& error);
    void submitted(const QJsonObject& response);
private:
    void createSupportRequest(const QJsonArray& uploads, const QJsonObject& data);
    void createSupportRequest(const QJsonObject& body);
};

#endif // GREEN_REQUESTSUPPORTCONTROLLER_H
