#include "gui.h"

namespace {

void MenuBarDataAppend(QQmlListProperty<QObject>* property, QObject* object)
{
    Menu* menu = qobject_cast<Menu*>(object);
    Q_ASSERT(menu);
    MenuBar* menu_bar = static_cast<MenuBar*>(property->object);
#ifdef Q_OS_MAC
    object->setParent(menu_bar->m_menu_bar);
    menu_bar->m_menus.append(menu);
    menu_bar->m_menu_bar->addMenu(menu);
#else
    menu_bar->m_menus.append(menu);
    object->setParent(menu_bar);
    QObject::connect(menu, &QObject::destroyed, [menu_bar, menu] {
        menu_bar->m_menus.removeOne(menu);
    });
#endif
}

void MenuDataAppend(QQmlListProperty<QObject>* property, QObject* object)
{
    Action* action = qobject_cast<Action*>(object);
    Q_ASSERT(action);
    Menu* menu = static_cast<Menu*>(property->object);
    menu->addAction(action);
}

} // namespace


MenuBar::MenuBar()
{
#ifdef Q_OS_MAC
    static QMenuBar* menu_bar = new QMenuBar(nullptr);
    m_menu_bar = menu_bar;
#endif
}

MenuBar::~MenuBar()
{
    for (Menu* menu : m_menus) {
        delete menu;
    }
}

QQmlListProperty<QObject> MenuBar::data()
{
    return QQmlListProperty<QObject>(this, nullptr, MenuBarDataAppend, nullptr, nullptr, nullptr);
}

QMainWindow *MenuBar::window() const
{
    return m_window;
}

void MenuBar::setWindow(QMainWindow *window)
{
    Q_ASSERT(!m_window && window);
    m_window = window;
#ifndef Q_OS_MAC
    m_menu_bar = m_window->menuBar();
    for (Menu* menu : m_menus) {
        // first move menu ownership to menu bar
        static_cast<QObject*>(menu)->setParent(m_menu_bar);
        // then add the menu to the menu bar
        m_menu_bar->addMenu(menu);
    }
#endif
    emit windowChanged(m_window);
}

QQmlListProperty<QObject> Menu::data()
{
    return QQmlListProperty<QObject>(this, nullptr, MenuDataAppend, nullptr, nullptr, nullptr);
}

Separator::Separator() : Action()
{
    setSeparator(true);
}
