#ifndef GREEN_EXPORTADDRESSESCONTROLLER_H
#define GREEN_EXPORTADDRESSESCONTROLLER_H

#include "green.h"
#include "controller.h"

#include <QObject>
#include <QtQml>

class ExportAddressesController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    QML_ELEMENT

public:
    explicit ExportAddressesController(QObject* parent = nullptr);

    Account* account() const { return m_account; }
    void setAccount(Account* account);

public slots:
    void save();

signals:
    void accountChanged();
    void rejected();
    void saved(const QString& name, const QUrl& url);

private:
    void nextPage();

private:
    Account* m_account{nullptr};
    int m_last_pointer{0};
    QString m_file_name;
    QStringList m_lines;
};

#endif // GREEN_EXPORTADDRESSESCONTROLLER_H
