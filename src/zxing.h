#ifndef GREEN_ZXING_H
#define GREEN_ZXING_H

#include <QFutureWatcher>
#include <QObject>
#include <QQmlEngine>
#include <QQuickImageProvider>
#include <QVideoFrame>
#include <QVideoSink>

class ZXingDetector : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVideoSink* videoSink READ videoSink WRITE setVideoSink NOTIFY videoSinkChanged)
    Q_PROPERTY(QVariantList results READ results NOTIFY resultsChanged)
    QML_ELEMENT
public:
    ZXingDetector(QObject* parent = nullptr);
    QVideoSink* videoSink() const { return m_video_sink; }
    void setVideoSink(QVideoSink* video_sink);
    QVariantList results() const { return m_results; }
signals:
    void videoSinkChanged();
    void resultsChanged();
private slots:
    void videoFrameChanged(const QVideoFrame& frame);
private:
    QVideoSink* m_video_sink{nullptr};
    QVariantList m_results;
    QFutureWatcher<QVariantList>* m_watcher{nullptr};
};

class ZXingImageProvider : public QQuickImageProvider
{
public:
    ZXingImageProvider();
    QImage requestImage(const QString& id, QSize* size, const QSize& requested_size) override;
};

#endif // GREEN_ZXING_H
