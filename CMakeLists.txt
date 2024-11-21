cmake_minimum_required(VERSION 3.16)

project(FileTaggingApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# 添加 FFmpeg 路径
set(FFMPEG_ROOT "D:/Environment/ffmpeg")
set(FFMPEG_INCLUDE_DIR "${FFMPEG_ROOT}/include")
set(FFMPEG_LIB_DIR "${FFMPEG_ROOT}/lib")

# 添加 FFmpeg 库
find_library(AVCODEC_LIBRARY avcodec PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(AVFORMAT_LIBRARY avformat PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(AVUTIL_LIBRARY avutil PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(SWSCALE_LIBRARY swscale PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)

# 添加 QuickEffects 模块
find_package(Qt6 REQUIRED COMPONENTS Concurrent Core Gui Quick QuickDialogs2 QuickControls2)

# 源文件
set(SOURCES
    src/main.cpp
    src/core/filesystemmanager.cpp
    src/models/filedata.cpp
    src/models/filelistmodel.cpp
    src/utils/logger.cpp
    src/utils/previewgenerator.cpp
    src/utils/defaultapps.cpp
)

# 头文件
set(HEADERS
    src/core/filesystemmanager.h
    src/models/filedata.h
    src/models/filelistmodel.h
    src/utils/logger.h
    src/utils/previewgenerator.h
    src/utils/defaultapps.h
)

# QML文件
set(QML_FILES
    qml/main.qml
    qml/components/FileList.qml
    qml/components/LogViewer.qml
    qml/dialogs/FolderPickerDialog.qml
    qml/components/FilterDialog.qml
)

qt_add_executable(FileTaggingApp
    ${SOURCES}
    ${HEADERS}
)

target_include_directories(FileTaggingApp PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${FFMPEG_INCLUDE_DIR}
)

target_link_directories(FileTaggingApp PRIVATE
    ${FFMPEG_LIB_DIR}
)

target_link_libraries(FileTaggingApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickDialogs2
    Qt6::QuickControls2
    Qt6::Concurrent
    ${AVCODEC_LIBRARY}
    ${AVFORMAT_LIBRARY}
    ${AVUTIL_LIBRARY}
    ${SWSCALE_LIBRARY}
)

# 使用qt_add_resources添加所有资源
qt_add_resources(FileTaggingApp "qml"
    PREFIX "/"
    FILES
        qml/components/qmldir
        qml/main.qml
        qml/components/FileList.qml
        qml/components/LogViewer.qml
        qml/components/Splitter.qml
        qml/components/FilterDialog.qml
        qml/components/Settings.qml
        qml/components/DetailPanel.qml
        qml/components/TopToolBar.qml
        qml/components/StatusBar.qml
        qml/dialogs/FolderPickerDialog.qml
        qml/dialogs/LogViewerDialog.qml
        qml/dialogs/PlayerSettingsDialog.qml
        resources/images/file.svg
        resources/images/folder.svg
        resources/images/refresh.svg
        resources/images/log.svg
        resources/images/clear.svg
        resources/images/large-icons.svg
        resources/images/list.svg
        resources/images/image.svg
        resources/images/text.svg
        resources/images/filter.svg
        resources/images/play.svg
        resources/images/video.svg
        resources/images/player.svg
        resources/images/loading.svg
        resources/images/open.svg
        resources/images/debug.svg
        resources/images/audio.svg
        resources/images/archive.svg
        resources/images/code.svg
)

# 添加 QML 导入路径
target_compile_definitions(FileTaggingApp PRIVATE
    QML_IMPORT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/qml"
)

# 确保运行时能找到 FFmpeg DLL
add_custom_command(TARGET FileTaggingApp POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${FFMPEG_ROOT}/bin"
    $<TARGET_FILE_DIR:FileTaggingApp>
)
