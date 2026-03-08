#include "DatabaseManager.h"
#include "qaesencryption.h"
#include <QCryptographicHash>

DatabaseManager::DatabaseManager(QObject *parent): QObject(parent){
    db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName("passwords_vault.db");

    if (!db.open()) {
        qDebug() << "Error: connection with database failed" << db.lastError().text();
        return;
    }

    qDebug() << "Database: connection ok";
    QSqlQuery query(db);

    query.exec(
        "CREATE TABLE IF NOT EXISTS passwords ("
        "id       INTEGER PRIMARY KEY AUTOINCREMENT, "
        "service  TEXT, "
        "login    TEXT, "
        "password TEXT)"
        );

    query.exec(
        "CREATE TABLE IF NOT EXISTS master ("
        "id           INTEGER PRIMARY KEY CHECK (id = 1), "
        "hash         TEXT NOT NULL, "
        "verification TEXT NOT NULL)"
        );
}

DatabaseManager::~DatabaseManager() {
    if (db.isOpen()) db.close();
}

QString DatabaseManager::hashPass(const QString& pass) {
    QByteArray hash = QCryptographicHash::hash(pass.toUtf8(), QCryptographicHash::Sha256);
    return hash.toHex();
}

QString DatabaseManager::encrypt(const QString& plainText, const QString& key) {
    QAESEncryption encryption(QAESEncryption::AES_256, QAESEncryption::CBC);
    QByteArray keyData = QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha256);
    QByteArray ivData  = QCryptographicHash::hash(keyData, QCryptographicHash::Md5);
    return QString::fromLatin1(
        encryption.encode(plainText.toUtf8(), keyData, ivData).toBase64()
        );
}

QString DatabaseManager::decrypt(const QString& base64Text, const QString& key) {
    QAESEncryption encryption(QAESEncryption::AES_256, QAESEncryption::CBC);
    QByteArray keyData       = QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha256);
    QByteArray ivData        = QCryptographicHash::hash(keyData, QCryptographicHash::Md5);
    QByteArray encryptedData = QByteArray::fromBase64(base64Text.toUtf8());
    QByteArray decodedData   = encryption.decode(encryptedData, keyData, ivData);
    return QString::fromUtf8(encryption.removePadding(decodedData));
}

bool DatabaseManager::isMasterKeySet() {
    QSqlQuery query(db);
    query.exec("SELECT id FROM master WHERE id = 1");
    return query.next();
}

bool DatabaseManager::setMasterKey(const QString& password) {
    if (password.isEmpty()) return false;
    if (isMasterKeySet()) return false;

    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO master (id, hash, verification) "
        "VALUES (1, :hash, :verification)"
        );
    query.bindValue(":hash",         hashPass(password));
    query.bindValue(":verification", encrypt("CRYPTOKEY_OK", password));

    if (!query.exec()) {
        qDebug() << "Failed to save master key:" << query.lastError().text();
        return false;
    }

    m_sessionKey = password;
    qDebug() << "Master key created.";
    return true;
}

QString DatabaseManager::verifyMasterKey(const QString& password) {
    if (password.isEmpty()) return "wrong";
    if (!isMasterKeySet())  return "not_set";

    QSqlQuery query(db);
    query.exec("SELECT hash, verification FROM master WHERE id = 1");
    if (!query.next()) return "wrong";

    QString storedHash         = query.value(0).toString();
    QString storedVerification = query.value(1).toString();

    if (hashPass(password) != storedHash) {
        qDebug() << "Wrong master key: hash mismatch.";
        return "wrong";
    }

    if (decrypt(storedVerification, password) != "CRYPTOKEY_OK") {
        qDebug() << "Wrong master key: verification failed.";
        return "wrong";
    }

    m_sessionKey = password;
    qDebug() << "Master key verified. Session opened.";
    return "ok";
}

void DatabaseManager::addData(const QString& service, const QString& login, const QString& rawPass) {
    QString encrypted = encrypt(rawPass, m_sessionKey);

    QSqlQuery query(db);
    query.prepare(
        "INSERT INTO passwords (service, login, password) "
        "VALUES (:service, :login, :pass)"
        );
    query.bindValue(":service", service);
    query.bindValue(":login",   login);
    query.bindValue(":pass",    encrypted);
    query.exec();

    emit dataChanged();
}

QString DatabaseManager::getDecryptedPassword(int id) {
    QSqlQuery query(db);
    query.prepare("SELECT password FROM passwords WHERE id = :id");
    query.bindValue(":id", id);
    if (query.exec() && query.next()) {
        return decrypt(query.value(0).toString(), m_sessionKey);
    }
    return "";
}

QVariantList DatabaseManager::getEntriesList() {
    QVariantList result;
    QSqlQuery query(db);
    if (!query.exec("SELECT id, service, login FROM passwords ORDER BY id DESC")) {
        qDebug() << "Select error:" << query.lastError().text();
        return result;
    }
    while (query.next()) {
        QVariantMap entry;
        entry["id"]      = query.value(0).toInt();
        entry["service"] = query.value(1).toString();
        entry["login"]   = query.value(2).toString();
        result.append(entry);
    }
    return result;
}

void DatabaseManager::removeData(int id) {
    QSqlQuery query(db);
    query.prepare("DELETE FROM passwords WHERE id = :id");
    query.bindValue(":id", id);
    if (!query.exec()) {
        qDebug() << "Delete error:" << query.lastError().text();
    } else {
        qDebug() << "ID" << id << "deleted.";
        emit dataChanged();
    }
}

void DatabaseManager::get_data_list() {
    QSqlQuery query(db);
    if (!query.exec("SELECT id, service, login FROM passwords")) {
        qDebug() << "Select error:" << query.lastError().text();
        return;
    }
    while (query.next()) {
        qDebug() << "ID:" << query.value(0).toInt()
        << "| Service:" << query.value(1).toString()
        << "| Login:"   << query.value(2).toString();
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
