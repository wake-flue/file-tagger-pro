import QtQuick
import QtMultimedia

Item {
    id: root
    property string source
    property bool isVideo: false
    
    Image {
        id: thumbnail
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        
        // 视频播放图标覆盖层
        Image {
            visible: root.isVideo
            anchors.centerIn: parent
            source: "qrc:/resources/images/play.svg"
            sourceSize.width: 24
            sourceSize.height: 24
            width: 24
            height: 24
            opacity: 0.8
        }
    }
    
    Component.onCompleted: {
        if (isVideo) {
            // 这里可以调用 C++ 后端来生成视频缩略图
            // 临时使用视频默认图标
            thumbnail.source = "qrc:/resources/images/video.svg"
            thumbnail.sourceSize.width = parent.width
            thumbnail.sourceSize.height = parent.height
        } else {
            thumbnail.source = source
            thumbnail.sourceSize.width = parent.width
            thumbnail.sourceSize.height = parent.height
        }
    }
}
