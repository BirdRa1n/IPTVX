// SPDX-License-Identifier: MIT
#include "model/ChannelStore.h"

#include <limits>

namespace iptvx {

ChannelStore::ChannelStore() = default;

void ChannelStore::reserve(qsizetype channels, qsizetype textBytes)
{
    m_records.reserve(size_t(channels));
    m_arena.reserve(textBytes);
}

ChannelStore::Span ChannelStore::store(QByteArrayView utf8)
{
    utf8 = utf8.trimmed();
    if (utf8.isEmpty())
        return {};
    // The arena is addressed with 32-bit offsets (4 GiB of text), far beyond
    // any real playlist. Refuse to grow past it rather than wrap around.
    constexpr auto kMax = qsizetype(std::numeric_limits<quint32>::max());
    if (m_arena.size() + utf8.size() > kMax)
        return {};
    const Span span { quint32(m_arena.size()), quint32(utf8.size()) };
    m_arena.append(utf8);
    return span;
}

ChannelStore::Index ChannelStore::append(const ChannelInput &channel)
{
    Record r;
    r.name = store(channel.name);
    r.url = store(channel.url);
    r.logo = store(channel.logo);
    r.tvgId = store(channel.tvgId);
    r.group = m_groups.intern(channel.group.trimmed());
    r.userAgent = m_userAgents.intern(channel.userAgent.trimmed());
    r.referrer = m_referrers.intern(channel.referrer.trimmed());
    r.catchupDays = channel.catchupDays;
    r.flags = channel.radio ? kFlagRadio : 0;
    m_records.push_back(r);
    return Index(m_records.size() - 1);
}

void ChannelStore::squeeze()
{
    m_arena.squeeze();
    m_records.shrink_to_fit();
    m_groups.freeze();
    m_userAgents.freeze();
    m_referrers.freeze();
}

qsizetype ChannelStore::memoryFootprint() const
{
    return m_arena.capacity() + qsizetype(m_records.capacity() * sizeof(Record))
        + m_groups.memoryFootprint() + m_userAgents.memoryFootprint()
        + m_referrers.memoryFootprint();
}

} // namespace iptvx
