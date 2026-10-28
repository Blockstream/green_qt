#ifndef BLOCKSTREAM_ASSETMANAGER_H
#define BLOCKSTREAM_ASSETMANAGER_H

#include "green.h"

#include <QElapsedTimer>
#include <QList>
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

    // Fetches the Liquid asset registry for a deployment once; refresh forces a new fetch.
    void load(const QString& deployment);
    void refresh(const QString& deployment);
    void refreshIfStale(const QString& deployment);
    void stop();

public slots:
    // Starts registry fetching; called from the UI once startup settings are applied.
    void start();

private:
    struct Registry {
        Session* session{nullptr};
        TaskGroup* group{nullptr};
        QList<Task*> tasks;
        bool loaded{false};
        QElapsedTimer timer;
    };
    void fetch(const QString& deployment);
    void release(const QString& deployment);

    QMap<QPair<QString, QString>, Asset*> m_assets;
    QStandardItemModel* const m_model;
    TaskDispatcher* const m_dispatcher;
    QMap<QString, Registry> m_registries;
    QStringList m_pending;
    bool m_started{false};
};

#endif // BLOCKSTREAM_ASSETMANAGER_H
