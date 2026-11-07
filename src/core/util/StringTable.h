// SPDX-License-Identifier: MIT
#pragma once

#include <QHash>
#include <QString>

#include <vector>

namespace iptvx {

/// Deduplicating table of short strings addressed by a 16-bit id.
///
/// Playlists repeat the same handful of values (group titles, user agents,
/// referrers) across tens of thousands of entries. Storing each value once
/// and referencing it by a 2-byte id instead of a 24-byte QString per entry
/// keeps the per-channel footprint small.
///
/// Id 0 is always the empty string. When the table is full every new value
/// maps to id 0, so callers never have to handle an overflow error.
class StringTable
{
public:
    using Id = quint16;
    static constexpr Id kEmpty = 0;
    static constexpr qsizetype kCapacity = 0xFFFF;

    StringTable() { m_values.emplace_back(); }

    /// Returns the id for @p utf8, inserting it when unseen.
    Id intern(QByteArrayView utf8)
    {
        if (utf8.isEmpty())
            return kEmpty;
        const QString value = QString::fromUtf8(utf8);
        if (const auto it = m_index.constFind(value); it != m_index.cend())
            return *it;
        if (qsizetype(m_values.size()) >= kCapacity)
            return kEmpty;
        const auto id = static_cast<Id>(m_values.size());
        m_values.push_back(value);
        m_index.insert(value, id);
        return id;
    }

    /// Returns the shared string for @p id (no allocation: QString is
    /// implicitly shared).
    const QString &value(Id id) const
    {
        return id < m_values.size() ? m_values[id] : m_values.front();
    }

    qsizetype size() const { return qsizetype(m_values.size()); }
    const std::vector<QString> &values() const { return m_values; }

    /// Releases the lookup hash once no more values will be interned.
    void freeze()
    {
        m_index = {};
        m_values.shrink_to_fit();
    }

    qsizetype memoryFootprint() const
    {
        qsizetype bytes = qsizetype(m_values.capacity() * sizeof(QString));
        for (const QString &v : m_values)
            bytes += v.capacity() * qsizetype(sizeof(QChar));
        bytes += m_index.capacity() * qsizetype(sizeof(QString) + sizeof(Id));
        return bytes;
    }

private:
    std::vector<QString> m_values;
    QHash<QString, Id> m_index;
};

} // namespace iptvx
