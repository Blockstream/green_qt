#include "account.h"
#include "controllers/exportaddressescontroller.h"
#include "handlers/getaddresseshandler.h"
#include "resolver.h"

#include <QFileDialog>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QTimer>

ExportAddressesController::ExportAddressesController(QObject *parent) : QObject(parent)
{
}

void ExportAddressesController::setAccount(Account *account)
{
    if (m_account == account) return;
    m_account = account;
    emit accountChanged(m_account);
}

void ExportAddressesController::save()
{
    Q_ASSERT(m_account);
    auto wallet = m_account->wallet();
    auto settings = wallet->settings();

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
    auto handler = new GetAddressesHandler(m_last_pointer, m_account);
    QObject::connect(handler, &Handler::done, this, [=] {
        handler->deleteLater();
        m_last_pointer = handler->lastPointer();

        for (QJsonValue data : handler->addresses()) {
            const auto object = data.toObject();
            qDebug() << object;
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
    connect(handler, &Handler::resolver, this, [](Resolver* resolver) {
        resolver->resolve();
    });
    handler->exec();
}
