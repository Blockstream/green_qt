#include "clipboard.h"

#include <QClipboard>
#include <QGuiApplication>

Clipboard::Clipboard(QObject* parent) : QObject(parent)
{
}

Clipboard* Clipboard::instance()
{
    static Clipboard instance;
    return &instance;
}

void Clipboard::copy(const QString& data) // NOLINT(build/include_what_you_use)
{
    QGuiApplication::clipboard()->setText(data);
}

QString Clipboard::text() const
{
    return QGuiApplication::clipboard()->text();
}
