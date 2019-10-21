#ifndef BLOCKSTREAM_GREEN_GUI_H
#define BLOCKSTREAM_GREEN_GUI_H

#include <QAction>
#include <QMainWindow>
#include <QMenu>
#include <QMenuBar>
#include <QQmlListProperty>

class Menu;

class MenuBar : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<QObject> data READ data DESIGNABLE false)
    Q_PROPERTY(QMainWindow* window READ window WRITE setWindow NOTIFY windowChanged DESIGNABLE false)
    Q_CLASSINFO("DefaultProperty", "data")
    
public:
    MenuBar();
    virtual ~MenuBar();

    QList<Menu*> m_menus;

    QQmlListProperty<QObject> data();
    QMainWindow* window() const;
public slots:
    void setWindow(QMainWindow* window);
signals:
    void windowChanged(QMainWindow* window);

public:
    QMenuBar* m_menu_bar{nullptr};
    QMainWindow* m_window{nullptr};
};

class Menu : public QMenu
{
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<QObject> data READ data DESIGNABLE false)
    Q_CLASSINFO("DefaultProperty", "data")

public:
    Menu() : QMenu() {}
    virtual ~Menu() {}

    QQmlListProperty<QObject> data();
};

class Action : public QAction
{
    Q_OBJECT

public:
    Action() : QAction() {}
    virtual ~Action() {}
};

class Separator : public Action
{
    Q_OBJECT

public:
    Separator();
    virtual ~Separator() {}
};

#endif // BLOCKSTREAM_GREEN_GUI_H
