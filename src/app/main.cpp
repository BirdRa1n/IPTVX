// SPDX-License-Identifier: MIT
// IPTVX application entry point.

#include "ArtworkNetworkFactory.h"

#include <QGuiApplication>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QStandardPaths>
#include <QTranslator>

using namespace Qt::StringLiterals;

namespace {

void installTranslator(QGuiApplication &app, QTranslator &translator)
{
    const QStringList uiLanguages = QLocale::system().uiLanguages();
    for (const QString &locale : uiLanguages) {
        if (translator.load(u":/i18n/iptvx_"_s + QLocale(locale).name())) {
            QCoreApplication::installTranslator(&translator);
            return;
        }
    }
    Q_UNUSED(app)
}

} // namespace

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(u"IPTVX"_s);
    QGuiApplication::setOrganizationName(u"IPTVX"_s);
    QGuiApplication::setApplicationVersion(QStringLiteral(IPTVX_VERSION));

    // A fully custom design system is drawn on top of the Basic style:
    // it is the lightest style and imposes no native look.
    QQuickStyle::setStyle(u"Basic"_s);

    QTranslator translator;
    installTranslator(app, translator);

    QQmlApplicationEngine engine;
    iptvx::ui::ArtworkNetworkFactory artworkFactory(
        QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + u"/artwork"_s);
    engine.setNetworkAccessManagerFactory(&artworkFactory);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
        [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule(u"IPTVX.UI"_s, u"Main"_s);

    return QGuiApplication::exec();
}
