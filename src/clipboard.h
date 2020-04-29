#ifndef GREEN_CLIPBOARD_H
#define GREEN_CLIPBOARD_H

#include <QObject>

class Clipboard : public QObject
{
    Q_OBJECT
    Clipboard(QObject* parent = nullptr);
public:
    static Clipboard* instance();
    Q_INVOKABLE void copy(const QString& data);
};

#endif // GREEN_CLIPBOARD_H
