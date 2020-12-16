#ifndef GREEN_RECEIVEADDRESSCONTROLLER_H
#define GREEN_RECEIVEADDRESSCONTROLLER_H

#include <QtQml>
#include <QObject>

QT_FORWARD_DECLARE_CLASS(Account)

class ReceiveAddressController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(QString amount READ amount WRITE setAmount NOTIFY changed)
    Q_PROPERTY(QString address READ address NOTIFY changed)
    Q_PROPERTY(QString uri READ uri NOTIFY changed)
    Q_PROPERTY(bool generating READ generating NOTIFY generatingChanged)
    QML_ELEMENT
public:
    explicit ReceiveAddressController(QObject* parent = nullptr);
    virtual ~ReceiveAddressController();
    Account* account() const;
    void setAccount(Account* account);
    QString amount() const;
    void setAmount(const QString& amount);
    QString address() const;
    QString uri() const;
    bool generating() const;
    void setGenerating(bool generating);
public slots:
    void generate();
signals:
    void accountChanged(Account* account);
    void changed();
    void generatingChanged(bool generating);
public:
    Account* m_account{nullptr};
    QString m_amount;
    QString m_address;
    bool m_generating{false};
};

#endif // GREEN_RECEIVEADDRESSCONTROLLER_H
