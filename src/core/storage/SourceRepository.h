// SPDX-License-Identifier: MIT
#pragma once

#include "model/Source.h"

#include <QList>
#include <QSqlDatabase>

#include <optional>

namespace iptvx {

/// CRUD access to configured sources.
///
/// Security note: credentials are stored in the local SQLite file in plain
/// text, like most IPTV players do. Moving them to the OS keychain is on the
/// roadmap (see docs/ROADMAP.md).
class SourceRepository
{
public:
    explicit SourceRepository(QSqlDatabase db);

    QList<Source> all() const;
    std::optional<Source> find(const QString &id) const;

    /// Inserts @p source, generating an id and timestamps when missing.
    /// Returns the stored source.
    std::optional<Source> insert(Source source);
    bool update(Source source);
    bool remove(const QString &id);

private:
    QSqlDatabase m_db;
};

} // namespace iptvx
