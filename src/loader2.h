#ifndef GREEN_LOADER2_H
#define GREEN_LOADER2_H

#include <QObject>
#include <QQmlComponent>
#include <QQmlEngine>

class Loader2 : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_PROPERTY(QQmlComponent* sourceComponent READ sourceComponent WRITE setSourceComponent NOTIFY sourceComponentChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(QObject* object READ object NOTIFY objectChanged)
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT
public:
    explicit Loader2(QObject *parent = nullptr);
    void classBegin() override;
    void componentComplete() override;
    QQmlComponent* sourceComponent() const;
    void setSourceComponent(QQmlComponent* source_component);
    bool active() const;
    void setActive(bool newActive);
    QObject* object() const;
signals:
    void sourceComponentChanged();
    void activeChanged();
    void objectChanged();
protected:
    void timerEvent(QTimerEvent* event) override;
    void invalidate();
    void update();
private:
    int m_timer_id{0};
    QQmlComponent* m_source_component{nullptr};
    bool m_active;
    QObject* m_object{nullptr};
};

#include <QQuickItem>
class Clipper : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QRectF offset READ offset WRITE setOffset NOTIFY offsetChanged)
    QML_ELEMENT
public:
    Clipper(QQuickItem *parent = nullptr);

    QRectF offset() const { return m_offset; }
    void setOffset(const QRectF&);

signals:
    void offsetChanged();

protected:
    QRectF clipRect() const override;

private:
    QRectF m_offset;
};

#include <QSortFilterProxyModel>
class LimitProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int limit READ limit WRITE setLimit NOTIFY limitChanged)
    QML_ELEMENT
public:
    LimitProxyModel(QObject* parent = nullptr);

    QAbstractItemModel* source() const { return m_source; }
    void setSource(QAbstractItemModel*);

    int limit() const;
    void setLimit(int);

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;

signals:
    void sourceChanged();
    void limitChanged();

private:
    QAbstractItemModel* m_source = nullptr;
    int m_limit = 0;
};

#endif // GREEN_LOADER2_H
