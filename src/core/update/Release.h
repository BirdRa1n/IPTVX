// SPDX-License-Identifier: MIT
#pragma once

#include <QByteArray>
#include <QDateTime>
#include <QList>
#include <QString>
#include <QUrl>

#include <optional>

namespace iptvx::update {

/// A downloadable file attached to a GitHub release.
struct ReleaseAsset
{
    QString name;
    QUrl url;           ///< browser_download_url
    qint64 size = 0;
    QByteArray sha256;  ///< hex digest when GitHub provides one ("digest")
};

/// A published GitHub release.
struct Release
{
    QString tag;        ///< e.g. "v0.2.0"
    QString version;    ///< tag without the leading "v"
    QString name;
    QString notes;      ///< Markdown body
    QUrl pageUrl;       ///< html_url
    QDateTime publishedAt;
    QList<ReleaseAsset> assets;
};

/// Operating system + CPU of the running app, as release assets name them.
struct Platform
{
    enum class Os { MacOS, Linux, Windows, Other };
    Os os = Os::Other;
    QString arch; ///< "arm64", "x86_64", "aarch64", "x64"

    /// File-name suffix of the release asset for this platform, e.g.
    /// "macos-arm64.zip", "linux-aarch64.AppImage", "windows-x64-setup.exe".
    QString assetSuffix() const;

    /// The platform IPTVX is running on. On macOS an Intel build running
    /// under Rosetta reports arm64 so it upgrades to the native build.
    static Platform current();
};

/// Compares dotted versions ("1.2.10" > "1.2.9"). A pre-release suffix
/// ("1.0.0-beta.2") sorts before the plain release. Returns <0, 0 or >0.
int compareVersions(const QString &a, const QString &b);

/// Parses the JSON of GET /repos/{owner}/{repo}/releases/latest.
std::optional<Release> parseRelease(QByteArrayView json, QString *error = nullptr);

/// Picks the asset matching @p platform, if the release has one.
std::optional<ReleaseAsset> selectAsset(const Release &release, const Platform &platform);

} // namespace iptvx::update
