// SPDX-License-Identifier: MIT
#include "storage/Database.h"

#include <QDir>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>

#include <array>

using namespace Qt::StringLiterals;

namespace iptvx {

namespace {

// Each entry migrates the schema from version (index) to (index + 1).
// NEVER edit a released migration: append a new one instead.
constexpr std::array kMigrations = {
    // v1: sources, favorites, watch history
    R"SQL(
    CREATE TABLE IF NOT EXISTS sources (
        id                 TEXT PRIMARY KEY,
        name               TEXT NOT NULL,
        type               INTEGER NOT NULL,
        url                TEXT NOT NULL,
        username           TEXT NOT NULL DEFAULT '',
        password           TEXT NOT NULL DEFAULT '',
        mac_address        TEXT NOT NULL DEFAULT '',
        user_agent         TEXT NOT NULL DEFAULT '',
        epg_url            TEXT NOT NULL DEFAULT '',
        refresh_on_startup INTEGER NOT NULL DEFAULT 0,
        created_at         INTEGER NOT NULL,
        updated_at         INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS favorites (
        source_id   TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
        stream_url  TEXT NOT NULL,
        name        TEXT NOT NULL,
        logo        TEXT NOT NULL DEFAULT '',
        position    INTEGER NOT NULL DEFAULT 0,
        created_at  INTEGER NOT NULL,
        PRIMARY KEY (source_id, stream_url)
    );
    CREATE TABLE IF NOT EXISTS history (
        source_id   TEXT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
        stream_url  TEXT NOT NULL,
        name        TEXT NOT NULL,
        logo        TEXT NOT NULL DEFAULT '',
        position_ms INTEGER NOT NULL DEFAULT 0,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        watched_at  INTEGER NOT NULL,
        PRIMARY KEY (source_id, stream_url)
    );
    CREATE INDEX IF NOT EXISTS idx_history_watched ON history(watched_at DESC);
    )SQL",
};

bool execScript(QSqlDatabase &db, const char *script, QString *error)
{
    const QStringList statements = QString::fromUtf8(script).split(u';', Qt::SkipEmptyParts);
    QSqlQuery query(db);
    for (const QString &raw : statements) {
        const QString sql = raw.trimmed();
        if (sql.isEmpty())
            continue;
        if (!query.exec(sql)) {
            *error = query.lastError().text();
            return false;
        }
    }
    return true;
}

} // namespace

Database::Database(QString connectionName)
    : m_connectionName(std::move(connectionName))
{
}

Database::~Database()
{
    close();
}

int Database::schemaVersion()
{
    return int(kMigrations.size());
}

QString Database::defaultPath()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    return dir + u"/iptvx.db"_s;
}

QSqlDatabase Database::connection() const
{
    return QSqlDatabase::database(m_connectionName, false);
}

bool Database::open(const QString &path)
{
    auto db = QSqlDatabase::addDatabase(u"QSQLITE"_s, m_connectionName);
    db.setDatabaseName(path);
    if (!db.open()) {
        m_lastError = db.lastError().text();
        return false;
    }

    QSqlQuery pragma(db);
    pragma.exec(u"PRAGMA foreign_keys = ON"_s);
    pragma.exec(u"PRAGMA journal_mode = WAL"_s);
    pragma.exec(u"PRAGMA synchronous = NORMAL"_s);
    // Keep SQLite's page cache small (negative = KiB): the app reads little
    // data from it and every MiB counts on low-memory devices.
    pragma.exec(u"PRAGMA cache_size = -2048"_s);
    pragma.exec(u"PRAGMA temp_store = MEMORY"_s);

    return migrate();
}

void Database::close()
{
    if (!QSqlDatabase::contains(m_connectionName))
        return;
    {
        auto db = QSqlDatabase::database(m_connectionName, false);
        if (db.isOpen())
            db.close();
    }
    QSqlDatabase::removeDatabase(m_connectionName);
}

bool Database::migrate()
{
    auto db = connection();
    QSqlQuery query(db);
    query.exec(u"PRAGMA user_version"_s);
    const int current = query.next() ? query.value(0).toInt() : 0;

    for (int version = current; version < schemaVersion(); ++version) {
        if (!db.transaction()) {
            m_lastError = db.lastError().text();
            return false;
        }
        if (!execScript(db, kMigrations[size_t(version)], &m_lastError)
            || !QSqlQuery(db).exec(u"PRAGMA user_version = %1"_s.arg(version + 1))) {
            db.rollback();
            return false;
        }
        if (!db.commit()) {
            m_lastError = db.lastError().text();
            return false;
        }
    }
    return true;
}

} // namespace iptvx
