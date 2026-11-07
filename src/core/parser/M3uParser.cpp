// SPDX-License-Identifier: MIT
#include "parser/M3uParser.h"

#include <QBuffer>
#include <QIODevice>

namespace iptvx {

namespace {

constexpr QByteArrayView kExtM3u = "#EXTM3U";
constexpr QByteArrayView kExtInf = "#EXTINF:";
constexpr QByteArrayView kExtGrp = "#EXTGRP:";
constexpr QByteArrayView kExtVlcOpt = "#EXTVLCOPT:";
constexpr QByteArrayView kUtf8Bom = "\xEF\xBB\xBF";

bool startsWithCI(QByteArrayView s, QByteArrayView prefix)
{
    return s.size() >= prefix.size() && s.first(prefix.size()).compare(prefix, Qt::CaseInsensitive) == 0;
}

bool equalsCI(QByteArrayView a, QByteArrayView b)
{
    return a.compare(b, Qt::CaseInsensitive) == 0;
}

/// Calls @p onAttribute(key, value) for every `key="value"` / `key=value`
/// pair and returns the title (text after the first unquoted comma).
template<typename Fn>
QByteArrayView parseAttributes(QByteArrayView s, Fn &&onAttribute)
{
    const qsizetype n = s.size();
    qsizetype i = 0;
    while (i < n) {
        while (i < n && s[i] == ' ')
            ++i;
        if (i >= n)
            break;
        if (s[i] == ',')
            return s.sliced(i + 1).trimmed();

        const qsizetype keyStart = i;
        while (i < n && s[i] != '=' && s[i] != ' ' && s[i] != ',')
            ++i;
        const QByteArrayView key = s.sliced(keyStart, i - keyStart);
        if (i >= n || s[i] != '=')
            continue; // bare token (e.g. the duration): ignore

        ++i; // skip '='
        QByteArrayView value;
        if (i < n && (s[i] == '"' || s[i] == '\'')) {
            const char quote = s[i++];
            const qsizetype valueStart = i;
            while (i < n && s[i] != quote)
                ++i;
            value = s.sliced(valueStart, i - valueStart);
            if (i < n)
                ++i; // closing quote
        } else {
            const qsizetype valueStart = i;
            while (i < n && s[i] != ' ' && s[i] != ',')
                ++i;
            value = s.sliced(valueStart, i - valueStart);
        }
        onAttribute(key, value);
    }
    return {};
}

/// Splits `url|Header=value&Header2=value2` and reports the headers.
template<typename Fn>
QByteArrayView splitPipeHeaders(QByteArrayView line, Fn &&onHeader)
{
    const qsizetype pipe = line.indexOf('|');
    if (pipe < 0)
        return line;
    QByteArrayView rest = line.sliced(pipe + 1);
    while (!rest.isEmpty()) {
        const qsizetype amp = rest.indexOf('&');
        const QByteArrayView pair = amp < 0 ? rest : rest.first(amp);
        if (const qsizetype eq = pair.indexOf('='); eq > 0)
            onHeader(pair.first(eq).trimmed(), pair.sliced(eq + 1).trimmed());
        rest = amp < 0 ? QByteArrayView() : rest.sliced(amp + 1);
    }
    return line.first(pipe);
}

/// Pending entry between an #EXTINF line and its URL line. Owns copies,
/// because the line buffer is reused; capacity is retained across entries.
struct Pending
{
    QByteArray name;
    QByteArray tvgName;
    QByteArray logo;
    QByteArray tvgId;
    QByteArray group;
    QByteArray userAgent;
    QByteArray referrer;
    quint16 catchupDays = 0;
    bool radio = false;
    bool active = false;

    void reset()
    {
        for (QByteArray *f : { &name, &tvgName, &logo, &tvgId, &group, &userAgent, &referrer })
            f->resize(0); // keeps capacity
        catchupDays = 0;
        radio = false;
        active = false;
    }
};

class Parser
{
public:
    Parser()
        : m_store(std::make_shared<ChannelStore>())
    {
    }

    void reserveFor(qint64 bytes)
    {
        if (bytes <= 0)
            return;
        // Empirically ~1 channel per 250 bytes of playlist, ~55% of it text.
        m_store->reserve(qsizetype(bytes / 250), qsizetype(bytes * 55 / 100));
    }

    void feed(QByteArrayView line)
    {
        if (m_firstLine) {
            m_firstLine = false;
            if (line.startsWith(kUtf8Bom))
                line = line.sliced(kUtf8Bom.size());
        }
        line = line.trimmed();
        if (line.isEmpty())
            return;

        if (line.front() == '#') {
            directive(line);
            return;
        }
        // Plain (non-extended) playlists have URL lines without #EXTINF.
        commit(line);
    }

    M3uParseResult finish(bool cancelled)
    {
        m_store->squeeze();
        return { std::move(m_store), std::move(m_epgUrls), cancelled };
    }

private:
    void directive(QByteArrayView line)
    {
        if (startsWithCI(line, kExtInf)) {
            m_pending.reset();
            m_pending.active = true;
            const QByteArrayView title = parseAttributes(line.sliced(kExtInf.size()),
                [this](QByteArrayView key, QByteArrayView value) { attribute(key, value); });
            m_pending.name.assign(title);
        } else if (startsWithCI(line, kExtGrp)) {
            if (m_pending.group.isEmpty())
                m_pending.group.assign(line.sliced(kExtGrp.size()).trimmed());
        } else if (startsWithCI(line, kExtVlcOpt)) {
            const QByteArrayView opt = line.sliced(kExtVlcOpt.size());
            const qsizetype eq = opt.indexOf('=');
            if (eq > 0) {
                const QByteArrayView key = opt.first(eq);
                if (equalsCI(key, "http-user-agent"))
                    m_pending.userAgent.assign(opt.sliced(eq + 1));
                else if (equalsCI(key, "http-referrer") || equalsCI(key, "http-referer"))
                    m_pending.referrer.assign(opt.sliced(eq + 1));
            }
        } else if (startsWithCI(line, kExtM3u)) {
            parseAttributes(line.sliced(kExtM3u.size()), [this](QByteArrayView key, QByteArrayView value) {
                if (equalsCI(key, "url-tvg") || equalsCI(key, "x-tvg-url")) {
                    for (const QByteArray &url : value.toByteArray().split(','))
                        if (!url.trimmed().isEmpty())
                            m_epgUrls.append(QString::fromUtf8(url.trimmed()));
                }
            });
        }
        // Everything else (#KODIPROP, #EXTVLCOPT variants, comments) is ignored.
    }

    void attribute(QByteArrayView key, QByteArrayView value)
    {
        if (equalsCI(key, "tvg-id"))
            m_pending.tvgId.assign(value);
        else if (equalsCI(key, "tvg-name"))
            m_pending.tvgName.assign(value);
        else if (equalsCI(key, "tvg-logo"))
            m_pending.logo.assign(value);
        else if (equalsCI(key, "group-title"))
            m_pending.group.assign(value);
        else if (equalsCI(key, "user-agent") || equalsCI(key, "http-user-agent"))
            m_pending.userAgent.assign(value);
        else if (equalsCI(key, "http-referrer") || equalsCI(key, "referrer"))
            m_pending.referrer.assign(value);
        else if (equalsCI(key, "radio"))
            m_pending.radio = equalsCI(value, "true") || value == "1";
        else if (equalsCI(key, "catchup-days") || equalsCI(key, "timeshift"))
            m_pending.catchupDays = quint16(qBound(0, value.toInt(), 0xFFFF));
    }

    void commit(QByteArrayView line)
    {
        const QByteArrayView url = splitPipeHeaders(line, [this](QByteArrayView key, QByteArrayView value) {
            if (equalsCI(key, "User-Agent") && m_pending.userAgent.isEmpty())
                m_pending.userAgent.assign(value);
            else if ((equalsCI(key, "Referer") || equalsCI(key, "Referrer")) && m_pending.referrer.isEmpty())
                m_pending.referrer.assign(value);
        });

        QByteArrayView name = m_pending.name;
        if (name.isEmpty())
            name = m_pending.tvgName;
        if (name.isEmpty())
            name = url;

        m_store->append({ .name = name,
                          .url = url,
                          .logo = m_pending.logo,
                          .tvgId = m_pending.tvgId,
                          .group = m_pending.group,
                          .userAgent = m_pending.userAgent,
                          .referrer = m_pending.referrer,
                          .catchupDays = m_pending.catchupDays,
                          .radio = m_pending.radio });
        m_pending.reset();
    }

    std::shared_ptr<ChannelStore> m_store;
    QStringList m_epgUrls;
    Pending m_pending;
    bool m_firstLine = true;
};

} // namespace

M3uParseResult M3uParser::parse(QIODevice &device, const std::atomic_bool *cancel)
{
    Parser parser;
    if (!device.isSequential())
        parser.reserveFor(device.size() - device.pos());

    QByteArray line;
    line.reserve(4096);
    qsizetype count = 0;
    while (device.readLineInto(&line)) {
        parser.feed(line);
        // Check the cancel flag every 1024 lines: cheap and responsive.
        if (cancel && (++count & 0x3FF) == 0 && cancel->load(std::memory_order_relaxed))
            return parser.finish(true);
    }
    return parser.finish(false);
}

M3uParseResult M3uParser::parse(QByteArrayView data)
{
    QByteArray copy = QByteArray::fromRawData(data.data(), data.size());
    QBuffer buffer(&copy);
    buffer.open(QIODevice::ReadOnly);
    return parse(buffer);
}

} // namespace iptvx
