#include "application.h"
#include "walletmanager.h"

#include <QtConcurrentRun>
#include <QFileOpenEvent>
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
    if (contents.isEmpty()) {
        *size = requested_size;
        QImage image(*size, QImage::Format_RGB32);
        image.fill(0xFFFFFFFF);
        return image;
    } else {
        *size = requested_size;
        ZXing::MultiFormatWriter writer(ZXing::BarcodeFormat::QRCode);
        writer.setEccLevel(7);
        writer.setEncoding(ZXing::CharacterSet::UTF8);
        writer.setMargin(1);
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
