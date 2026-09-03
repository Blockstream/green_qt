#ifndef GREEN_OUTPUTLISTMODEL_H
#define GREEN_OUTPUTLISTMODEL_H

#include "green.h"

#include <QAbstractListModel>
#include <QModelIndex>
#include <QQmlEngine>
#include <QVector>

class OutputListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(Account* account READ account WRITE setAccount NOTIFY accountChanged)
    Q_PROPERTY(bool allCoins READ allCoins WRITE setAllCoins NOTIFY allCoinsChanged)
    Q_PROPERTY(bool fetching READ fetching NOTIFY fetchingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    QML_ELEMENT
public:
    OutputListModel(QObject* parent = nullptr);
    ~OutputListModel();
    Account* account() const { return m_account; }
    void setAccount(Account* account);
    bool allCoins() const { return m_all_coins; }
    void setAllCoins(bool all_coins);
    bool fetching() const { return m_fetching; }
    QString error() const { return m_error; }
    QHash<int,QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
public slots:
    int indexOf(Output* output) const;
    void fetch();
signals:
    void accountChanged(Account* account);
    void allCoinsChanged();
    void fetchingChanged();
    void errorChanged();
    void selectionChanged();
private:
    void update();
private:
    Account* m_account{nullptr};
    QVector<Output*> m_outputs;
    bool m_all_coins{true};
    bool m_fetching{false};
    QString m_error;
    TaskDispatcher* const m_dispatcher;
};

#endif // GREEN_OUTPUTLISTMODEL_H
