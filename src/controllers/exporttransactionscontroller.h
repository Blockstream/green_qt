#ifndef GREEN_EXPORTTRANSACTIONSCONTROLLER_H
#define GREEN_EXPORTTRANSACTIONSCONTROLLER_H

#include "green.h"

#include "controller.h"

#include <QObject>
#include <QtQml>

class ExportTransactionsController : public Controller
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    QML_ELEMENT
public:
    explicit ExportTransactionsController(QObject* parent = nullptr);
    Account* account() const { return m_account; }
    void setAccount(Account* account);
public slots:
    void save();
private slots:
    void saveToFile(const QString& file);
signals:
    void accountChanged();
    void rejected();
    void saved(const QString name, const QUrl& url);
private:
    void nextPage();
private:
    Account* m_account{nullptr};
    int m_count{5};
    int m_offset{0};
    QDateTime m_datetime;
    QString m_file_name;
    QString m_fee_field;
    QString m_fiat_field;
    bool m_include_header{true};
    QString m_separator{","};
    QStringList m_fields;
    QStringList m_lines;
};

#endif // GREEN_EXPORTTRANSACTIONSCONTROLLER_H
