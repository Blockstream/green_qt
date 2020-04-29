#include "clipboard.h"

#include <QClipboard>
#include <QGuiApplication>

Clipboard::Clipboard(QObject* parent) : QObject(parent)
{
}

Clipboard *Clipboard::instance()
{
    static Clipboard clipboard;
    return &clipboard;
}

void Clipboard::copy(const QString& data)
{
    QGuiApplication::clipboard()->setText(data);
}
