#include "DatabaseManager.h"
#include "qaesencryption.h"
#include <QCryptographicHash>

DatabaseManager::DatabaseManager(QObject *parent): QObject(parent){
    db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName("passwords_vault.db");

    if (!db.open()) {
        qDebug() << "Error: connection with database failed" << db.lastError().text();
    } else {
        qDebug() << "Database: connection ok";

        QSqlQuery query(db);
        QString createTable = "CREATE TABLE IF NOT EXISTS passwords ("
                              "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                              "service TEXT, "
                              "login TEXT, "
                              "password TEXT)";
        if (!query.exec(createTable)) {
            qDebug() << "Table creation failed:" << query.lastError().text();
        }
    }
}

DatabaseManager::~DatabaseManager() {
    if (db.isOpen()) {
        db.close();
    }
}

bool DatabaseManager::connectToDB(const QString& dbPath) {
    if (db.isOpen()) db.close();

    db.setDatabaseName(dbPath);
    if (!db.open()) {
        qDebug() << "Failed to connect to SQLite:" << db.lastError().text();
        return false;
    }
    return true;
}

QString DatabaseManager::hashPass(const QString& pass) {
    QByteArray hash = QCryptographicHash::hash(pass.toUtf8(), QCryptographicHash::Sha256);

    return hash.toHex();
}

QString DatabaseManager::encrypt(const QString& plainText, const QString& key) {
    QAESEncryption encryption(QAESEncryption::AES_256, QAESEncryption::CBC);

    QByteArray keyData = QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha256);

    QByteArray ivData = QCryptographicHash::hash(keyData, QCryptographicHash::Md5);

    QByteArray plainData = plainText.toUtf8();
    QByteArray encryptedData = encryption.encode(plainData, keyData, ivData);

    return QString::fromLatin1(encryptedData.toBase64());
}

QString DatabaseManager::decrypt(const QString& base64Text, const QString& key) {
    QAESEncryption encryption(QAESEncryption::AES_256, QAESEncryption::CBC);

    QByteArray keyData = QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha256);
    QByteArray ivData = QCryptographicHash::hash(keyData, QCryptographicHash::Md5);

    QByteArray encryptedData = QByteArray::fromBase64(base64Text.toUtf8());

    QByteArray decodedData = encryption.decode(encryptedData, keyData, ivData);

    QByteArray resultData = encryption.removePadding(decodedData);

    return QString::fromUtf8(resultData);
}

bool DatabaseManager::setMasterKey(const QString& password) {
    if (password.isEmpty()) return false;
    m_sessionKey = password;
    return true;
}

void DatabaseManager::addData(const QString& service, const QString& login, const QString& rawPass) {
    QString encrypted = encrypt(rawPass, m_sessionKey);

    QSqlQuery query(db);
    query.prepare("INSERT INTO passwords (service, login, password) VALUES (:service, :login, :pass)");
    query.bindValue(":service", service);
    query.bindValue(":login", login);
    query.bindValue(":pass", encrypted);
    query.exec();
}

QString DatabaseManager::getDecryptedPassword(int id) {
    QSqlQuery query(db);
    query.prepare("SELECT password FROM passwords WHERE id = :id");
    query.bindValue(":id", id);

    if (query.exec() && query.next()) {
        QString encryptedFromDb = query.value(0).toString();
        return decrypt(encryptedFromDb, m_sessionKey);
    }
    return "";
}

void DatabaseManager::get_data_list() {
    QSqlQuery query(db);
    if (!query.exec("SELECT id, service, login FROM passwords")) {
        qDebug() << "Select error:" << query.lastError().text();
        return;
    }

    while (query.next()) {
        int id = query.value(0).toInt();
        QString service = query.value(1).toString();
        QString login = query.value(2).toString();
        qDebug() << "ID:" << id << "| Service:" << service << "| Login:" << login;
    }
}

void DatabaseManager::removeData(int id) {
    QSqlQuery query(db);
    query.prepare("DELETE FROM passwords WHERE id = :id");
    query.bindValue(":id", id);

    if(!query.exec()) {
        qDebug() << "Delete error:" << query.lastError().text();
    } else {
        qDebug() << "ID" << id << "deleted.";
    }
}
