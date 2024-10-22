#ifndef GREEN_APPLICATION_H
#define GREEN_APPLICATION_H

#include <QApplication>
#include <QFutureWatcher>
#include <QQmlEngine>
#include <QQuickImageProvider>
#include <QVideoSink>
#include <QVideoFrame>
#include <QUrl>

class Application : public QApplication
{
    Q_OBJECT
public:
    Application(int &argc, char **argv);
    void raise();
protected:
    bool event(QEvent *event) override;
};

class ApplicationController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    ApplicationController(QObject* parent = nullptr);
    virtual ~ApplicationController();
public slots:
    void triggerQuit();
    void quit();
signals:
    void quitRequested();
    void quitTriggered();
protected:
    bool eventFilter(QObject *obj, QEvent *event);
private:
    bool m_quit_triggered{false};
};

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

#endif // GREEN_APPLICATION_H
