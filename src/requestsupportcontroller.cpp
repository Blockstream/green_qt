#include "analytics.h"
#include "httprequestactivity.h"
#include "httpmanager.h"
#include "requestsupportcontroller.h"

#include <QFile>

extern QFile g_log_file;

namespace {

QString GetLogs()
{
    QFile file(g_log_file.fileName());
    auto rc = file.open(QIODevice::ReadOnly);
    if (!rc) return "failed to open log file";
    const auto content = QString::fromUtf8(file.readAll());
    const auto count = qMin(8000, content.size());
    return content.last(count);
}

} // namespace

RequestSupportController::RequestSupportController(QObject* parent)
    : QObject(parent)
{
}

void RequestSupportController::submit(bool share_logs, const QJsonObject& data)
{
    const auto type = data.value("type").toString();
    const auto subject = data.value("subject").toString();
    const auto email = data.value("email").toString();
    const auto body = data.value("body").toString();

    QJsonArray custom_fields = data.value("custom_fields").toArray();
    // ticket type: incident, feedback, store_review
    custom_fields.append(QJsonObject{
        { "id", "42575138597145" },
        { "value", type }
    });
    // Product
    custom_fields.append(QJsonObject{
        { "id", "900003758323" },
        { "value", "green" }
    });
    // App version
    custom_fields.append(QJsonObject{
        { "id", "900009625166" },
        { "value", QCoreApplication::applicationVersion() }
    });
    // Operating system: android, ios, windows, macos, linux
    custom_fields.append(QJsonObject{
        { "id", "900008231623" },
        { "value", QSysInfo::productType() }
    });
    // Operating system version
    custom_fields.append(QJsonObject{
        { "id", "42657567831833" },
        { "value", QSysInfo::productVersion() }
    });
    // Countly id
    custom_fields.append(QJsonObject{
        { "id", "42306364242073" },
        { "value", Analytics::instance()->countlyId() }
    });
    if (share_logs) {
        // Logs
        custom_fields.append(QJsonObject{
            { "id", "21409433258649" },
            { "value", GetLogs() }
        });
    }

    // Account type: 6167739898649; values: singlesig__green_, multisig_shield__green_, lightning__green_
    // Hardware Wallet: 900006375926; values jade, ledger_nano_s, ledger_nano_x, trezor_one, trezor_t

    QJsonObject requester{
        { "email", email }
    };
    QJsonObject comment{
        { "body", body }
    };
    QJsonObject request{
        { "requester", requester },
        { "subject", subject },
        { "comment", comment },
        { "custom_fields", custom_fields }
    };

    auto req = new HttpRequestActivity(this);
    req->setMethod("POST");
    req->addUrl("https://blockstream.zendesk.com/api/v2/requests");
    req->addHeader("Content-Type", "application/json");
    req->setData(QJsonObject{
        { "request", request }
    });
    connect(req, &HttpRequestActivity::failed, this, [=] {
        emit failed("Unknown error");
    });
    connect(req, &HttpRequestActivity::finished, this, [=] {
        const auto error = req->response().value("error").toString();
        if (error.isEmpty() || error == "Created") {
            const auto body = QJsonDocument::fromJson(req->response().value("body").toString().toUtf8());
            emit submitted(body.object());
        } else {
            emit failed(error);
        }
    });

    HttpManager::instance()->exec(req);
}
