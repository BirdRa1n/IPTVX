// SPDX-License-Identifier: MIT
#include "storage/SourceRepository.h"

#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QTimeZone>
#include <QUuid>
#include <QVariant>

using namespace Qt::StringLiterals;

namespace iptvx {

namespace {

const QString kColumns = u"id, name, type, url, username, password, mac_address, user_agent, "
                         "epg_url, refresh_on_startup, created_at, updated_at"_s;

Source fromQuery(const QSqlQuery &q)
{
    Source s;
    s.id = q.value(0).toString();
    s.name = q.value(1).toString();
    s.type = static_cast<SourceType>(q.value(2).toInt());
    s.url = q.value(3).toString();
    s.username = q.value(4).toString();
    s.password = q.value(5).toString();
    s.macAddress = q.value(6).toString();
    s.userAgent = q.value(7).toString();
    s.epgUrl = q.value(8).toString();
    s.refreshOnStartup = q.value(9).toBool();
    s.createdAt = QDateTime::fromMSecsSinceEpoch(q.value(10).toLongLong(), QTimeZone::UTC);
    s.updatedAt = QDateTime::fromMSecsSinceEpoch(q.value(11).toLongLong(), QTimeZone::UTC);
    return s;
}

void bind(QSqlQuery &q, const Source &s)
{
    q.bindValue(u":id"_s, s.id);
    q.bindValue(u":name"_s, s.name);
    q.bindValue(u":type"_s, int(s.type));
    q.bindValue(u":url"_s, s.url);
    q.bindValue(u":username"_s, s.username);
    q.bindValue(u":password"_s, s.password);
    q.bindValue(u":mac"_s, s.macAddress);
    q.bindValue(u":ua"_s, s.userAgent);
    q.bindValue(u":epg"_s, s.epgUrl);
    q.bindValue(u":refresh"_s, s.refreshOnStartup ? 1 : 0);
    q.bindValue(u":created"_s, s.createdAt.toMSecsSinceEpoch());
    q.bindValue(u":updated"_s, s.updatedAt.toMSecsSinceEpoch());
}

} // namespace

SourceRepository::SourceRepository(QSqlDatabase db)
    : m_db(std::move(db))
{
}

QList<Source> SourceRepository::all() const
{
    QList<Source> result;
    QSqlQuery q(m_db);
    q.setForwardOnly(true);
    if (!q.exec(u"SELECT "_s + kColumns + u" FROM sources ORDER BY created_at"_s))
        return result;
    while (q.next())
        result.append(fromQuery(q));
    return result;
}

std::optional<Source> SourceRepository::find(const QString &id) const
{
    QSqlQuery q(m_db);
    q.prepare(u"SELECT "_s + kColumns + u" FROM sources WHERE id = :id"_s);
    q.bindValue(u":id"_s, id);
    if (q.exec() && q.next())
        return fromQuery(q);
    return std::nullopt;
}

std::optional<Source> SourceRepository::insert(Source source)
{
    if (source.id.isEmpty())
        source.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const auto now = QDateTime::currentDateTimeUtc();
    if (!source.createdAt.isValid())
        source.createdAt = now;
    source.updatedAt = now;

    QSqlQuery q(m_db);
    q.prepare(u"INSERT INTO sources ("_s + kColumns
              + u") VALUES (:id, COALESCE(:name, ''), :type, :url, "
                "COALESCE(:username, ''), COALESCE(:password, ''), COALESCE(:mac, ''), "
                "COALESCE(:ua, ''), COALESCE(:epg, ''), :refresh, :created, :updated)"_s);
    // Null QStrings bind as SQL NULL; the statement maps them to ''.
    bind(q, source);
    if (!q.exec()) {
        qWarning("SourceRepository::insert failed: %s", qPrintable(q.lastError().text()));
        return std::nullopt;
    }
    return source;
}

bool SourceRepository::update(Source source)
{
    source.updatedAt = QDateTime::currentDateTimeUtc();
    QSqlQuery q(m_db);
    q.prepare(u"UPDATE sources SET name = COALESCE(:name, ''), type = :type, url = :url, "
              "username = COALESCE(:username, ''), password = COALESCE(:password, ''), "
              "mac_address = COALESCE(:mac, ''), user_agent = COALESCE(:ua, ''), "
              "epg_url = COALESCE(:epg, ''), "
              "refresh_on_startup = :refresh, created_at = :created, updated_at = :updated "
              "WHERE id = :id"_s);
    bind(q, source);
    return q.exec() && q.numRowsAffected() == 1;
}

bool SourceRepository::remove(const QString &id)
{
    QSqlQuery q(m_db);
    q.prepare(u"DELETE FROM sources WHERE id = :id"_s);
    q.bindValue(u":id"_s, id);
    return q.exec() && q.numRowsAffected() == 1;
}

} // namespace iptvx
