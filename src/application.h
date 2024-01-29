#ifndef GREEN_APPLICATION_H
#define GREEN_APPLICATION_H

#include <QApplication>
#include <QUrl>

class Application : public QApplication
{
    Q_OBJECT
public:
    Application(int &argc, char **argv);
    void raise();
protected:
    bool event(QEvent *event) override;
};

#endif // GREEN_APPLICATION_H
