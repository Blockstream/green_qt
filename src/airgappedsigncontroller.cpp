#include "account.h"
#include "airgappedsigncontroller.h"
#include "context.h"
#include "session.h"
#include "task.h"
#include "wallet.h"

#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QStandardPaths>
#include <QTextStream>
#include <QUrl>

AirgappedSignController::AirgappedSignController(QObject* parent)
    : Controller(parent)
{
}

void AirgappedSignController::setAccount(Account* account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
}

void AirgappedSignController::setTransaction(const QJsonObject& transaction)
{
    if (m_transaction == transaction) return;
    m_transaction = transaction;
    emit transactionChanged();
}

void AirgappedSignController::setMemo(const QString& memo)
{
    if (m_memo == memo) return;
    m_memo = memo;
    emit memoChanged();
}

void AirgappedSignController::exportPsbt()
{
    if (!m_account) return;
    setMonitor(new TaskGroupMonitor(this));

    const auto session = m_account->session();

    m_error.clear();
    m_parts.clear();
    m_unsigned_psbt.clear();
    emit partsChanged();
    emit unsignedPsbtChanged();

    auto group = new TaskGroup(this);
    auto psbt = new PsbtFromJsonTask(m_transaction, session);
    connect(psbt, &Task::failed, this, [=, this](const QString& error) {
        m_error = error;
    });
    connect(psbt, &Task::finished, this, [=, this] {
        m_unsigned_psbt = psbt->psbt();
        emit unsignedPsbtChanged();

        const QJsonObject details{
            { "ur_type", "crypto-psbt" },
            { "data", m_unsigned_psbt },
            { "max_fragment_len", 40 },
        };
        auto encode = new EncodeBCURTask(details, session);
        connect(encode, &Task::failed, this, [=, this](const QString& error) {
            m_error = error;
        });
        connect(encode, &Task::finished, this, [=, this] {
            const auto parts = encode->result().value("result").toObject().value("parts").toArray();
            m_parts.clear();
            for (const auto part : parts) {
                m_parts.append(part.toString());
            }
            emit partsChanged();
        });
        group->add(encode);
    });
    group->add(psbt);
    monitor()->add(group);
    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=, this] {
        emit failed(m_error);
    });
}

void AirgappedSignController::savePsbtToFile()
{
    if (m_unsigned_psbt.isEmpty()) return;

    const auto wallet = m_account->context()->wallet();
    const auto account_name = m_account->name().isEmpty() ? qtTrId("id_main_account") : m_account->name();
    const QString suggestion =
            QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
            wallet->name() + " - " + account_name + " - " +
            QDateTime::currentDateTime().toString("yyyyMMddhhmmss") + ".psbt";

    auto dialog = new QFileDialog(nullptr, "Save As", suggestion);
    dialog->setAcceptMode(QFileDialog::AcceptSave);
    dialog->setFileMode(QFileDialog::AnyFile);
    dialog->selectFile(suggestion);
    connect(dialog, &QFileDialog::fileSelected, this, [=, this](const QString& file) {
        if (file.isEmpty()) return;
        QFile out(file);
        if (out.open(QFile::WriteOnly)) {
            QTextStream stream(&out);
            stream << m_unsigned_psbt;
            out.close();
        }
    });
    connect(dialog, &QFileDialog::finished, dialog, &QFileDialog::deleteLater);
    dialog->open();
}

void AirgappedSignController::importSignedPsbt(const QString& psbt)
{
    if (!m_account) return;
    if (psbt.isEmpty()) {
        emit failed(QStringLiteral("Invalid PSBT"));
        return;
    }

    setMonitor(new TaskGroupMonitor(this));

    const auto session = m_account->session();

    QJsonObject details{
        { "psbt", psbt },
        { "simulate_only", false },
    };
    if (!m_memo.isEmpty()) {
        details.insert("memo", m_memo);
    }

    m_error.clear();

    auto group = new TaskGroup(this);
    auto broadcast = new BroadcastTransactionTask(details, session);
    connect(broadcast, &Task::failed, this, [=, this](const QString& error) {
        m_error = error;
    });
    connect(broadcast, &Task::finished, this, [=, this] {
        auto transaction = m_account->getOrCreateTransaction(broadcast->transaction());
        emit transactionCompleted(transaction);
    });
    group->add(broadcast);
    monitor()->add(group);
    dispatcher()->add(group);

    connect(group, &TaskGroup::failed, this, [=, this] {
        emit failed(m_error);
    });
}

QString AirgappedSignController::parsePsbtFile(const QUrl& url) const
{
    if (!url.isLocalFile()) return {};
    QFile file(url.toLocalFile());
    if (!file.open(QIODevice::ReadOnly)) return {};
    const auto data = file.readAll();
    file.close();

    static const QByteArray psbt_magic = QByteArray::fromHex("70736274ff");
    if (data.startsWith(psbt_magic)) {
        return QString::fromLatin1(data.toBase64());
    }

    auto text = QString::fromLatin1(data).trimmed();
    text.remove('\n').remove('\r');
    return text;
}
