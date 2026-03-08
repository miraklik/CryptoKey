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

    Q_INVOKABLE bool    isMasterKeySet();
    Q_INVOKABLE bool    setMasterKey(const QString& password);
    Q_INVOKABLE QString verifyMasterKey(const QString& password);

    Q_INVOKABLE void         addData(const QString& service, const QString& login, const QString& rawPass);
    Q_INVOKABLE QString      getDecryptedPassword(int id);
    Q_INVOKABLE QVariantList getEntriesList();
    Q_INVOKABLE void         removeData(int id);
    Q_INVOKABLE void         get_data_list();

    bool connectToDB(const QString& dbPath);

signals:
    void dataChanged();

private:
    QSqlDatabase db;
    QString      m_sessionKey;

    QString hashPass(const QString& pass);
    QString encrypt (const QString& plainText,  const QString& key);
    QString decrypt (const QString& base64Text, const QString& key);
};
