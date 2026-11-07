// SPDX-License-Identifier: MIT
#pragma once

#include "model/ChannelStore.h"

#include <QDateTime>
#include <QObject>
#include <QPointer>
#include <QUrl>

#include <functional>

class QNetworkAccessManager;
class QNetworkReply;

namespace iptvx {

/// Account details returned by `player_api.php` without an action.
struct XtreamAccount
{
    QString status;      ///< e.g. "Active"
    QDateTime expiresAt; ///< invalid when unlimited
    int maxConnections = 0;
    int activeConnections = 0;
    QStringList outputFormats; ///< e.g. ["m3u8", "ts"]
};

/// Credentials + endpoint of an Xtream Codes server.
struct XtreamEndpoint
{
    QUrl server; ///< scheme://host[:port] (any path is ignored)
    QString username;
    QString password;
};

/// Pure helpers for the Xtream Codes API (no I/O, unit-testable).
namespace xtream {

QUrl apiUrl(const XtreamEndpoint &ep, const QString &action = {},
            const QList<std::pair<QString, QString>> &params = {});
QUrl liveUrl(const XtreamEndpoint &ep, qint64 streamId, const QString &extension = QStringLiteral("m3u8"));
QUrl movieUrl(const XtreamEndpoint &ep, qint64 streamId, const QString &extension);
QUrl episodeUrl(const XtreamEndpoint &ep, qint64 episodeId, const QString &extension);

/// Parses the account block of the authentication response.
/// Returns false when the credentials were rejected or the JSON is invalid.
bool parseAccount(QByteArrayView json, XtreamAccount *account, QString *error);

/// Builds a ChannelStore from `get_live_categories` and `get_live_streams`
/// JSON payloads. Intended to run on a worker thread.
std::shared_ptr<ChannelStore> buildLiveStore(QByteArrayView categoriesJson,
                                             QByteArrayView streamsJson,
                                             const XtreamEndpoint &ep);

} // namespace xtream

/// Asynchronous Xtream Codes client.
///
/// Callbacks run on the thread that owns the client. Heavy JSON → store
/// conversion is moved to the global thread pool so the UI never stalls.
class XtreamClient : public QObject
{
    Q_OBJECT

public:
    template<typename T>
    using Callback = std::function<void(T value, QString error)>;

    XtreamClient(QNetworkAccessManager *network, XtreamEndpoint endpoint, QObject *parent = nullptr);

    const XtreamEndpoint &endpoint() const { return m_endpoint; }

    void authenticate(Callback<XtreamAccount> done);
    void fetchLiveChannels(Callback<std::shared_ptr<ChannelStore>> done);

    /// Aborts every request in flight; their callbacks are not invoked.
    void abort();

private:
    void get(const QUrl &url, std::function<void(QByteArray body, QString error)> done);

    QPointer<QNetworkAccessManager> m_network;
    XtreamEndpoint m_endpoint;
    QList<QPointer<QNetworkReply>> m_inFlight;
};

} // namespace iptvx
