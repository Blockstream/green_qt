#include "application.h"
#include "config.h"
#include "util.h"
#include "walletmanager.h"

#include <QtConcurrentRun>
#include <QDir>
#include <QDirIterator>
#include <QFileOpenEvent>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QUrl>
#include <QWindow>

#include <ZXing/BitMatrix.h>
#include <ZXing/ReadBarcode.h>
#include <ZXing/MultiFormatWriter.h>

Application::Application(int& argc, char** argv)
    : QApplication(argc, argv)
{
}

void Application::raise()
{
    for (QWindow* window : allWindows()) {
        // windows: does not allow a window to be brought to front while the user has focus on another window
        // instead, Windows flashes the taskbar button of the window to notify the user

        // mac: if the primary window is minimized, it is restored. It is background, it is brough to foreground
        if (window->visibility() == QWindow::Hidden || window->visibility() == QWindow::Minimized) {
            window->setVisibility(QWindow::AutomaticVisibility);
        }
        window->requestActivate();
        window->raise();
    }
}

bool Application::event(QEvent* event)
{
    if (event->type() == QEvent::FileOpen) {
        auto open_event = static_cast<QFileOpenEvent*>(event);
        WalletManager::instance()->setOpenUrl(open_event->url().toString());
        raise();
    }
    return QApplication::event(event);
}

ZXingDetector::ZXingDetector(QObject *parent)
    : QObject(parent)
{
}

void ZXingDetector::setVideoSink(QVideoSink* video_sink)
{
    if (m_video_sink == video_sink) return;
    if (m_video_sink) {
        disconnect(m_video_sink, &QVideoSink::videoFrameChanged, this, &ZXingDetector::videoFrameChanged);
    }
    m_video_sink = video_sink;
    if (m_video_sink) {
        connect(m_video_sink, &QVideoSink::videoFrameChanged, this, &ZXingDetector::videoFrameChanged);
    }
}

void ZXingDetector::videoFrameChanged(const QVideoFrame& frame)
{
    // discard frames while a frame is being processed
    if (m_watcher) return;

    auto current = m_results;
    m_watcher = new QFutureWatcher<QVariantList>(this);
    m_watcher->setFuture(QtConcurrent::run([=] {
        auto results = current;
        auto image = frame.toImage().convertedTo(QImage::Format_Grayscale8);
        ZXing::ReaderOptions options;
        options.setFormats(ZXing::BarcodeFormat::QRCode);
        options.setTryHarder(true);
        options.setTryDownscale(true);

        // increase age remove old results
        for (auto i = results.begin(); i != results.end();) {
            auto v = i->toMap();
            auto age = v.value("age").toInt();
            if (age > 5) {
                i = results.erase(i);
            } else {
                v["age"] = age + 1;
                *i = v;
                i ++;
            }
        }

        auto barcodes = ZXing::ReadBarcodes(ZXing::ImageView(image.bits(), image.width(), image.height(), ZXing::ImageFormat::Lum), options);
        for (const auto barcode : barcodes) {
            const auto text = QString::fromStdString(barcode.text());
            QVariantList points;
            for (const auto point : barcode.position()) {
                points.append(QVariantMap{{ "x", point.x }, { "y", point.y }});
            }
            // search and remove from old results
            for (auto i = results.begin(); i != results.end();) {
                auto v = i->toMap();
                if (v.value("text") == text) {
                    results.erase(i);
                    break;
                } else {
                    i ++;
                }
            }
            results.append(QVariantMap{
                { "age", 0 },
                { "text", text },
                { "points", points }
            });
        }
        return results;
    }));

    connect(m_watcher, &QFutureWatcher<QVariantList>::finished, this, [=] {
        m_results = m_watcher->result();
        emit resultsChanged();
        delete m_watcher;
        m_watcher = nullptr;
    });
}

ZXingImageProvider::ZXingImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage ZXingImageProvider::requestImage(const QString& id, QSize* size, const QSize& requested_size)
{
    const auto contents = QUrl::fromPercentEncoding(id.toUtf8());
    if (requested_size.isValid()) {
        *size = requested_size;
    } else {
        *size = QSize(512, 512);
    }
    if (contents.isEmpty()) {
        QImage image(*size, QImage::Format_RGB32);
        image.fill(0x0);
        return image;
    } else {
        ZXing::MultiFormatWriter writer(ZXing::BarcodeFormat::QRCode);
        writer.setEccLevel(7);
        writer.setEncoding(ZXing::CharacterSet::UTF8);
        writer.setMargin(0);
        const auto bitmatrix = writer.encode(contents.toStdString(), size->width(), size->height());

        QImage image(*size, QImage::Format_RGB32);
        for (int x = 0; x < size->width(); x++) {
            for (int y = 0; y < size->height(); y++) {
                image.setPixel(x, y, bitmatrix.get(x, y) ? 0xFF000000 : 0xFFFFFFFF);
            }
        }
        return image;
    }
}

ApplicationController::ApplicationController(QObject* parent)
    : QObject(parent)
{
    qApp->installEventFilter(this);
}

ApplicationController::~ApplicationController()
{
    qApp->removeEventFilter(this);
}

void ApplicationController::triggerQuit()
{
    qDebug() << Q_FUNC_INFO << m_quit_triggered;
    m_quit_triggered = true;
    emit quitTriggered();
}

void ApplicationController::quit()
{
    qDebug() << Q_FUNC_INFO << m_quit_triggered;
    qApp->removeEventFilter(this);
    qApp->quit();
}

void ApplicationController::triggerCrash()
{
    qFatal() << Q_FUNC_INFO;
}

bool SentryPayloadFromMinidump(const QString& path, QByteArray& envelope);

void ApplicationController::reportCrashes()
{
    qDebug() << Q_FUNC_INFO;

    auto engine = qmlEngine(this);
    if (!engine) {
        qDebug() << Q_FUNC_INFO << "engine not set";
        return;
    }
    auto net = engine->networkAccessManager();
    if (!net) {
        qDebug() << Q_FUNC_INFO << "network access manager not set";
        return;
    }

    QDir dir(GetDataDir("crashpad"));
#if defined(Q_OS_WINDOWS)
    dir.cd("reports");
#else
    dir.cd("pending");
#endif
    QDirIterator it(dir.absolutePath(), QDir::Files, QDirIterator::NoIteratorFlags);
    while (it.hasNext()) {
        const auto minidump_path = it.next();
        qDebug() << Q_FUNC_INFO << minidump_path;
        QByteArray envelope;
        if (SentryPayloadFromMinidump(minidump_path, envelope)) {
            QUrl url("https://sentry.blockstream.io/api/2/envelope/");
            QNetworkRequest req(url);
            req.setRawHeader("Content-Type", "application/json");
            req.setRawHeader("X-Sentry-Auth", "Sentry sentry_key=" SENTRY_KEY);

            auto reply = net->post(req, envelope);

            connect(reply, &QNetworkReply::finished, this, [=] {
                qDebug() << Q_FUNC_INFO << reply->readAll();
                reply->deleteLater();
            });
        }
        QFile::remove(minidump_path);
    }
}

bool ApplicationController::eventFilter(QObject* obj, QEvent* event)
{
    if (event->type() == QEvent::Quit) {
        if (!m_quit_triggered) {
            emit quitRequested();
            return true;
        }
    }
    return QObject::eventFilter(obj, event);
}
