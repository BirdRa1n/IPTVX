// SPDX-License-Identifier: MIT
#include "models/SourceListModel.h"

using namespace Qt::StringLiterals;

namespace iptvx::ui {

SourceListModel::SourceListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void SourceListModel::setSources(QList<Source> sources)
{
    beginResetModel();
    m_sources = std::move(sources);
    endResetModel();
    emit countChanged();
}

void SourceListModel::append(const Source &source)
{
    beginInsertRows({}, count(), count());
    m_sources.append(source);
    endInsertRows();
    emit countChanged();
}

void SourceListModel::removeById(const QString &id)
{
    for (int row = 0; row < count(); ++row) {
        if (m_sources[row].id == id) {
            beginRemoveRows({}, row, row);
            m_sources.removeAt(row);
            endRemoveRows();
            emit countChanged();
            return;
        }
    }
}

const Source *SourceListModel::findById(const QString &id) const
{
    for (const Source &s : m_sources)
        if (s.id == id)
            return &s;
    return nullptr;
}

int SourceListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : count();
}

QString SourceListModel::typeLabel(SourceType type)
{
    switch (type) {
    case SourceType::M3uFile:
        return tr("M3U File");
    case SourceType::M3uUrl:
        return tr("M3U");
    case SourceType::Xtream:
        return tr("Xtream");
    case SourceType::Stalker:
        return tr("Stalker");
    }
    return {};
}

QVariant SourceListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= count())
        return {};
    const Source &s = m_sources[index.row()];
    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return s.name;
    case IdRole:
        return s.id;
    case TypeRole:
        return int(s.type);
    case TypeLabelRole:
        return typeLabel(s.type);
    case UrlRole:
        return s.url;
    default:
        return {};
    }
}

QHash<int, QByteArray> SourceListModel::roleNames() const
{
    return { { IdRole, "sourceId"_ba }, { NameRole, "name"_ba }, { TypeRole, "type"_ba },
             { TypeLabelRole, "typeLabel"_ba }, { UrlRole, "url"_ba } };
}

} // namespace iptvx::ui
