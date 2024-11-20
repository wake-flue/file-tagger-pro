#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "core/filesystemmanager.h"
#include "models/filedata.h"
#include "models/filelistmodel.h"
#include <QQmlEngine>
#include <QtQuickControls2/QQuickStyle>

Q_DECLARE_METATYPE(QVector<FileData>)

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // 设置应用程序信息
    app.setOrganizationName("YourCompany");
    app.setOrganizationDomain("yourcompany.com");
    app.setApplicationName("FileTaggingApp");
    
    // 设置样式必须在创建 QApplication 之后，加载 QML 之前
    QQuickStyle::setStyle("Basic");
    
    qRegisterMetaType<FileData>();
    qRegisterMetaType<QVector<FileData>>();
    qmlRegisterType<FileSystemManager>("FileManager", 1, 0, "FileSystemManager");
    qmlRegisterType<FileListModel>("FileManager", 1, 0, "FileListModel");
    qmlRegisterUncreatableType<FileListModel>("FileManager", 1, 0, "ViewMode",
        "ViewMode is an enum type");
    qmlRegisterType<FileData>("FileManager", 1, 0, "FileData");

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/qml/main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
