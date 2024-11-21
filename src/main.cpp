#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "core/filesystemmanager.h"
#include "models/filedata.h"
#include "models/filelistmodel.h"
#include "utils/defaultapps.h"
#include <QQmlEngine>
#include <QtQuickControls2/QQuickStyle>
#include <QDir>
#include <QStandardPaths>

Q_DECLARE_METATYPE(QVector<FileData>)

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // 设置应用程序信息
    app.setOrganizationName("Wake");
    app.setOrganizationDomain("wake.com");
    app.setApplicationName("FileTaggingPro");
    
    // 设置样式必须在创建 QApplication 之后，加载 QML 之前
    QQuickStyle::setStyle("Basic");
    
    qRegisterMetaType<FileData>();
    qRegisterMetaType<QVector<FileData>>();
    qmlRegisterType<FileSystemManager>("FileManager", 1, 0, "FileSystemManager");
    qmlRegisterType<FileListModel>("FileManager", 1, 0, "FileListModel");
    qmlRegisterUncreatableType<FileListModel>("FileManager", 1, 0, "ViewMode",
        "ViewMode is an enum type");
    qmlRegisterType<FileData>("FileManager", 1, 0, "FileData");
    qmlRegisterType<DefaultApps>("FileManager", 1, 0, "DefaultApps");

    QDir settingsDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    if (!settingsDir.exists()) {
        settingsDir.mkpath(".");
    }

    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:/qml");
    const QUrl url(u"qrc:/qml/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
