// SPDX-License-Identifier: MIT
#pragma once

#include "model/ChannelStore.h"

#include <QAbstractListModel>
#include <QQmlEngine>

#include <vector>

namespace iptvx::ui {

/// Read-only list model over a shared ChannelStore.
///
/// The model never copies channels: it keeps the shared store plus a vector
/// of 32-bit indices for the current filter (4 bytes per visible row).
/// QStrings are created only inside data(), i.e. for delegates on screen.
class ChannelListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Library")

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY storeChanged)
    Q_PROPERTY(QStringList groups READ groups NOTIFY storeChanged)
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(QString group READ group WRITE setGroup NOTIFY groupChanged)

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        UrlRole,
        LogoRole,
        GroupRole,
        TvgIdRole,
        NumberRole,
        RadioRole,
        UserAgentRole,
    };
    Q_ENUM(Role)

    explicit ChannelListModel(QObject *parent = nullptr);

    void setStore(ChannelStorePtr store);

    /// When false an empty search yields no rows instead of the whole
    /// catalog (used by global search so idle state costs nothing).
    void setMatchAllWhenIdle(bool matchAll) { m_matchAllWhenIdle = matchAll; applyFilter(); }
    const ChannelStorePtr &store() const { return m_store; }

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return int(m_rows.size()); }
    int totalCount() const { return m_store ? int(m_store->size()) : 0; }
    QStringList groups() const;

    QString searchText() const { return m_searchText; }
    void setSearchText(const QString &text);
    QString group() const { return m_group; }
    void setGroup(const QString &group);

    /// Returns all roles of @p row as a map (for "now playing" state).
    Q_INVOKABLE QVariantMap get(int row) const;

signals:
    void countChanged();
    void storeChanged();
    void searchTextChanged();
    void groupChanged();

private:
    void applyFilter();

    ChannelStorePtr m_store;
    std::vector<ChannelStore::Index> m_rows;
    QString m_searchText;
    QString m_group;
    bool m_matchAllWhenIdle = true;
};

} // namespace iptvx::ui
