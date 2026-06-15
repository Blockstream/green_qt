#include "zxing.h"

#include <QtConcurrentRun>
#include <QUrl>

#include <ZXing/BitMatrix.h>
#include <ZXing/MultiFormatWriter.h>
#include <ZXing/ReadBarcode.h>

ZXingDetector::ZXingDetector(QObject *parent)
    : QObject(parent)
{
}

ZXingDetector::~ZXingDetector()
{
    m_future.waitForFinished();
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
    if (!m_future.isFinished()) return;

    auto current = m_results;

    auto future = QtConcurrent::run([=, this] {
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
    });

    future.then(this, [=, this](QVariantList results) {
        m_results = results;
        emit resultsChanged();
    });

    m_future = future;
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
        QImage image(*size, QImage::Format_ARGB32_Premultiplied);
        image.fill(0x0);
        return image;
    } else {
        ZXing::MultiFormatWriter writer(ZXing::BarcodeFormat::QRCode);
        // writer.setEccLevel(7);
        writer.setEncoding(ZXing::CharacterSet::UTF8);
        // writer.setMargin(0);
        const auto bitmatrix = writer.encode(contents.toStdString(), size->width(), size->height());

        QImage image(*size, QImage::Format_ARGB32);
        const QColor f(0, 0, 0, 255);
        const QColor g(0, 0, 0, 0);
        for (int x = 0; x < size->width(); x++) {
            for (int y = 0; y < size->height(); y++) {
                image.setPixelColor(QPoint(x, y), bitmatrix.get(x, y) ? f : g);
            }
        }
        return image;
    }
}
