/**
 *   © Copyright 2016 IBM Corp.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

import Foundation
import IBMMobileFirstPlatformFoundation

extension OCLogger {
    
    static func  getLogger ()->OCLogger {
        return OCLogger.getInstanceWithPackage(Bundle.init(for: OCLogger.classForCoder()).bundleIdentifier)
    }
    
    func logTraceWithMessages(_ message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_TRACE, message: message, args:getVaList(args), userInfo:Dictionary<String, String>())
    }
    
    func logDebugWithMessages(_ message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_DEBUG, message: message, args:getVaList(args), userInfo:Dictionary<String, String>())
    }
    
    func logInfoWithMessages(_ message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_INFO, message: message, args:getVaList(args), userInfo:Dictionary<String, String>())
    }
    
    func logWarnWithMessages(_ message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_WARN, message: message, args:getVaList(args), userInfo:Dictionary<String, String>())
    }
    
    func logErrorWithMessages(_ message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_ERROR, message: message, args:getVaList(args), userInfo:Dictionary<String, String>())
    }
    
    func logFatalWithMessages(_ message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_FATAL, message: message, args:getVaList(args), userInfo:Dictionary<String, String>())
    }
    
    func logAnalyticsWithMessages(_ message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_ANALYTICS, message: message, args:getVaList(args), userInfo:Dictionary<String, String>())
    }
    
    //Log methods with metadata
    
    func logTraceWithUserInfo(_ userInfo:Dictionary<String, String>, message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_TRACE, message: message, args:getVaList(args), userInfo:userInfo)
    }
    
    func logDebugWithUserInfo(_ userInfo:Dictionary<String, String>, message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_DEBUG, message: message, args:getVaList(args), userInfo:userInfo)
    }
    
    func logInfoWithUserInfo(_ userInfo:Dictionary<String, String>, message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_INFO, message: message, args:getVaList(args), userInfo:userInfo)
    }
    
    func logWarnWithUserInfo(_ userInfo:Dictionary<String, String>, message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_WARN, message: message, args:getVaList(args), userInfo:userInfo)
    }
    
    func logErrorWithUserInfo(_ userInfo:Dictionary<String, String>, message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_ERROR, message: message, args:getVaList(args), userInfo:userInfo)
    }
    
    func logFatalWithUserInfo(_ userInfo:Dictionary<String, String>, message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_FATAL, message: message, args:getVaList(args), userInfo:userInfo)
    }
    
    func logAnalyticsWithUserInfo(_ userInfo:Dictionary<String, String>, message:String, _ args: CVarArg...) {
        log(withLevel: OCLogger_ANALYTICS, message: message, args:getVaList(args), userInfo:userInfo)
    }
}
