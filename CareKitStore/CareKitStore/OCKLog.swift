/*
 Copyright (c) 2019, Apple Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
import Foundation
import os.log

public struct OCKLog {
    public static var isEnabled = true
}

extension OSLog {
    static var store: OSLog {
        OCKLog.isEnabled ?
            OSLog(
                subsystem: Bundle.main.bundleIdentifier!,
                category: "CareKitStore"
            ) : .disabled
    }
}

struct logger {
    private static let oslogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "com.advatarsystems")

    public static func info(_ message: String,
                            file: String = #file,
                            functionName: String = #function,
                            lineNumber: Int = #line,
                            columnNumber: Int = #column) {
        let url = URL(filePath: file)
        let fileName = url.lastPathComponent
        logger.oslogger.info("💙 INFO \(fileName):\(functionName)@\(lineNumber) \(message)")
    }

    public static func verbose(_ message: String, functionName: String = #function,
                            lineNumber: Int = #line,
                            columnNumber: Int = #column) {
        #if targetEnvironment(simulator)
        logger.oslogger.info("💜 VERBOSE \(functionName)#\(lineNumber) \(message)")
        #endif
    }

    public static func debug(_ message: String, functionName: String = #function,
                            lineNumber: Int = #line,
                            columnNumber: Int = #column) {
        logger.oslogger.debug("💚 DEBUG \(functionName)#\(lineNumber) \(message)")
    }
    
    public static func error(_ message: String, functionName: String = #function,
                            lineNumber: Int = #line,
                            columnNumber: Int = #column) {
        logger.oslogger.error("❤️ ERROR \(functionName)#\(lineNumber) \(message)")
    }

}
