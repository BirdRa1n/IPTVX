// SPDX-License-Identifier: MIT
#pragma once

#include "model/Source.h"

#include <QAbstractListModel>
#include <QQmlEngine>

namespace iptvx::ui {

/// List of configured sources (a handful of rows; stored by value).
class SourceListModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Provided by Library")

    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        NameRole,
        TypeRole,
        TypeLabelRole,
        UrlRole,
    };
    Q_ENUM(Role)

    explicit SourceListModel(QObject *parent = nullptr);

    void setSources(QList<Source> sources);
    void append(const Source &source);
    void removeById(const QString &id);
    const QList<Source> &sources() const { return m_sources; }
    const Source *findById(const QString &id) const;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const { return int(m_sources.size()); }

    static QString typeLabel(SourceType type);

signals:
    void countChanged();

private:
    QList<Source> m_sources;
};

} // namespace iptvx::ui
