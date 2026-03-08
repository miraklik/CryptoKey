#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "DatabaseManager.h"
#include "totp.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<DatabaseManager>("CryptoKey", 1, 0, "DatabaseManager");

    TotpGenerator *totp = new TotpGenerator(&app);
    qmlRegisterSingletonInstance("App.TOTP", 1, 0, "TotpHelper", totp);

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
