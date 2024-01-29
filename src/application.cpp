#include "application.h"

#include <QWindow>

Application::Application(int& argc, char** argv)
    : QApplication(argc, argv)
{
}

void Application::raise()
{
    for (QWindow* window : allWindows()) {
        // windows: does not allow a window to be brought to front while the user has focus on another window
        // instead, Windows flashes the taskbar button of the window to notify the user

        // mac: if the primary window is minimized, it is restored. It is background, it is brough to foreground

        window->showNormal();
        window->requestActivate();
        window->raise();
    }
}
