#ifndef GREEN_CLIPBOARD_H
#define GREEN_CLIPBOARD_H

#include <QtQml>
#include <QObject>

class Clipboard : public QObject
{
    Q_OBJECT
public:
    static Clipboard* instance();
    Q_INVOKABLE void copy(const QString& data);
private:
    Clipboard(QObject* parent = nullptr);
};

#endif // GREEN_CLIPBOARD_H
