// SPDX-License-Identifier: MIT
#include "model/ChannelStore.h"

#include <QTest>

using namespace Qt::StringLiterals;
using iptvx::ChannelStore;

class TestChannelStore : public QObject
{
    Q_OBJECT

private slots:
    void appendsAndReadsBack()
    {
        ChannelStore store;
        const auto i = store.append({ .name = "  News One ",
                                      .url = "http://stream.example.com/1.m3u8",
                                      .logo = "http://img.example.com/1.png",
                                      .tvgId = "news.one",
                                      .group = "News",
                                      .catchupDays = 3,
                                      .radio = true });
        QCOMPARE(store.size(), 1);
        QCOMPARE(store.name(i), u"News One"_s);
        QCOMPARE(store.url(i), u"http://stream.example.com/1.m3u8"_s);
        QCOMPARE(store.logo(i), u"http://img.example.com/1.png"_s);
        QCOMPARE(store.tvgId(i), u"news.one"_s);
        QCOMPARE(store.group(i), u"News"_s);
        QCOMPARE(store.catchupDays(i), quint16(3));
        QVERIFY(store.isRadio(i));
    }

    void internsRepeatedValues()
    {
        ChannelStore store;
        for (int n = 0; n < 1000; ++n)
            store.append({ .name = "Channel", .url = "http://example.com", .group = "Sports",
                           .userAgent = "Agent/1.0" });
        store.append({ .name = "Other", .url = "http://example.com", .group = "News" });
        // empty + Sports + News
        QCOMPARE(store.groups().size(), 3);
        QCOMPARE(store.groupId(0), store.groupId(999));
        QCOMPARE(store.userAgent(10), u"Agent/1.0"_s);
        QVERIFY(store.userAgent(1000).isEmpty());
    }

    void keepsUnicode()
    {
        ChannelStore store;
        store.append({ .name = "Educação Ç ñ 日本", .url = "u", .group = "Família" });
        QCOMPARE(store.name(0), u"Educação Ç ñ 日本"_s);
        QCOMPARE(store.group(0), u"Família"_s);
    }

    void stringsSurviveSqueeze()
    {
        ChannelStore store;
        store.reserve(100, 10000);
        store.append({ .name = "A", .url = "http://a", .group = "G" });
        store.squeeze();
        QCOMPARE(store.group(0), u"G"_s);
        store.append({ .name = "B", .url = "http://b", .group = "G" }); // still works
        QCOMPARE(store.name(1), u"B"_s);
    }

    void footprintIsCompact()
    {
        ChannelStore store;
        for (int n = 0; n < 10000; ++n)
            store.append({ .name = "Channel Name HD", .url = "http://example.com/live/user/pass/12345.ts",
                           .group = "Group" });
        store.squeeze();
        // ~44 B record + ~57 B text per channel; generous bound of 128 B.
        QVERIFY2(store.memoryFootprint() < 10000 * 128,
                 qPrintable(u"footprint: %1 bytes"_s.arg(store.memoryFootprint())));
    }
};

QTEST_APPLESS_MAIN(TestChannelStore)
#include "tst_channelstore.moc"
