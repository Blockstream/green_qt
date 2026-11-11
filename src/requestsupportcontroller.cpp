#include "analytics.h"
#include "requestsupportcontroller.h"
#include "util.h"

#include <QTemporaryFile>
#include <QtConcurrentRun>

#include <memory>

RequestSupportController::RequestSupportController(QObject* parent)
    : QObject(parent)
{
}

void RequestSupportController::submit(bool share_logs, const QJsonObject& data)
{
    if (!share_logs) {
        return createSupportRequest({}, data);
    }

    const auto file = std::make_shared<QTemporaryFile>();
    if (!file->open()) {
        emit failed("Failed to open log file");
        return;
    }

    const auto path = GetLogFilename();
    auto future = QtConcurrent::run([=] {
        QFile log(path);
        return log.open(QFile::ReadOnly) && RedactLog(log, *file) && file->flush();
    });

    future.then(this, [=, this](bool redacted) {
        if (!redacted) {
            emit failed("Failed to open log file");
            return;
        }
        file->reset();

        auto net = qmlEngine(this)->networkAccessManager();

        QUrlQuery query;
        query.addQueryItem("filename", QFileInfo(path).fileName());

        QUrl url("https://blockstream.zendesk.com/api/v2/uploads");
        url.setQuery(query);

        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "text/plain");

        auto reply = net->post(request, file.get());
        // the reply can outlive this controller, so it owns its cleanup and the upload device
        connect(reply, &QNetworkReply::finished, reply, [reply, file] { reply->deleteLater(); });

        connect(reply, &QNetworkReply::finished, this, [=, this] {
            if (reply->error() != QNetworkReply::NoError) {
                emit failed("Log upload failed (network error)");
                return;
            }

            const auto response = QJsonDocument::fromJson(reply->readAll());
            const auto token = response.object().value("upload").toObject().value("token").toString();

            if (token.isEmpty()) {
                emit failed("Log upload failed (server error)");
                return;
            }

            QJsonArray uploads;
            uploads.append(token);

            createSupportRequest(uploads, data);
        });
    });
}

void RequestSupportController::createSupportRequest(const QJsonArray& uploads, const QJsonObject& data)
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
    // Operating system: windows, macos, linux
    custom_fields.append(QJsonObject{
        { "id", "900008231623" },
#if defined(Q_OS_MACOS)
        { "value", "macos" }
#elif defined(Q_OS_WINDOWS)
        { "value", "windows" }
#elif defined(Q_OS_LINUX)
        { "value", "linux" }
#endif
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

    // Account type: 6167739898649; values: singlesig__green_, multisig_shield__green_, lightning__green_
    // Hardware Wallet: 900006375926; values jade, ledger_nano_s, ledger_nano_x, trezor_one, trezor_t

    QJsonObject requester{
        { "email", email }
    };
    QJsonObject comment{
        { "body", body },
        { "uploads", uploads }
    };
    QJsonObject request{
        { "requester", requester },
        { "subject", subject },
        { "comment", comment },
        { "custom_fields", custom_fields }
    };

    createSupportRequest(QJsonObject{
        { "request", request }
    });
}

void RequestSupportController::createSupportRequest(const QJsonObject& body)
{
    auto net = qmlEngine(this)->networkAccessManager();

    QUrl url("https://blockstream.zendesk.com/api/v2/requests");

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    auto reply = net->post(request, QJsonDocument(body).toJson(QJsonDocument::Compact));

    connect(reply, &QNetworkReply::finished, this, [=, this] {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            emit failed(reply->errorString());
            return;
        }

        const auto response = QJsonDocument::fromJson(reply->readAll());

        emit submitted(response.object());
    });
}
