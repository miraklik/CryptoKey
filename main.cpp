#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "DatabaseManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<DatabaseManager>("CryptoKey", 1, 0, "DatabaseManager");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("CryptoKey", "Main");

    return app.exec();
}
