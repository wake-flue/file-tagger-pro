cmake_minimum_required(VERSION 3.16)

project(FileTaggingApp VERSION 1.0 LANGUAGES CXX)

# 首先找到 Qt6 Core 模块
find_package(Qt6 REQUIRED COMPONENTS Core)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# 设置 Qt 策略
qt_standard_project_setup()
set(CMAKE_POLICY_DEFAULT_CMP0071 NEW)

# 设置 QML 输出目录
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

# 明确设置 QTP0001 策略
if (POLICY QTP0001)
    cmake_policy(SET QTP0001 NEW)
endif ()

# 添加其他 Qt 模块
find_package(Qt6 REQUIRED COMPONENTS Concurrent Gui Quick QuickDialogs2 QuickControls2 Qml Sql)

# 设置 QML 模块的资源前缀
set(QML_RESOURCE_PREFIX "/")
set(QML_IMPORT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/qml")

# 添加 FFmpeg 路径
set(FFMPEG_ROOT "D:/Environment/ffmpeg")
set(FFMPEG_INCLUDE_DIR "${FFMPEG_ROOT}/include")
set(FFMPEG_LIB_DIR "${FFMPEG_ROOT}/lib")

# 添加 FFmpeg 库
find_library(AVCODEC_LIBRARY avcodec PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(AVFORMAT_LIBRARY avformat PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(AVUTIL_LIBRARY avutil PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)
find_library(SWSCALE_LIBRARY swscale PATHS ${FFMPEG_LIB_DIR} NO_DEFAULT_PATH)

# 源文件
set(SOURCES
        src/main.cpp
        src/core/filesystemmanager.cpp
        src/models/filedata.cpp
        src/models/filelistmodel.cpp
        src/utils/logger.cpp
        src/utils/previewgenerator.cpp
        src/utils/spritegenerator.cpp
        src/core/tagmanager.cpp
        src/core/databasemanager.cpp
        src/models/tag.cpp
)

# 头文件
set(HEADERS
        src/core/filesystemmanager.h
        src/models/filedata.h
        src/models/filelistmodel.h
        src/utils/logger.h
        src/utils/previewgenerator.h
        src/utils/spritegenerator.h
        src/core/tagmanager.h
        src/core/databasemanager.h
        src/models/tag.h
)

# QML文件和资源文件分开定义
set(QML_FILES
        qml/main.qml
        qml/components/FileList.qml
        qml/components/TopToolBar.qml
        qml/components/Splitter.qml
        qml/components/DetailPanel.qml
        qml/components/StatusBar.qml
        qml/components/Settings.qml
        qml/components/TagToolBar.qml
        qml/dialogs/FolderPickerDialog.qml
        qml/dialogs/SpriteDialog.qml
        qml/dialogs/TagEditDialog.qml
        qml/dialogs/FileTagDialog.qml
        qml/dialogs/SettingsWindow.qml
        qml/settings/SettingsStyle.qml
        qml/settings/PlayerSettings.qml
        qml/settings/FileTypeSettings.qml
        qml/settings/DatabaseSettings.qml
        qml/settings/LogSettings.qml
)

# 添加 qmldir 文件到资源列表
set(RESOURCE_FILES
        qml/components/qmldir
        qml/dialogs/qmldir
        qml/settings/qmldir
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
        resources/images/checkmark.svg
        resources/images/search.svg
        resources/images/add.svg
        resources/images/remove.svg
        resources/images/tag.svg
        resources/images/tag-edit.svg
        resources/images/database.svg
        resources/images/backup.svg
        resources/images/setting.svg
        resources/images/restore.svg
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
        Qt6::Sql
        ${AVCODEC_LIBRARY}
        ${AVFORMAT_LIBRARY}
        ${AVUTIL_LIBRARY}
        ${SWSCALE_LIBRARY}
)

# 使用qt_add_resources添加所有资源
qt_add_resources(FileTaggingApp "resources"
    PREFIX "/"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}"
    FILES
    ${RESOURCE_FILES}
)

qt_add_resources(FileTaggingApp "qml"
    PREFIX "/"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}"
    FILES
    ${QML_FILES}
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

# 使用qt_add_qml_module添加QML模块
qt_add_qml_module(FileTaggingApp
        URI FileTaggingApp
        VERSION 1.0
        QML_FILES ${QML_FILES}
        RESOURCES ${RESOURCE_FILES}
        RESOURCE_PREFIX ${QML_RESOURCE_PREFIX}
        IMPORT_PATH ${QML_IMPORT_PATH}
        NO_RESOURCE_TARGET_PATH
)
