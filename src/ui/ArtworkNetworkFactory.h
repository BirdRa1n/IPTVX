// SPDX-License-Identifier: MIT
#pragma once

#include <QQmlNetworkAccessManagerFactory>
#include <QString>

namespace iptvx::ui {

/// Gives every QML network access manager a shared on-disk HTTP cache.
///
/// Channel logos and posters are fetched by QML `Image` elements. With a
/// disk cache they are revalidated instead of re-downloaded and do not have
/// to be kept in RAM between sessions. Decoded pixmaps are still bounded by
/// the delegates' `sourceSize` and Qt's pixmap cache.
class ArtworkNetworkFactory : public QQmlNetworkAccessManagerFactory
{
public:
    explicit ArtworkNetworkFactory(QString cacheDir, qint64 maxBytes = 128LL * 1024 * 1024);
    QNetworkAccessManager *create(QObject *parent) override;

private:
    QString m_cacheDir;
    qint64 m_maxBytes;
};

} // namespace iptvx::ui
