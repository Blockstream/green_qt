#ifndef GREEN_CLIPBOARD_H
#define GREEN_CLIPBOARD_H

#include <QtQml>
#include <QObject>
#include <QString>

class Clipboard : public QObject
{
    Q_OBJECT
public:
    static Clipboard* instance();
    Q_INVOKABLE void copy(const QString& data); // NOLINT(build/include_what_you_use)
private:
    Clipboard(QObject* parent = nullptr);
};

#endif // GREEN_CLIPBOARD_H
