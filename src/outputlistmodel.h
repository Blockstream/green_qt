#ifndef GREEN_OUTPUTLISTMODEL_H
#define GREEN_OUTPUTLISTMODEL_H

#include <QAbstractListModel>
#include <QModelIndex>
#include <QtQml>
#include <QVector>

#include "connectable.h"

class Account;
class Output;

class OutputListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    QML_ELEMENT
public:
    OutputListModel(QObject* parent = nullptr);
    ~OutputListModel();
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    bool fetching() const { return m_fetching; }
    QHash<int,QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
public slots:
    int indexOf(Output* output) const;
    void fetch();
signals:
    void accountChanged(Account* account);
    void fetchingChanged();
    void selectionChanged();
private:
    void update();
private:
    Connectable<Account> m_account;
    QVector<Output*> m_outputs;
    bool m_fetching{false};
};

#endif // GREEN_OUTPUTLISTMODEL_H
