// SPDX-License-Identifier: MIT
#pragma once

#include "model/ChannelStore.h"

#include <QStringList>

#include <atomic>
#include <memory>

class QIODevice;

namespace iptvx {

/// Result of parsing an M3U / M3U8 playlist.
struct M3uParseResult
{
    std::shared_ptr<ChannelStore> channels;
    /// XMLTV guide URLs announced in the #EXTM3U header (url-tvg / x-tvg-url).
    QStringList epgUrls;
    /// True when parsing stopped because the cancel flag was raised.
    bool cancelled = false;
};

/// Streaming parser for extended M3U playlists.
///
/// The device is read line by line into one reused buffer, so peak memory is
/// the size of the resulting ChannelStore plus one line - never the whole
/// file. Supported directives:
///
/// * `#EXTM3U url-tvg="…" x-tvg-url="…"`
/// * `#EXTINF:<duration> tvg-id="…" tvg-name="…" tvg-logo="…" group-title="…"
///   radio="true" catchup-days="…" user-agent="…" http-referrer="…",Title`
/// * `#EXTGRP:<group>`
/// * `#EXTVLCOPT:http-user-agent=…` / `#EXTVLCOPT:http-referrer=…`
/// * Kodi style pipe headers: `http://host/stream|User-Agent=…&Referer=…`
///
/// Unknown directives and comments are ignored. There is deliberately no URL
/// validation: any non-comment line after an entry becomes its URL.
class M3uParser
{
public:
    static M3uParseResult parse(QIODevice &device, const std::atomic_bool *cancel = nullptr);
    static M3uParseResult parse(QByteArrayView data);
};

} // namespace iptvx
