#ifndef GREEN_WALLY_H
#define GREEN_WALLY_H

#include <QObject>
#include <QStringList>
#include <QQmlListProperty>

class Wally : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList wordlist READ wordlist CONSTANT)

public:
    static Wally* instance();

    QStringList wordlist() const;
};

class MnemonicEditorController;
class Word : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int index READ index CONSTANT)
    Q_PROPERTY(QString text READ text NOTIFY textChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)
    Q_PROPERTY(QStringList suggestions READ suggestions NOTIFY suggestionsChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(bool focus READ focus WRITE setFocus NOTIFY focusChanged)
    MnemonicEditorController* const m_controller;
    const int m_index;
    QString m_text;
    bool m_valid{false};
    bool m_enabled{false};
    QStringList m_suggestions;
    bool m_focus{false};
public:
    Word(MnemonicEditorController* controller, int index);
    int index() const { return m_index; }
    QString text() const { return m_text; }
    bool setText(QString text);
    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    bool valid() const { return m_valid; }
    QStringList suggestions() const { return m_suggestions; }
    bool focus() const { return m_focus; }
    void setFocus(bool focus);

    Q_INVOKABLE QString update(const QString& text);

signals:
    void textChanged(const QString& text);
    void validChanged(bool valid);
    void enabledChanged(bool enabled);
    void suggestionsChanged();
    void focusChanged(bool focus);
};

class MnemonicEditorController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<Word> words READ words CONSTANT)
    Q_PROPERTY(bool password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY mnemonicChanged)
    Q_PROPERTY(float progress READ progress NOTIFY mnemonicChanged)
    QList<Word*> m_words;
    bool m_valid{false};
    bool m_password{false};
public:
    MnemonicEditorController(QObject* parent = nullptr);
    QQmlListProperty<Word> words() {
        return QQmlListProperty<Word>(this, m_words);
    }
    bool password() const { return m_password; }
    void setPassword(bool password);
    QString updateWord(int index, const QString& text);
    QString update(int index, const QString& text);
    QStringList mnemonic() const;
    bool valid() const { return m_valid; }
    float progress() const;

    void update();

public slots:
    void clear();
signals:
    void passwordChanged(bool password);
    void mnemonicChanged();
};

#endif // GREEN_WALLY_H
