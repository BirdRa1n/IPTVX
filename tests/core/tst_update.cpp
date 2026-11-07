// SPDX-License-Identifier: MIT
#include "update/Release.h"

#include <QFile>
#include <QTest>

using namespace Qt::StringLiterals;
using namespace iptvx::update;

namespace {
QByteArray fixture()
{
    QFile file(QStringLiteral(IPTVX_TEST_DATA_DIR "/github/release_latest.json"));
    return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
}

Platform platform(Platform::Os os, const char *arch)
{
    Platform p;
    p.os = os;
    p.arch = QString::fromLatin1(arch);
    return p;
}
} // namespace

class TestUpdate : public QObject
{
    Q_OBJECT

private slots:
    void comparesVersions_data()
    {
        QTest::addColumn<QString>("a");
        QTest::addColumn<QString>("b");
        QTest::addColumn<int>("expected");
        QTest::newRow("equal") << u"1.2.3"_s << u"1.2.3"_s << 0;
        QTest::newRow("v prefix") << u"v1.2.3"_s << u"1.2.3"_s << 0;
        QTest::newRow("patch") << u"0.1.10"_s << u"0.1.9"_s << 1;
        QTest::newRow("minor") << u"0.2.0"_s << u"0.10.0"_s << -1;
        QTest::newRow("short") << u"1.2"_s << u"1.2.0"_s << 0;
        QTest::newRow("pre < release") << u"1.0.0-beta.1"_s << u"1.0.0"_s << -1;
        QTest::newRow("release > pre") << u"1.0.0"_s << u"1.0.0-rc.1"_s << 1;
    }
    void comparesVersions()
    {
        QFETCH(QString, a);
        QFETCH(QString, b);
        QFETCH(int, expected);
        const int result = compareVersions(a, b);
        QCOMPARE((result > 0) - (result < 0), expected);
    }

    void parsesRelease()
    {
        const auto release = parseRelease(fixture());
        QVERIFY(release);
        QCOMPARE(release->tag, u"v0.3.0"_s);
        QCOMPARE(release->version, u"0.3.0"_s);
        QCOMPARE(release->assets.size(), 6);
        QCOMPARE(release->assets.first().sha256, QByteArray("abcdef0123"));
        QVERIFY(release->notes.contains(u"What's new"_s));
        QVERIFY(!parseRelease("{}"));
        QVERIFY(!parseRelease("garbage"));
    }

    void selectsAssetPerPlatform_data()
    {
        QTest::addColumn<int>("os");
        QTest::addColumn<QString>("arch");
        QTest::addColumn<QString>("expected");
        QTest::newRow("mac arm") << int(Platform::Os::MacOS) << u"arm64"_s << u"IPTVX-0.3.0-macos-arm64.zip"_s;
        QTest::newRow("mac intel") << int(Platform::Os::MacOS) << u"x86_64"_s << u"IPTVX-0.3.0-macos-x86_64.zip"_s;
        QTest::newRow("linux x86") << int(Platform::Os::Linux) << u"x86_64"_s << u"IPTVX-0.3.0-linux-x86_64.AppImage"_s;
        QTest::newRow("linux arm") << int(Platform::Os::Linux) << u"aarch64"_s << u"IPTVX-0.3.0-linux-aarch64.AppImage"_s;
        QTest::newRow("windows") << int(Platform::Os::Windows) << u"x64"_s << u"IPTVX-0.3.0-windows-x64-setup.exe"_s;
    }
    void selectsAssetPerPlatform()
    {
        QFETCH(int, os);
        QFETCH(QString, arch);
        QFETCH(QString, expected);
        Platform p;
        p.os = Platform::Os(os);
        p.arch = arch;
        const auto asset = selectAsset(*parseRelease(fixture()), p);
        QVERIFY(asset);
        QCOMPARE(asset->name, expected);
    }

    void reportsMissingAsset()
    {
        QVERIFY(!selectAsset(*parseRelease(fixture()), platform(Platform::Os::Other, "x")));
        QVERIFY(!selectAsset(*parseRelease(fixture()), platform(Platform::Os::Linux, "riscv64")));
    }

    void detectsCurrentPlatform()
    {
        const Platform p = Platform::current();
        QVERIFY(!p.assetSuffix().isEmpty());
    }
};

QTEST_APPLESS_MAIN(TestUpdate)
#include "tst_update.moc"
