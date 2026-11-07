// SPDX-License-Identifier: MIT
#include "provider/XtreamClient.h"

#include <QFutureWatcher>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrlQuery>
#include <QtConcurrentRun>

using namespace Qt::StringLiterals;

namespace iptvx {

namespace xtream {

namespace {

QUrl baseUrl(const XtreamEndpoint &ep)
{
    QUrl url = ep.server;
    url.setPath({});
    url.setQuery(QString());
    url.setFragment({});
    return url;
}

QUrl streamUrl(const XtreamEndpoint &ep, const QString &kind, qint64 id, const QString &ext)
{
    QUrl url = baseUrl(ep);
    const QString file = ext.isEmpty() ? QString::number(id) : QString::number(id) + u'.' + ext;
    url.setPath(u"/%1/%2/%3/%4"_s.arg(kind, ep.username, ep.password, file));
    return url;
}

QString stringOf(const QJsonValue &v)
{
    // The API is loosely typed: ids/numbers arrive as strings or numbers.
    if (v.isString())
        return v.toString();
    if (v.isDouble())
        return QString::number(qint64(v.toDouble()));
    return {};
}

} // namespace

QUrl apiUrl(const XtreamEndpoint &ep, const QString &action,
            const QList<std::pair<QString, QString>> &params)
{
    QUrl url = baseUrl(ep);
    url.setPath(u"/player_api.php"_s);
    QUrlQuery query;
    query.addQueryItem(u"username"_s, ep.username);
    query.addQueryItem(u"password"_s, ep.password);
    if (!action.isEmpty())
        query.addQueryItem(u"action"_s, action);
    for (const auto &[key, value] : params)
        query.addQueryItem(key, value);
    url.setQuery(query);
    return url;
}

QUrl liveUrl(const XtreamEndpoint &ep, qint64 streamId, const QString &extension)
{
    return streamUrl(ep, u"live"_s, streamId, extension);
}

QUrl movieUrl(const XtreamEndpoint &ep, qint64 streamId, const QString &extension)
{
    return streamUrl(ep, u"movie"_s, streamId, extension);
}

QUrl episodeUrl(const XtreamEndpoint &ep, qint64 episodeId, const QString &extension)
{
    return streamUrl(ep, u"series"_s, episodeId, extension);
}

bool parseAccount(QByteArrayView json, XtreamAccount *account, QString *error)
{
    QJsonParseError parseError;
    const auto doc = QJsonDocument::fromJson(json.toByteArray(), &parseError);
    if (!doc.isObject()) {
        *error = u"Invalid server response: %1"_s.arg(parseError.errorString());
        return false;
    }
    const QJsonObject info = doc.object().value("user_info"_L1).toObject();
    if (info.value("auth"_L1).toInt(stringOf(info.value("auth"_L1)).toInt()) != 1) {
        *error = u"Invalid username or password"_s;
        return false;
    }
    account->status = info.value("status"_L1).toString();
    const qint64 exp = stringOf(info.value("exp_date"_L1)).toLongLong();
    account->expiresAt = exp > 0 ? QDateTime::fromSecsSinceEpoch(exp) : QDateTime();
    account->maxConnections = stringOf(info.value("max_connections"_L1)).toInt();
    account->activeConnections = stringOf(info.value("active_cons"_L1)).toInt();
    account->outputFormats.clear();
    for (const QJsonValue &f : info.value("allowed_output_formats"_L1).toArray())
        account->outputFormats.append(f.toString());
    return true;
}

std::shared_ptr<ChannelStore> buildLiveStore(QByteArrayView categoriesJson,
                                             QByteArrayView streamsJson,
                                             const XtreamEndpoint &ep)
{
    QHash<QString, QByteArray> categoryNames;
    {
        const auto categories = QJsonDocument::fromJson(categoriesJson.toByteArray()).array();
        categoryNames.reserve(categories.size());
        for (const QJsonValue &v : categories) {
            const QJsonObject c = v.toObject();
            categoryNames.insert(stringOf(c.value("category_id"_L1)),
                                 c.value("category_name"_L1).toString().toUtf8());
        }
    } // free the categories document before parsing the (larger) streams one

    auto store = std::make_shared<ChannelStore>();
    const auto streams = QJsonDocument::fromJson(streamsJson.toByteArray()).array();
    store->reserve(streams.size(), streams.size() * 96);

    QByteArray name, url, logo, tvgId; // reused conversion buffers
    for (const QJsonValue &v : streams) {
        const QJsonObject s = v.toObject();
        const qint64 id = stringOf(s.value("stream_id"_L1)).toLongLong();
        if (id <= 0)
            continue;
        name = s.value("name"_L1).toString().toUtf8();
        url = liveUrl(ep, id).toEncoded();
        logo = s.value("stream_icon"_L1).toString().toUtf8();
        tvgId = s.value("epg_channel_id"_L1).toString().toUtf8();
        const QByteArray group = categoryNames.value(stringOf(s.value("category_id"_L1)));
        store->append({ .name = name,
                        .url = url,
                        .logo = logo,
                        .tvgId = tvgId,
                        .group = group,
                        .catchupDays = quint16(qBound(0, stringOf(s.value("tv_archive_duration"_L1)).toInt(), 0xFFFF)) });
    }
    store->squeeze();
    return store;
}

} // namespace xtream

XtreamClient::XtreamClient(QNetworkAccessManager *network, XtreamEndpoint endpoint, QObject *parent)
    : QObject(parent)
    , m_network(network)
    , m_endpoint(std::move(endpoint))
{
}

void XtreamClient::get(const QUrl &url, std::function<void(QByteArray, QString)> done)
{
    if (!m_network) {
        done({}, u"Network unavailable"_s);
        return;
    }
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(30'000);
    QNetworkReply *reply = m_network->get(request);
    m_inFlight.append(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, done = std::move(done)] {
        reply->deleteLater();
        m_inFlight.removeAll(reply);
        if (reply->error() == QNetworkReply::OperationCanceledError)
            return; // aborted: stay silent
        if (reply->error() != QNetworkReply::NoError) {
            done({}, reply->errorString());
            return;
        }
        done(reply->readAll(), {});
    });
}

void XtreamClient::authenticate(Callback<XtreamAccount> done)
{
    get(xtream::apiUrl(m_endpoint), [done = std::move(done)](QByteArray body, QString error) {
        XtreamAccount account;
        if (error.isEmpty())
            xtream::parseAccount(body, &account, &error);
        done(std::move(account), std::move(error));
    });
}

void XtreamClient::fetchLiveChannels(Callback<std::shared_ptr<ChannelStore>> done)
{
    get(xtream::apiUrl(m_endpoint, u"get_live_categories"_s),
        [this, done = std::move(done)](QByteArray categories, QString error) mutable {
            if (!error.isEmpty()) {
                done(nullptr, std::move(error));
                return;
            }
            get(xtream::apiUrl(m_endpoint, u"get_live_streams"_s),
                [this, categories = std::move(categories), done = std::move(done)](QByteArray streams, QString err) mutable {
                    if (!err.isEmpty()) {
                        done(nullptr, std::move(err));
                        return;
                    }
                    auto *watcher = new QFutureWatcher<std::shared_ptr<ChannelStore>>(this);
                    connect(watcher, &QFutureWatcherBase::finished, this, [watcher, done = std::move(done)] {
                        watcher->deleteLater();
                        done(watcher->result(), {});
                    });
                    watcher->setFuture(QtConcurrent::run(
                        [categories = std::move(categories), streams = std::move(streams), ep = m_endpoint] {
                            return xtream::buildLiveStore(categories, streams, ep);
                        }));
                });
        });
}

void XtreamClient::abort()
{
    const auto replies = std::exchange(m_inFlight, {});
    for (const auto &reply : replies)
        if (reply)
            reply->abort();
}

} // namespace iptvx
