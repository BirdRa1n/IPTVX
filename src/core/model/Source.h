// SPDX-License-Identifier: MIT
#pragma once

#include <QDateTime>
#include <QString>

namespace iptvx {

/// Kind of content provider a source talks to.
enum class SourceType : quint8 {
    M3uFile = 0, ///< Local .m3u/.m3u8 file
    M3uUrl = 1,  ///< Remote .m3u/.m3u8 URL
    Xtream = 2,  ///< Xtream Codes player_api.php
    Stalker = 3, ///< Stalker / Ministra portal (MAC based)
};

/// A user-configured playlist or provider account.
///
/// Only the definition is kept here; the (potentially huge) channel catalog
/// lives in a ChannelStore loaded on demand.
struct Source
{
    QString id; ///< Stable UUID (without braces)
    QString name;
    SourceType type = SourceType::M3uUrl;
    QString url;      ///< File path, playlist URL, server URL or portal URL
    QString username; ///< Xtream only
    QString password; ///< Xtream only
    QString macAddress; ///< Stalker only
    QString userAgent;  ///< Optional HTTP User-Agent override
    QString epgUrl;     ///< Optional XMLTV URL override
    bool refreshOnStartup = false;
    QDateTime createdAt;
    QDateTime updatedAt;

    bool isValid() const { return !id.isEmpty() && !url.isEmpty(); }
};

} // namespace iptvx
