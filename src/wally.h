#ifndef GREEN_WALLY_H
#define GREEN_WALLY_H

#include <QObject>
#include <QStringList>

class Wally : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList wordlist READ wordlist CONSTANT)

public:
    static Wally* instance();

    QStringList wordlist() const;
};

#endif // GREEN_WALLY_H
