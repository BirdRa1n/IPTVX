// SPDX-License-Identifier: MIT
#include "parser/M3uParser.h"

#include <QBuffer>
#include <QFile>
#include <QTest>

using namespace Qt::StringLiterals;
using iptvx::M3uParser;

class TestM3uParser : public QObject
{
    Q_OBJECT

private slots:
    void parsesFixtureFile()
    {
        QFile file(QStringLiteral(IPTVX_TEST_DATA_DIR "/sample.m3u"));
        QVERIFY(file.open(QIODevice::ReadOnly));
        const auto result = M3uParser::parse(file);
        const auto &s = *result.channels;

        QCOMPARE(result.epgUrls,
                 QStringList({ u"http://epg.example.com/guide.xml"_s, u"http://epg.example.com/extra.xml"_s }));
        QCOMPARE(s.size(), 6);

        QCOMPARE(s.name(0), u"News One HD"_s);
        QCOMPARE(s.tvgId(0), u"news.one"_s);
        QCOMPARE(s.logo(0), u"http://img.example.com/news.png"_s);
        QCOMPARE(s.group(0), u"News"_s);
        QCOMPARE(s.url(0), u"http://stream.example.com/news.m3u8"_s);
        QCOMPARE(s.catchupDays(0), quint16(7));

        // Title containing a comma, attribute value containing a comma.
        QCOMPARE(s.name(1), u"Sports, Live"_s);
        QCOMPARE(s.group(1), u"Sports, Football"_s);

        // #EXTGRP and #EXTVLCOPT
        QCOMPARE(s.group(2), u"Movies"_s);
        QCOMPARE(s.userAgent(2), u"VLC/3.0"_s);
        QCOMPARE(s.referrer(2), u"http://ref.example.com/"_s);

        // Pipe headers are stripped from the URL.
        QCOMPARE(s.url(3), u"http://stream.example.com/pipe.ts"_s);
        QCOMPARE(s.userAgent(3), u"Pipe Agent"_s);
        QCOMPARE(s.referrer(3), u"http://pipe.example.com"_s);

        QVERIFY(s.isRadio(4));
        QCOMPARE(s.name(4), u"Radio Jazz"_s);

        // Missing title falls back to tvg-name.
        QCOMPARE(s.name(5), u"Fallback Name"_s);
    }

    void handlesBomAndCrlf()
    {
        const QByteArray data = "\xEF\xBB\xBF#EXTM3U\r\n#EXTINF:-1,One\r\nhttp://a\r\n";
        const auto result = M3uParser::parse(data);
        QCOMPARE(result.channels->size(), 1);
        QCOMPARE(result.channels->name(0), u"One"_s);
        QCOMPARE(result.channels->url(0), u"http://a"_s);
    }

    void acceptsPlainPlaylists()
    {
        const auto result = M3uParser::parse("http://a\nhttp://b\n# comment\nhttp://c");
        QCOMPARE(result.channels->size(), 3);
        QCOMPARE(result.channels->name(2), u"http://c"_s); // URL used as name
    }

    void acceptsVeryLongUrls()
    {
        const QByteArray longUrl = "http://example.com/?token=" + QByteArray(5000, 'x');
        const QByteArray data = "#EXTINF:-1,Long\n" + longUrl + "\n#EXTINF:-1,Next\nhttp://n";
        const auto result = M3uParser::parse(data);
        QCOMPARE(result.channels->size(), 2);
        QCOMPARE(result.channels->urlUtf8(0).size(), longUrl.size());
        QCOMPARE(result.channels->name(1), u"Next"_s);
    }

    void ignoresUnknownDirectives()
    {
        const auto result = M3uParser::parse(
            "#EXTM3U\n#EXTINF:-1 group-title=\"G\",A\n#KODIPROP:inputstream=adaptive\nhttp://a\n");
        QCOMPARE(result.channels->size(), 1);
        QCOMPARE(result.channels->group(0), u"G"_s);
    }

    void honoursCancellation()
    {
        QByteArray big;
        for (int i = 0; i < 5000; ++i)
            big += "#EXTINF:-1,C\nhttp://c\n";
        std::atomic_bool cancel { true };
        QBuffer buffer(&big);
        buffer.open(QIODevice::ReadOnly);
        const auto result = M3uParser::parse(buffer, &cancel);
        QVERIFY(result.cancelled);
        QVERIFY(result.channels->size() < 5000);
    }
};

QTEST_APPLESS_MAIN(TestM3uParser)
#include "tst_m3uparser.moc"
