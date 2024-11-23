pragma Singleton
import QtQuick

QtObject {
    // 日志函数
    function logOperation(fileManager, operation, fileName) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.info(operation + ": " + fileName)
        } else {
            console.log(operation + ": " + fileName)
        }
    }
    
    function logError(fileManager, operation, fileName, error) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.error(operation + ": " + fileName + " - " + error)
        } else {
            console.error(operation + ": " + fileName + " - " + error)
        }
    }
    
    function logWarning(fileManager, operation, fileName, warning) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.warning(operation + ": " + fileName + " - " + warning)
        } else {
            console.warn(operation + ": " + fileName + " - " + warning)
        }
    }
    
    function logDebug(fileManager, operation, fileName, detail) {
        if (fileManager && fileManager.logger) {
            fileManager.logger.debug(operation + ": " + fileName + (detail ? " - " + detail : ""))
        } else {
            console.log(operation + ": " + fileName + (detail ? " - " + detail : ""))
        }
    }
} 