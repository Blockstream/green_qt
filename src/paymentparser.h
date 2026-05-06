#ifndef BLOCKSTREAM_PAYMENT_PARSER_H
#define BLOCKSTREAM_PAYMENT_PARSER_H

#include "green.h"

#include <QObject>
#include <QQmlEngine>

class RecipientParserPrivate;
class RecipientParser : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString input READ input WRITE setInput NOTIFY inputChanged)
    Q_PROPERTY(QVariantMap data READ data WRITE setData NOTIFY dataChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(QVariantMap recipient READ recipient NOTIFY recipientChanged)
    QML_ELEMENT
public:
    RecipientParser(QObject* parent = nullptr);
    ~RecipientParser();
    QString input() const;
    void setInput(const QString& input);
    QVariantMap data() const;
    void setData(const QVariantMap& data);
    bool isBusy() const;
    QVariantMap recipient() const;
signals:
    void inputChanged();
    void dataChanged();
    void busyChanged();
    void recipientChanged();
protected:
    void invalidate();
    void update();
    void timerEvent(QTimerEvent *event);
private:
    RecipientParserPrivate* const d;
};

#endif // BLOCKSTREAM_PAYMENT_PARSER_H
