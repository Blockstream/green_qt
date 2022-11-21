#ifndef GREEN_LOADER2_H
#define GREEN_LOADER2_H

#include <QObject>
#include <QQmlComponent>
#include <QtQml>

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

#endif // GREEN_LOADER2_H
