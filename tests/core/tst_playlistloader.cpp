// SPDX-License-Identifier: MIT
#include "service/PlaylistLoader.h"

#include <QNetworkAccessManager>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

using namespace Qt::StringLiterals;
using namespace iptvx;

class TestPlaylistLoader : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase() { qRegisterMetaType<iptvx::ChannelStorePtr>(); }

    void loadsLocalFile()
    {
        QTemporaryDir cache;
        QNetworkAccessManager nam;
        PlaylistLoader loader(&nam, cache.path());
        QSignalSpy loaded(&loader, &PlaylistLoader::loaded);

        Source source;
        source.id = u"local"_s;
        source.type = SourceType::M3uFile;
        source.url = QStringLiteral(IPTVX_TEST_DATA_DIR "/sample.m3u");
        loader.load(source);
        QVERIFY(loader.isBusy());
        QVERIFY(loaded.wait(5000));
        QVERIFY(!loader.isBusy());

        const auto args = loaded.takeFirst();
        QCOMPARE(args.at(0).toString(), u"local"_s);
        const auto store = args.at(1).value<ChannelStorePtr>();
        QVERIFY(store);
        QCOMPARE(store->size(), 6);
        QCOMPARE(args.at(2).toStringList().size(), 2);
    }

    void reportsMissingFile()
    {
        QTemporaryDir cache;
        PlaylistLoader loader(nullptr, cache.path());
        QSignalSpy failed(&loader, &PlaylistLoader::failed);
        Source source;
        source.id = u"missing"_s;
        source.type = SourceType::M3uFile;
        source.url = cache.filePath(u"does-not-exist.m3u"_s);
        loader.load(source);
        QVERIFY(failed.wait(5000));
    }

    void usesCachedCopyForUrls()
    {
        QTemporaryDir cache;
        PlaylistLoader loader(nullptr, cache.path()); // no network: must hit cache
        QVERIFY(QFile::copy(QStringLiteral(IPTVX_TEST_DATA_DIR "/sample.m3u"), loader.cachePath(u"remote"_s)));
        QSignalSpy loaded(&loader, &PlaylistLoader::loaded);
        Source source;
        source.id = u"remote"_s;
        source.type = SourceType::M3uUrl;
        source.url = u"http://playlist.example.com/list.m3u"_s;
        loader.load(source);
        QVERIFY(loaded.wait(5000));
    }

    void cancelSuppressesSignals()
    {
        QTemporaryDir cache;
        PlaylistLoader loader(nullptr, cache.path());
        QSignalSpy loaded(&loader, &PlaylistLoader::loaded);
        Source source;
        source.id = u"local"_s;
        source.type = SourceType::M3uFile;
        source.url = QStringLiteral(IPTVX_TEST_DATA_DIR "/sample.m3u");
        loader.load(source);
        loader.cancel();
        QVERIFY(!loaded.wait(300));
    }
};

QTEST_GUILESS_MAIN(TestPlaylistLoader)
#include "tst_playlistloader.moc"
