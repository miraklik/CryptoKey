#pragma once

#include <QObject>
#include <QtQml>
#include <QString>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlError>
#include <QtSql/QSqlQuery>
#include <QDebug>
#include <QCryptographicHash>

class DatabaseManager : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    Q_INVOKABLE bool setMasterKey(const QString& password);
    Q_INVOKABLE void addData(const QString& service, const QString& login, const QString& rawPass);
    Q_INVOKABLE QString getDecryptedPassword(int id);

    bool connectToDB(const QString& dbPath);
    QString hashPass(const QString& pass);
    QString encrypt(const QString& plainText, const QString& key);
    QString decrypt(const QString& base64Text, const QString& key);

    Q_INVOKABLE void get_data_list();
    Q_INVOKABLE void removeData(int id);

private:
    QString m_sessionKey;
    QSqlDatabase db;
};
