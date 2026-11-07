// SPDX-License-Identifier: MIT
#pragma once

#include "update/Release.h"

#include <QObject>
#include <QPointer>

#include <memory>

class QNetworkAccessManager;
class QNetworkReply;
class QSaveFile;
class QCryptographicHash;

namespace iptvx::update {

/// Talks to the GitHub Releases API and downloads release assets.
///
/// * check(): GET /repos/{repo}/releases/latest (unauthenticated; GitHub
///   allows 60 requests/hour per IP, the app checks once per launch).
/// * download(): streams the asset to disk (never buffered in RAM) and
///   verifies its size and, when GitHub publishes one, its SHA-256 digest.
class UpdateService : public QObject
{
    Q_OBJECT

public:
    UpdateService(QNetworkAccessManager *network, QString repository, QString currentVersion,
                  QObject *parent = nullptr);
    ~UpdateService() override;

    void check();
    void download(const ReleaseAsset &asset, const QString &directory);
    void cancel();

    QString repository() const { return m_repository; }
    QString currentVersion() const { return m_currentVersion; }

signals:
    /// A newer release exists. @p asset is empty when no build matches this
    /// platform (the release page can still be offered).
    void updateAvailable(const iptvx::update::Release &release,
                         const std::optional<iptvx::update::ReleaseAsset> &asset);
    void upToDate(const QString &latestVersion);
    void checkFailed(const QString &error);

    void downloadProgress(qint64 received, qint64 total);
    void downloaded(const QString &filePath);
    void downloadFailed(const QString &error);

private:
    QPointer<QNetworkAccessManager> m_network;
    QString m_repository;
    QString m_currentVersion;
    QPointer<QNetworkReply> m_reply;
    std::unique_ptr<QSaveFile> m_file;
    std::unique_ptr<QCryptographicHash> m_hash;
};

} // namespace iptvx::update
