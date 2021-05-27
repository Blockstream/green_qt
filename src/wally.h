#ifndef GREEN_WALLY_H
#define GREEN_WALLY_H

#include <QtQml>
#include <QObject>
#include <QStringList>
#include <QQmlListProperty>

class MnemonicEditorController;
class Word : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int index READ index CONSTANT)
    Q_PROPERTY(QString text READ text NOTIFY textChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)
    Q_PROPERTY(QStringList suggestions READ suggestions NOTIFY suggestionsChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    QML_ELEMENT
    QML_UNCREATABLE("Word is instanced by MnemonicEditorController.")
    MnemonicEditorController* const m_controller;
    const int m_index;
    QString m_text;
    bool m_valid{false};
    bool m_enabled{false};
    QStringList m_suggestions;
public:
    Word(MnemonicEditorController* controller, int index);
    int index() const { return m_index; }
    QString text() const { return m_text; }
    bool setText(QString text);
    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);
    bool valid() const { return m_valid; }
    QStringList suggestions() const { return m_suggestions; }

    Q_INVOKABLE QString update(const QString& text);

signals:
    void textChanged(const QString& text);
    void validChanged(bool valid);
    void enabledChanged(bool enabled);
    void suggestionsChanged();
};

class MnemonicEditorController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool autoComplete READ autoComplete WRITE setAutoComplete NOTIFY autoCompleteChanged)
    Q_PROPERTY(QQmlListProperty<Word> words READ words CONSTANT)
    Q_PROPERTY(bool password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QStringList mnemonic READ mnemonic NOTIFY mnemonicChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY mnemonicChanged)
    Q_PROPERTY(float progress READ progress NOTIFY mnemonicChanged)
    Q_PROPERTY(int mnemonicSize READ mnemonicSize WRITE setMnemonicSize NOTIFY mnemonicSizeChanged)
    QML_ELEMENT
    bool m_auto_complete{false};
    QList<Word*> m_words;
    bool m_valid{false};
    bool m_password{false};
public:
    MnemonicEditorController(QObject* parent = nullptr);
    bool autoComplete() const { return m_auto_complete; }
    void setAutoComplete(bool auto_complete);
    QQmlListProperty<Word> words();
    bool password() const { return m_password; }
    void setPassword(bool password);
    QString updateWord(int index, const QString& text);
    QString update(int index, const QString& text);
    QStringList mnemonic() const;
    bool valid() const { return m_valid; }
    float progress() const;
    void update();
    int mnemonicSize() { return m_mnemonic_size; };
    void setMnemonicSize(int size);
public slots:
    void clear();
signals:
    void passwordChanged(bool password);
    void mnemonicChanged();
    void autoCompleteChanged(bool auto_complete);
    void mnemonicSizeChanged(int mnemonicSize);
private:
    int m_mnemonic_size{12};
};

class MnemonicQuizWord : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString value READ value NOTIFY valueChanged)
    Q_PROPERTY(QStringList options READ options NOTIFY optionsChanged)
    Q_PROPERTY(bool enabled READ enabled NOTIFY enabledChanged)
    Q_PROPERTY(bool correct READ isCorrect NOTIFY correctChanged)
    QML_ELEMENT
public:
    MnemonicQuizWord(int index = 0, QObject* parent = nullptr);
    int index() const { return m_index; }
    QString value() const { return m_value; }
    void setValue(const QString& value);
    bool isCorrect() const { return m_correct; }
    void setCorrect(bool correct);
    QStringList options() const { return m_options; }
    void setOptions(const QStringList& options);
    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);
signals:
    void valueChanged(const QString& value);
    void correctChanged(bool correct);
    void optionsChanged(const QStringList& options);
    void enabledChanged(bool enabled);
private:
    const int m_index;
    QString m_value;
    bool m_correct{false};
    QStringList m_options;
    bool m_enabled{false};
};

#endif // GREEN_WALLY_H
