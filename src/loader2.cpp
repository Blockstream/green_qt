#include "loader2.h"

Loader2::Loader2(QObject *parent)
    : QObject{parent}
{
}

void Loader2::classBegin()
{
}

void Loader2::componentComplete()
{
    update();
}

QQmlComponent *Loader2::sourceComponent() const
{
    return m_source_component;
}

void Loader2::setSourceComponent(QQmlComponent* source_component)
{
    if (m_source_component == source_component) return;
    m_source_component = source_component;
    emit sourceComponentChanged();
    invalidate();
}

bool Loader2::active() const
{
    return m_active;
}

void Loader2::setActive(bool active)
{
    if (m_active == active) return;
    m_active = active;
    emit activeChanged();
    invalidate();
}

QObject *Loader2::object() const
{
    return m_object;
}

void Loader2::timerEvent(QTimerEvent* event)
{
    if (event->timerId() == m_timer_id) {
        killTimer(m_timer_id);
        m_timer_id = 0;
        update();
    }
}

void Loader2::invalidate()
{
    if (m_timer_id > 0) killTimer(m_timer_id);
    m_timer_id = startTimer(1);
}

void Loader2::update()
{
    if (!m_object && m_active && m_source_component) {
        QVariantMap properties;
        for (int i = Loader2::staticMetaObject.propertyCount(); i < metaObject()->propertyCount(); ++i) {
            auto property = metaObject()->property(i);
            properties.insert(property.name(), property.read(this));
        }

        m_object = m_source_component->beginCreate(qmlContext(this));
        m_object->setParent(parent());
        m_source_component->setInitialProperties(m_object, properties);
        m_source_component->completeCreate();

        connect(m_object, &QObject::destroyed, this, [=](QObject* object) {
           if (m_object == object) {
               m_object = nullptr;
               emit objectChanged();
               invalidate();
           }
        });
        emit objectChanged();
        return;
    }

    if (m_object && (!m_active || !m_source_component)) {
        qmlEngine(this)->setObjectOwnership(m_object, QQmlEngine::JavaScriptOwnership);

        m_object = nullptr;
        emit objectChanged();
        return;
    }
}
