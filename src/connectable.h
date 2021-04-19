#ifndef GREEN_CONNECTABLE_H
#define GREEN_CONNECTABLE_H

#include <QMetaObject>
#include <QObject>

#include <vector>

template <typename T>
class Connectable
{
public:
    Connectable(T* value = nullptr) { update(value); }
    ~Connectable() {
        update(nullptr);
    }
    T* get() const { return m_value; }
    Connectable<T>& operator=(T* value) { update(value); return *this; }
    operator T*() const { return m_value; }
    operator bool() const { return m_value; }
    T* operator->() { return m_value; }
    const T* operator->() const { return m_value; }
    bool update(T* value) {
        if (m_value == value) return false;
        for (const auto& connection : m_connections) {
            QObject::disconnect(connection);
        }
        m_connections.clear();
        m_value = value;
        if (m_value) m_connections.push_back(QObject::connect(m_value, &QObject::destroyed, [this] {
            update(nullptr);
        }));
        return true;
    }
    void track(QMetaObject::Connection&& connection) {
        m_connections.emplace_back(connection);
    }
    void destroy()
    {
        T* value = m_value;
        update(nullptr);
        delete value;
    }
private:
    T* m_value{nullptr};
    std::vector<QMetaObject::Connection> m_connections;
};


#endif // GREEN_CONNECTABLE_H
