#pragma once

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QCryptographicHash>
#include <QByteArray>
#include <QTimer>

class TotpGenerator : public QObject {
    Q_OBJECT
    Q_PROPERTY(int timeLeft READ timeLeft NOTIFY timeLeftChanged)
    Q_PROPERTY(QString currentCode READ currentCode NOTIFY codeUpdated)
public:
    explicit TotpGenerator(QObject *parent = nullptr);

    Q_INVOKABLE QString generateCode(const QString &secret);

    int timeLeft() const { return m_timeLeft; }
    QString currentCode() const { return m_currentCode; }

signals:
    void timeLeftChanged();
    void codeUpdated();

private slots:
    void updateTimer();

private:
    QByteArray hmacSha1(const QByteArray &key, const QByteArray &message);
    QByteArray base32Decode(const QString &secret);
    int dynamicTruncation(const QByteArray &hash);

    QString m_currentCode;
    int m_timeLeft;
    QTimer *m_timer;
    QString m_activeSecret;
};
