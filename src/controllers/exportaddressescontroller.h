#ifndef GREEN_EXPORTADDRESSESCONTROLLER_H
#define GREEN_EXPORTADDRESSESCONTROLLER_H

#include <QObject>
#include <QtQml>

QT_FORWARD_DECLARE_CLASS(Account)
QT_FORWARD_DECLARE_CLASS(Handler)

class ExportAddressesController : public QObject
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
    void accountChanged(Account* account);
    void saved();
private:
    void nextPage();
private:
    Account* m_account{nullptr};
    int m_last_pointer{0};
    QString m_file_name;
    QStringList m_lines;
};

#endif // GREEN_EXPORTADDRESSESCONTROLLER_H
