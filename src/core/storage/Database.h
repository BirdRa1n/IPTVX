// SPDX-License-Identifier: MIT
#pragma once

#include <QSqlDatabase>
#include <QString>

namespace iptvx {

/// Owns the application's SQLite connection and its schema migrations.
///
/// * One connection per Database instance, used from the thread that opened
///   it (Qt SQL connections are not thread-safe).
/// * WAL journaling + NORMAL synchronous for fast, crash-safe writes.
/// * Schema version is tracked in `PRAGMA user_version`; migrations are
///   applied in order, each in its own transaction, and are safe to rerun.
class Database
{
public:
    explicit Database(QString connectionName = QStringLiteral("iptvx"));
    ~Database();

    Database(const Database &) = delete;
    Database &operator=(const Database &) = delete;

    /// Opens (creating if needed) @p path and migrates it. Pass ":memory:"
    /// for an in-memory database (tests).
    bool open(const QString &path);
    void close();

    QSqlDatabase connection() const;
    QString lastError() const { return m_lastError; }

    /// Latest schema version known to this build.
    static int schemaVersion();

    /// Default on-disk location (QStandardPaths::AppDataLocation).
    static QString defaultPath();

private:
    bool migrate();

    QString m_connectionName;
    QString m_lastError;
};

} // namespace iptvx
