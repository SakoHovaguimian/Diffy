import OSLog

protocol Loggable {

    var loggerName: String { get }

}

extension Loggable {

    func log(_ message: String) {

        let logger = Logger(subsystem: "com.diffy.app", category: self.loggerName)
        logger.debug("\(message, privacy: .public)")

    }

}
