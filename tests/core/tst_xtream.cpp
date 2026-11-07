// SPDX-License-Identifier: MIT
#include "provider/XtreamClient.h"

#include <QFile>
#include <QTest>
#include <QUrlQuery>

using namespace Qt::StringLiterals;
using namespace iptvx;

namespace {

QByteArray fixture(const char *name)
{
    QFile file(QString::fromUtf8(IPTVX_TEST_DATA_DIR "/xtream/") + QString::fromUtf8(name));
    return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
}

const XtreamEndpoint ep { QUrl(u"http://provider.example.com:8080/some/path?x=1"_s), u"demo"_s, u"secret"_s };
} // namespace

class TestXtream : public QObject
{
    Q_OBJECT

private slots:
    void buildsApiUrl()
    {
        const QUrl url = xtream::apiUrl(ep, u"get_live_streams"_s, { { u"category_id"_s, u"5"_s } });
        QCOMPARE(url.host(), u"provider.example.com"_s);
        QCOMPARE(url.port(), 8080);
        QCOMPARE(url.path(), u"/player_api.php"_s);
        const QUrlQuery q(url);
        QCOMPARE(q.queryItemValue(u"username"_s), u"demo"_s);
        QCOMPARE(q.queryItemValue(u"password"_s), u"secret"_s);
        QCOMPARE(q.queryItemValue(u"action"_s), u"get_live_streams"_s);
        QCOMPARE(q.queryItemValue(u"category_id"_s), u"5"_s);
    }

    void buildsStreamUrls()
    {
        QCOMPARE(xtream::liveUrl(ep, 42).toString(), u"http://provider.example.com:8080/live/demo/secret/42.m3u8"_s);
        QCOMPARE(xtream::movieUrl(ep, 7, u"mkv"_s).toString(), u"http://provider.example.com:8080/movie/demo/secret/7.mkv"_s);
        QCOMPARE(xtream::episodeUrl(ep, 9, u"mp4"_s).toString(), u"http://provider.example.com:8080/series/demo/secret/9.mp4"_s);
    }

    void parsesAccount()
    {
        XtreamAccount account;
        QString error;
        QVERIFY(xtream::parseAccount(fixture("account.json"), &account, &error));
        QCOMPARE(account.status, u"Active"_s);
        QCOMPARE(account.maxConnections, 2);
        QCOMPARE(account.expiresAt.toSecsSinceEpoch(), 1893456000);
        QCOMPARE(account.outputFormats, QStringList({ u"m3u8"_s, u"ts"_s }));
    }

    void rejectsBadCredentials()
    {
        XtreamAccount account;
        QString error;
        QVERIFY(!xtream::parseAccount(fixture("account_denied.json"), &account, &error));
        QVERIFY(!error.isEmpty());
        QVERIFY(!xtream::parseAccount("not json", &account, &error));
    }

    void buildsLiveStore()
    {
        const auto store = xtream::buildLiveStore(fixture("live_categories.json"), fixture("live_streams.json"), ep);
        QCOMPARE(store->size(), 2);
        QCOMPARE(store->name(0), u"News One"_s);
        QCOMPARE(store->group(0), u"News"_s);
        QCOMPARE(store->tvgId(0), u"news.one"_s);
        QCOMPARE(store->catchupDays(0), quint16(3));
        QCOMPARE(store->url(1), u"http://provider.example.com:8080/live/demo/secret/102.m3u8"_s);
        QCOMPARE(store->group(1), u"Sports"_s);
    }
};

QTEST_APPLESS_MAIN(TestXtream)
#include "tst_xtream.moc"
