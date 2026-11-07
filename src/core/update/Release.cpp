// SPDX-License-Identifier: MIT
#include "update/Release.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSysInfo>

#if defined(Q_OS_MACOS)
#include <sys/sysctl.h>
#endif

using namespace Qt::StringLiterals;

namespace iptvx::update {

QString Platform::assetSuffix() const
{
    switch (os) {
    case Os::MacOS:
        return u"macos-%1.zip"_s.arg(arch);
    case Os::Linux:
        return u"linux-%1.AppImage"_s.arg(arch);
    case Os::Windows:
        return u"windows-%1-setup.exe"_s.arg(arch);
    case Os::Other:
        break;
    }
    return {};
}

Platform Platform::current()
{
    Platform p;
    const QString cpu = QSysInfo::currentCpuArchitecture(); // "arm64", "x86_64", "i386"…
    const bool arm = cpu.startsWith(u"arm"_s) || cpu == u"aarch64"_s;
#if defined(Q_OS_MACOS)
    p.os = Os::MacOS;
    bool translated = false;
    int value = 0;
    size_t size = sizeof(value);
    if (sysctlbyname("sysctl.proc_translated", &value, &size, nullptr, 0) == 0)
        translated = value == 1; // Intel build running under Rosetta 2
    p.arch = (arm || translated) ? u"arm64"_s : u"x86_64"_s;
#elif defined(Q_OS_LINUX)
    p.os = Os::Linux;
    p.arch = arm ? u"aarch64"_s : u"x86_64"_s;
#elif defined(Q_OS_WIN)
    p.os = Os::Windows;
    p.arch = u"x64"_s; // the only Windows build; runs emulated on Windows on ARM
#else
    Q_UNUSED(arm)
#endif
    return p;
}

int compareVersions(const QString &a, const QString &b)
{
    auto split = [](const QString &v, QString *pre) {
        QString core = v.trimmed();
        if (core.startsWith(u'v') || core.startsWith(u'V'))
            core.remove(0, 1);
        const qsizetype dash = core.indexOf(u'-');
        if (dash >= 0) {
            *pre = core.mid(dash + 1);
            core.truncate(dash);
        }
        QList<int> parts;
        for (const QString &n : core.split(u'.'))
            parts.append(n.toInt());
        while (parts.size() < 3)
            parts.append(0);
        return parts;
    };
    QString preA, preB;
    const QList<int> pa = split(a, &preA);
    const QList<int> pb = split(b, &preB);
    for (qsizetype i = 0; i < qMax(pa.size(), pb.size()); ++i) {
        const int x = i < pa.size() ? pa[i] : 0;
        const int y = i < pb.size() ? pb[i] : 0;
        if (x != y)
            return x < y ? -1 : 1;
    }
    if (preA.isEmpty() != preB.isEmpty())
        return preA.isEmpty() ? 1 : -1; // release > pre-release
    return QString::compare(preA, preB);
}

std::optional<Release> parseRelease(QByteArrayView json, QString *error)
{
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(json.toByteArray(), &parseError);
    if (!doc.isObject()) {
        if (error)
            *error = parseError.errorString();
        return std::nullopt;
    }
    const QJsonObject o = doc.object();
    Release r;
    r.tag = o.value("tag_name"_L1).toString();
    if (r.tag.isEmpty()) {
        if (error)
            *error = u"Release has no tag"_s;
        return std::nullopt;
    }
    r.version = r.tag.startsWith(u'v') ? r.tag.mid(1) : r.tag;
    r.name = o.value("name"_L1).toString();
    r.notes = o.value("body"_L1).toString();
    r.pageUrl = QUrl(o.value("html_url"_L1).toString());
    r.publishedAt = QDateTime::fromString(o.value("published_at"_L1).toString(), Qt::ISODate);
    for (const QJsonValue &v : o.value("assets"_L1).toArray()) {
        const QJsonObject a = v.toObject();
        ReleaseAsset asset;
        asset.name = a.value("name"_L1).toString();
        asset.url = QUrl(a.value("browser_download_url"_L1).toString());
        asset.size = qint64(a.value("size"_L1).toDouble());
        const QString digest = a.value("digest"_L1).toString(); // "sha256:<hex>"
        if (digest.startsWith(u"sha256:"_s))
            asset.sha256 = digest.mid(7).toLatin1().toLower();
        if (!asset.name.isEmpty() && asset.url.isValid())
            r.assets.append(asset);
    }
    return r;
}

std::optional<ReleaseAsset> selectAsset(const Release &release, const Platform &platform)
{
    const QString suffix = platform.assetSuffix();
    if (suffix.isEmpty())
        return std::nullopt;
    for (const ReleaseAsset &asset : release.assets)
        if (asset.name.endsWith(suffix, Qt::CaseInsensitive))
            return asset;
    return std::nullopt;
}

} // namespace iptvx::update
