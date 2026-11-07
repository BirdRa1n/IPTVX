// SPDX-License-Identifier: MIT
#include "models/ChannelListModel.h"

using namespace Qt::StringLiterals;

namespace iptvx::ui {

ChannelListModel::ChannelListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void ChannelListModel::setStore(ChannelStorePtr store)
{
    beginResetModel();
    m_store = std::move(store);
    m_rows.clear();
    m_rows.shrink_to_fit();
    endResetModel();
    emit storeChanged();
    if (!m_group.isEmpty()) {
        m_group.clear();
        emit groupChanged();
    }
    applyFilter();
}

int ChannelListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_rows.size());
}

QVariant ChannelListModel::data(const QModelIndex &index, int role) const
{
    if (!m_store || !index.isValid() || index.row() >= int(m_rows.size()))
        return {};
    const ChannelStore::Index i = m_rows[size_t(index.row())];
    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return m_store->name(i);
    case UrlRole:
        return m_store->url(i);
    case LogoRole:
        return m_store->logo(i);
    case GroupRole:
        return m_store->group(i);
    case TvgIdRole:
        return m_store->tvgId(i);
    case NumberRole:
        return int(i) + 1;
    case RadioRole:
        return m_store->isRadio(i);
    case UserAgentRole:
        return m_store->userAgent(i);
    default:
        return {};
    }
}

QHash<int, QByteArray> ChannelListModel::roleNames() const
{
    return {
        { NameRole, "name"_ba },     { UrlRole, "url"_ba },       { LogoRole, "logo"_ba },
        { GroupRole, "group"_ba },   { TvgIdRole, "tvgId"_ba },   { NumberRole, "number"_ba },
        { RadioRole, "radio"_ba },   { UserAgentRole, "userAgent"_ba },
    };
}

QStringList ChannelListModel::groups() const
{
    QStringList result;
    if (!m_store)
        return result;
    const auto &values = m_store->groups().values();
    result.reserve(qsizetype(values.size()));
    for (const QString &g : values)
        if (!g.isEmpty())
            result.append(g);
    return result;
}

void ChannelListModel::setSearchText(const QString &text)
{
    if (text == m_searchText)
        return;
    m_searchText = text;
    emit searchTextChanged();
    applyFilter();
}

void ChannelListModel::setGroup(const QString &group)
{
    if (group == m_group)
        return;
    m_group = group;
    emit groupChanged();
    applyFilter();
}

QVariantMap ChannelListModel::get(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= count())
        return map;
    const QModelIndex idx = index(row);
    const auto roles = roleNames();
    for (auto it = roles.cbegin(); it != roles.cend(); ++it)
        map.insert(QString::fromUtf8(it.value()), data(idx, it.key()));
    return map;
}

void ChannelListModel::applyFilter()
{
    const int before = count();
    beginResetModel();
    m_rows.clear();
    if (m_store) {
        const qsizetype n = m_store->size();
        const QString needle = m_searchText.trimmed();
        const QByteArray needleUtf8 = needle.toUtf8();

        // Resolve the group to its interned id once: comparing 16-bit ids is
        // much cheaper than comparing strings for every channel.
        int groupId = -1;
        if (!m_group.isEmpty()) {
            const auto &values = m_store->groups().values();
            for (size_t g = 0; g < values.size(); ++g)
                if (values[g] == m_group)
                    groupId = int(g);
            if (groupId < 0)
                groupId = 0x10000; // unknown group: matches nothing
        }

        if (needle.isEmpty() && groupId < 0) {
            m_rows.resize(size_t(n));
            for (qsizetype i = 0; i < n; ++i)
                m_rows[size_t(i)] = ChannelStore::Index(i);
        } else {
            for (qsizetype i = 0; i < n; ++i) {
                const auto idx = ChannelStore::Index(i);
                if (groupId >= 0 && m_store->groupId(idx) != groupId)
                    continue;
                // Cheap exact byte match first; only build a temporary QString
                // for the case-insensitive comparison when that misses.
                if (!needle.isEmpty()) {
                    const QByteArrayView name = m_store->nameUtf8(idx);
                    if (!name.contains(needleUtf8)
                        && !QString::fromUtf8(name).contains(needle, Qt::CaseInsensitive))
                        continue;
                }
                m_rows.push_back(idx);
            }
            m_rows.shrink_to_fit();
        }
    }
    endResetModel();
    if (before != count())
        emit countChanged();
}

} // namespace iptvx::ui
