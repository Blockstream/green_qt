#include <QDesktopServices>
#include <QObject>
#include <QUrl>
#include <QtQuickTest>

// Keeps UiLink tests from launching the system browser.
class Setup : public QObject
{
    Q_OBJECT
public slots:
    void applicationAvailable()
    {
        QDesktopServices::setUrlHandler("https", this, "openUrl");
    }
    void openUrl(const QUrl &url)
    {
        Q_UNUSED(url)
    }
};

QUICK_TEST_MAIN_WITH_SETUP(blockstream_controls, Setup)

#include "main.moc"
