#ifndef BLOCKSTREAM_ASSETMANAGER_H
#define BLOCKSTREAM_ASSETMANAGER_H

#include "green.h"

#include <QMap>
#include <QObject>
#include <QQmlEngine>
#include <QStandardItemModel>
#include <QString>

class AssetManager : public QObject
{
    Q_OBJECT
public:
    explicit AssetManager();
    virtual ~AssetManager();

    static AssetManager* instance();

    static AssetManager* create(QQmlEngine*, QJSEngine*);

    QStandardItemModel* model() const { return m_model; }

    Q_INVOKABLE Asset* assetWithId(const QString& deployment, const QString& id);

private:
    QMap<QPair<QString, QString>, Asset*> m_assets;
    QStandardItemModel* const m_model;
};

#endif // BLOCKSTREAM_ASSETMANAGER_H
