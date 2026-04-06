#ifndef GREEN_LOGGING_H
#define GREEN_LOGGING_H

#include <QtMessageHandler>

void logMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg);

#endif // GREEN_LOGGING_H
