// SPDX-License-Identifier: MIT
#include "storage/Database.h"
#include "storage/SourceRepository.h"

#include <QSqlQuery>
#include <QTemporaryDir>
#include <QTest>

using namespace Qt::StringLiterals;
using namespace iptvx;

class TestSourceRepository : public QObject
{
    Q_OBJECT

private slots:
    void migratesToLatestVersion()
    {
        Database db(u"t1"_s);
        QVERIFY2(db.open(u":memory:"_s), qPrintable(db.lastError()));
        QSqlQuery q(db.connection());
        QVERIFY(q.exec(u"PRAGMA user_version"_s) && q.next());
        QCOMPARE(q.value(0).toInt(), Database::schemaVersion());
    }

    void reopeningIsIdempotent()
    {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const QString path = dir.filePath(u"iptvx.db"_s);
        {
            Database db(u"t3"_s);
            QVERIFY(db.open(path));
        }
        Database db(u"t3"_s);
        QVERIFY2(db.open(path), qPrintable(db.lastError()));
    }

    void crudRoundTrip()
    {
        Database db(u"t2"_s);
        QVERIFY(db.open(u":memory:"_s));
        SourceRepository repo(db.connection());

        Source s;
        s.name = u"Provider A"_s;
        s.type = SourceType::Xtream;
        s.url = u"http://provider.example.com:8080"_s;
        s.username = u"demo"_s;
        s.password = u"secret"_s;
        const auto stored = repo.insert(s);
        QVERIFY(stored);
        QVERIFY(!stored->id.isEmpty());
        QVERIFY(stored->createdAt.isValid());

        auto found = repo.find(stored->id);
        QVERIFY(found);
        QCOMPARE(found->type, SourceType::Xtream);
        QCOMPARE(found->username, u"demo"_s);

        found->name = u"Renamed"_s;
        QVERIFY(repo.update(*found));
        QCOMPARE(repo.all().size(), 1);
        QCOMPARE(repo.all().first().name, u"Renamed"_s);

        QVERIFY(repo.remove(stored->id));
        QVERIFY(repo.all().isEmpty());
        QVERIFY(!repo.remove(stored->id));
    }
};

QTEST_GUILESS_MAIN(TestSourceRepository)
#include "tst_sourcerepository.moc"
