#include "totp.h"
#include <QtMath>
#include <QLoggingCategory>

TotpGenerator::TotpGenerator(QObject *parent)
    : QObject(parent), m_timeLeft(30), m_timer(new QTimer(this))
{
    connect(m_timer, &QTimer::timeout, this, &TotpGenerator::updateTimer);
    m_timer->start(1000);
    updateTimer();
}

void TotpGenerator::updateTimer() {
    qint64 now = QDateTime::currentSecsSinceEpoch();
    int step = 30;
    int counter = now / step;
    m_timeLeft = step - (now % step);

    emit timeLeftChanged();

    if (!m_activeSecret.isEmpty() && m_timeLeft == 30) {
        generateCode(m_activeSecret);
    } else if (!m_activeSecret.isEmpty()) {
        emit codeUpdated();
    }
}

QString TotpGenerator::generateCode(const QString &secret)
{
    m_activeSecret = secret;
    QByteArray key = base32Decode(secret.toUpper().remove(" "));
    if (key.isEmpty()) {
        m_currentCode = "ERROR";
        emit codeUpdated();
        return m_currentCode;
    }

    qint64 now = QDateTime::currentSecsSinceEpoch();
    int64_t counter = now / 30;

    QByteArray msg;
    msg.resize(8);
    for (int i = 7; i >= 0; --i) {
        msg[i] = counter & 0xff;
        counter >>= 8;
    }

    QByteArray hash = hmacSha1(key, msg);
    int codeInt = dynamicTruncation(hash);
    QString code = QString::number(codeInt % 1000000).rightJustified(6, '0');

    m_currentCode = code;
    emit codeUpdated();
    return code;
}

QByteArray TotpGenerator::hmacSha1(const QByteArray &key, const QByteArray &message)
{
    const int blockSize = 64;
    QByteArray k = key;

    if (k.length() > blockSize) {
        k = QCryptographicHash::hash(k, QCryptographicHash::Sha1);
    }
    if (k.length() < blockSize) {
        k.fill('\x00', blockSize - k.length());
    }

    QByteArray oKeyPad = k;
    QByteArray iKeyPad = k;
    for (int i = 0; i < blockSize; i++) {
        oKeyPad[i] ^= 0x5c;
        iKeyPad[i] ^= 0x36;
    }

    QByteArray innerHash = QCryptographicHash::hash(iKeyPad + message, QCryptographicHash::Sha1);
    return QCryptographicHash::hash(oKeyPad + innerHash, QCryptographicHash::Sha1);
}

QByteArray TotpGenerator::base32Decode(const QString &secret)
{
    static const QString base32Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    QByteArray result;
    QString cleanSecret = secret;

    // Убираем паддинг (=)
    cleanSecret.remove('=');

    int buffer = 0;
    int bitsLeft = 0;

    for (const QChar &c : cleanSecret) {
        int val = base32Chars.indexOf(c.toUpper());
        if (val == -1) continue;

        buffer = (buffer << 5) | val;
        bitsLeft += 5;

        if (bitsLeft >= 8) {
            bitsLeft -= 8;
            result.append((buffer >> bitsLeft) & 0xFF);
        }
    }
    return result;
}

int TotpGenerator::dynamicTruncation(const QByteArray &hash)
{
    if (hash.size() < 20) return 0;

    int offset = hash[19] & 0x0F;
    int binary =
        ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    return binary;
}
