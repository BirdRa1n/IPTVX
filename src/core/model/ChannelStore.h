// SPDX-License-Identifier: MIT
#pragma once

#include "util/StringTable.h"

#include <QByteArray>
#include <QString>

#include <memory>
#include <vector>

namespace iptvx {

/// Borrowed view of one channel, used to append to a ChannelStore without
/// allocating intermediate QStrings. All views are UTF-8.
struct ChannelInput
{
    QByteArrayView name;
    QByteArrayView url;
    QByteArrayView logo;
    QByteArrayView tvgId;
    QByteArrayView group;
    QByteArrayView userAgent;
    QByteArrayView referrer;
    quint16 catchupDays = 0;
    bool radio = false;
};

/// Compact, append-only, columnar storage for a playlist's channels.
///
/// Memory layout
/// -------------
/// * Free-form text (name, url, logo, tvg-id) is appended to one contiguous
///   UTF-8 arena and referenced by (offset, length) spans. UTF-8 is roughly
///   half the size of QString's UTF-16 for the mostly-ASCII content of a
///   playlist, and one buffer avoids a heap allocation (plus its ~32 byte
///   header) for every field of every channel.
/// * Highly repetitive values (group, user agent, referrer) are interned in
///   StringTables and referenced by 16-bit ids.
/// * A channel record is therefore a fixed 44 bytes plus its unique text.
///
/// QStrings are only materialised on demand (for the rows currently shown by
/// a view), so a 100 000-channel playlist costs a few megabytes instead of
/// tens of megabytes.
///
/// Thread-safety: a store is built on a worker thread and then published as
/// `std::shared_ptr<const ChannelStore>`; const access is safe from any
/// thread.
class ChannelStore
{
public:
    using Index = quint32;

    ChannelStore();

    /// Pre-allocates space; @p textBytes is a hint for the UTF-8 arena.
    void reserve(qsizetype channels, qsizetype textBytes);

    /// Appends a channel and returns its index.
    Index append(const ChannelInput &channel);

    /// Releases slack capacity and the interning hashes. Call once the store
    /// is complete; appending afterwards still works but is slower.
    void squeeze();

    qsizetype size() const { return qsizetype(m_records.size()); }
    bool isEmpty() const { return m_records.empty(); }

    QString name(Index i) const { return text(m_records[i].name); }
    QString url(Index i) const { return text(m_records[i].url); }
    QString logo(Index i) const { return text(m_records[i].logo); }
    QString tvgId(Index i) const { return text(m_records[i].tvgId); }

    QByteArrayView nameUtf8(Index i) const { return view(m_records[i].name); }
    QByteArrayView urlUtf8(Index i) const { return view(m_records[i].url); }

    StringTable::Id groupId(Index i) const { return m_records[i].group; }
    const QString &group(Index i) const { return m_groups.value(m_records[i].group); }
    const QString &userAgent(Index i) const { return m_userAgents.value(m_records[i].userAgent); }
    const QString &referrer(Index i) const { return m_referrers.value(m_records[i].referrer); }
    quint16 catchupDays(Index i) const { return m_records[i].catchupDays; }
    bool isRadio(Index i) const { return m_records[i].flags & kFlagRadio; }

    /// All distinct groups; id 0 is the "ungrouped" empty string.
    const StringTable &groups() const { return m_groups; }

    /// Approximate heap bytes owned by this store (diagnostics only).
    qsizetype memoryFootprint() const;

private:
    struct Span
    {
        quint32 offset = 0;
        quint32 length = 0;
    };

    struct Record
    {
        Span name;
        Span url;
        Span logo;
        Span tvgId;
        StringTable::Id group = 0;
        StringTable::Id userAgent = 0;
        StringTable::Id referrer = 0;
        quint16 catchupDays = 0;
        quint8 flags = 0;
    };
    static_assert(sizeof(Record) <= 44, "keep the per-channel record compact");

    static constexpr quint8 kFlagRadio = 0x1;

    Span store(QByteArrayView utf8);
    QByteArrayView view(Span s) const { return QByteArrayView(m_arena).sliced(s.offset, s.length); }
    QString text(Span s) const { return QString::fromUtf8(view(s)); }

    QByteArray m_arena;
    std::vector<Record> m_records;
    StringTable m_groups;
    StringTable m_userAgents;
    StringTable m_referrers;
};

using ChannelStorePtr = std::shared_ptr<const ChannelStore>;

} // namespace iptvx
