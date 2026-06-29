#include "zxing.h"

#include <QtMultimedia>
#include <QtQml>
#include <QUrl>

#include <ZXing/ZXingQt.h>

using namespace ZXingQt;

static QImage grayscaleToTransparentArgb(const QImage& gray, const QSize& target_size)
{
    QImage image(target_size, QImage::Format_ARGB32);
    image.fill(Qt::transparent);

    if (gray.isNull()) {
        return image;
    }

    const auto scaled = gray.scaled(target_size, Qt::KeepAspectRatio, Qt::FastTransformation);
    const int x = (target_size.width() - scaled.width()) / 2;
    const int y = (target_size.height() - scaled.height()) / 2;

    for (int py = 0; py < scaled.height(); ++py) {
        for (int px = 0; px < scaled.width(); ++px) {
            if (qGray(scaled.pixel(px, py)) < 128) {
                image.setPixelColor(x + px, y + py, QColor(0, 0, 0, 255));
            }
        }
    }

    return image;
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
    }

    const auto barcode = Barcode::fromText(contents, BarcodeFormat::QRCode);
    const auto gray = barcode.toImage(ZXing::WriterOptions().scale(-size->width()));
    return grayscaleToTransparentArgb(gray, *size);
}

#include "ZXing/moc_ZXingQt.cpp"
