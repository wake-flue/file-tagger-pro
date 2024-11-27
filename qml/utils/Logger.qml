pragma Singleton
import QtQuick

QtObject {
    // 日志函数
    function logOperation(fileManager, operation, fileName) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.info(formatLogMessage("操作", operation, fileName))
        } else {
            console.log(formatLogMessage("操作", operation, fileName))
        }
    }
    
    function logError(fileManager, operation, fileName, error) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.error(formatLogMessage("错误", operation, fileName, error))
        } else {
            console.error(formatLogMessage("错误", operation, fileName, error))
        }
    }
    
    function logWarning(fileManager, operation, fileName, warning) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.warning(formatLogMessage("警告", operation, fileName, warning))
        } else {
            console.warn(formatLogMessage("警告", operation, fileName, warning))
        }
    }
    
    function logDebug(fileManager, operation, fileName, detail) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.debug(formatLogMessage("调试", operation, fileName, detail))
        } else {
            console.log(formatLogMessage("调试", operation, fileName, detail))
        }
    }

    // 格式化日志消息
    function formatLogMessage(type, operation, fileName, detail) {
        let message = `${type}|${operation}|${fileName}`
        if (detail) {
            message += `|${detail}`
        }
        return message
    }
} 