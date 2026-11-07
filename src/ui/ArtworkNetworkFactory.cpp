// SPDX-License-Identifier: MIT
#include "ArtworkNetworkFactory.h"

#include <QNetworkAccessManager>
#include <QNetworkDiskCache>

namespace iptvx::ui {

ArtworkNetworkFactory::ArtworkNetworkFactory(QString cacheDir, qint64 maxBytes)
    : m_cacheDir(std::move(cacheDir))
    , m_maxBytes(maxBytes)
{
}

QNetworkAccessManager *ArtworkNetworkFactory::create(QObject *parent)
{
    auto *nam = new QNetworkAccessManager(parent);
    auto *cache = new QNetworkDiskCache(nam);
    cache->setCacheDirectory(m_cacheDir);
    cache->setMaximumCacheSize(m_maxBytes);
    nam->setCache(cache);
    return nam;
}

} // namespace iptvx::ui
