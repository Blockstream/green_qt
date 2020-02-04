#ifndef GREEN_WALLY_H
#define GREEN_WALLY_H

#include <QObject>
#include <QStringList>
#include <QValidator>

class Wally : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList wordlist READ wordlist CONSTANT)

public:
    static Wally* instance();

    QStringList wordlist() const;
};

class WordValidator : public QValidator
{
public:
    WordValidator(QObject* parent = nullptr);
    virtual State validate(QString &input, int &) const;
};

#endif // GREEN_WALLY_H
