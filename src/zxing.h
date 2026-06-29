#ifndef GREEN_ZXING_H
#define GREEN_ZXING_H

#include <QQuickImageProvider>

class ZXingImageProvider : public QQuickImageProvider
{
public:
    ZXingImageProvider();
    QImage requestImage(const QString& id, QSize* size, const QSize& requested_size) override;
};

#endif // GREEN_ZXING_H
