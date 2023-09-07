#include "exportaddressescontroller.h"
#include "account.h"
#include "context.h"
#include "task.h"
#include "session.h"
#include "wallet.h"

#include <QFileDialog>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QTimer>

ExportAddressesController::ExportAddressesController(QObject *parent)
    : Controller(parent)
{
}

void ExportAddressesController::setAccount(Account *account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged();
}

void ExportAddressesController::save()
{
    Q_ASSERT(m_account);
    const auto context = m_account->context();
    const auto wallet = context->wallet();
    const auto network = wallet->network();
    const auto session = context->getOrCreateSession(network);
    const auto settings = session->settings();

    const auto now = QDateTime::currentDateTime();
    const auto account_name = m_account->name().isEmpty() ? qtTrId("id_main_account") : m_account->name();
    const QString suggestion =
            QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + QDir::separator() +
            wallet->name() + " - " + account_name + " - " + "addresses" + " - " +
            now.toString("yyyyMMddhhmmss") + ".csv";
    m_file_name = QFileDialog::getSaveFileName(nullptr, "Export to CSV", suggestion);
    if (m_file_name.isEmpty()) {
        emit saved();
        return;
    }

    m_lines.append("address,tx_count");

    QTimer::singleShot(1000, this, [=] {
        nextPage();
    });
}

void ExportAddressesController::nextPage()
{
    auto task = new GetAddressesTask(m_last_pointer, m_account);
    connect(task, &Task::finished, this, [=] {
        m_last_pointer = task->lastPointer();

        for (QJsonValue data : task->addresses()) {
            const auto object = data.toObject();
            const auto address = object.value("address").toString();
            const auto tx_count = object.value("tx_count").toInt();
            QStringList values;
            values.append(address);
            values.append(QString::number(tx_count));
            m_lines.append(values.join(","));
        }

        if (m_last_pointer == 1) {
            QFile file(m_file_name);
            bool result = file.open(QFile::WriteOnly);
            Q_ASSERT(result);

            QTextStream stream(&file);
            stream << m_lines.join("\n");
            emit saved();
        } else {
            QTimer::singleShot(100, this, [=] {
                nextPage();
            });
        }
    });
    m_dispatcher->add(task);
}
