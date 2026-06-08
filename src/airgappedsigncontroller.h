#ifndef BLOCKSTREAM_AIRGAPPEDSIGNCONTROLLER_H
#define BLOCKSTREAM_AIRGAPPEDSIGNCONTROLLER_H

#include "controller.h"
#include "green.h"

#include <QJsonObject>
#include <QString>
#include <QStringList>
#include <QUrl>

class AirgappedSignController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QJsonObject transaction READ transaction WRITE setTransaction NOTIFY transactionChanged)
    Q_PROPERTY(QString memo READ memo WRITE setMemo NOTIFY memoChanged)
    Q_PROPERTY(QStringList parts READ parts NOTIFY partsChanged)
    Q_PROPERTY(QString unsignedPsbt READ unsignedPsbt NOTIFY unsignedPsbtChanged)
    QML_ELEMENT
public:
    AirgappedSignController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    QJsonObject transaction() const { return m_transaction; }
    void setTransaction(const QJsonObject& transaction);
    QString memo() const { return m_memo; }
    void setMemo(const QString& memo);
    QStringList parts() const { return m_parts; }
    QString unsignedPsbt() const { return m_unsigned_psbt; }
    Q_INVOKABLE QString parsePsbtFile(const QUrl& url) const;
public slots:
    void exportPsbt();
    void savePsbtToFile();
    void importSignedPsbt(const QString& psbt);
signals:
    void accountChanged();
    void transactionChanged();
    void memoChanged();
    void partsChanged();
    void unsignedPsbtChanged();
    void failed(const QString& error);
    void transactionCompleted(AccountTransaction* transaction);
private:
    Account* m_account{nullptr};
    QJsonObject m_transaction;
    QString m_memo;
    QStringList m_parts;
    QString m_unsigned_psbt;
    QString m_error;
};

#endif // BLOCKSTREAM_AIRGAPPEDSIGNCONTROLLER_H
