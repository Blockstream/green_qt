#ifndef GREEN_BCURCONTROLLER_H
#define GREEN_BCURCONTROLLER_H

#include "../controller.h"

#include <QQmlEngine>
#include <QJsonObject>
#include <QSet>
#include <QQueue>

class DecodeBCURTask;
class BCURController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged FINAL)
    QML_ELEMENT
public:
    BCURController(QObject* parent = nullptr);
    int progress() const { return m_progress; }
    void setProgress(int progress);
public slots:
    void process(const QString& data);
signals:
    void progressChanged();
    void resultDecoded(const QJsonObject& result);
    void dataDiscarded(const QString& data);
private:
    void next();
private:
    QJsonObject m_result;
    QSet<QString> m_seen;
    QQueue<QString> m_pending;
    DecodeBCURTask* m_task{nullptr};
    int m_progress{0};
};

#endif // GREEN_BCURCONTROLLER_H
