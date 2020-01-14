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

//
//  LiveUpdateManager.swift
//  A manager class for the  LiveUpdate APIs
//
//  Created by Oleg Sternberg & Ishai Borovoy on 14/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import IBMMobileFirstPlatformFoundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


open class LiveUpdateManager {
    fileprivate let bundleID : String = Bundle.main.bundleIdentifier!
    fileprivate let liveupdateClientScope : String = "liveupdate.mobileclient"
    fileprivate var applicationRoute: String = "";
    fileprivate var serviceURL: String = ""
    
    public static let sharedInstance = LiveUpdateManager()
    
    fileprivate init() {
        if let url = WLClient.init().serverUrl() {
            applicationRoute = url.absoluteString.replacingOccurrences(of: url.relativePath, with: "")
            serviceURL = "/mfpliveupdate/v1/\(bundleID)/configuration"
    }
    }
    
    /**
     Obtains a configuration from server / cache by a segment id
     
     - Parameter segment - the segment id which will be used by configuration adapter to return configuration
     
     - Parameter useCache - default is true, use false to explicitly obtain the configuration from the configuration adapter
     
     - Parameter completionHandler - the competition for retrieving the Configuration
     */
    open func obtainConfiguration (_ segment: String!, useCache: Bool = true, completionHandler: @escaping (_ configuration: Configuration?, _ error: NSError?) -> Void) {
        let encodedSegment = ecodeString(segment)
        let urlString = applicationRoute +  serviceURL + "/\(encodedSegment!)"
        if isValidUrl(url: urlString) {
            let url = URL(string: urlString)!
        OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: segment = \(String(describing: segment)), useCache = \(useCache), url = \(url)")
        self.obtainConfiguration(segment, url: url, params: nil, useCache: useCache, completionHandler: completionHandler)
        } else {
            let error = "Failed to initialize Liveupdate instance because server url is nil. Check the server details in mfpclient.plist"
            OCLogger.getLogger().logDebugWithMessages(error)
            completionHandler(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : error]))
    }
    }
    
    /**
    Obtains a configuration from server / cache by params
     
     - Parameter params - the parameters which will be used by configuration adapter to return configuration
     
     - Parameter useCache - default is true, use false to explicitly obtain the configuration from the configuration adapter
     
     - Parameter completionHandler - the competition for retrieving the Configuration
     */
    open func obtainConfiguration (_ params: [String:String], useCache: Bool = true, completionHandler: @escaping (_ configuration: Configuration?, _ error: NSError?) -> Void) {
        let urlString = applicationRoute + bundleID + serviceURL
        if isValidUrl(url: urlString) {
            let url = URL(string: urlString)!
        let id = buildIDFromParams(params)
        OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: params = \(params), useCache = \(useCache), url = \(url)")
        self.obtainConfiguration(id, url: url, params: params, useCache: useCache, completionHandler: completionHandler)
        } else {
            let error = "Failed to initialize Liveupdate instance because server url is nil. Check the server details in mfpclient.plist"
            OCLogger.getLogger().logDebugWithMessages(error)
            completionHandler(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : error]))
        }
    }
    
    
    fileprivate func obtainConfiguration (_ id : String, url: URL, params: [String: String]?, useCache: Bool, completionHandler: @escaping (_ configuration: Configuration?, _ error: NSError?) -> Void) {
        if let cachedConfig = LocalCache.getConfiguration(id) , useCache == true {
            // Get cached configuration
            OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: Retrieved cached configuration. configuration = \(cachedConfig)")
            completionHandler(cachedConfig, nil)
        } else {
            sendConfigRequest(id, url: url, params: params) { configuration, error in
                OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: Retrieving new configuration from server. configuration = \(String(describing: configuration))")
                completionHandler(configuration, error)
            }
        }
    }
    
    fileprivate func sendConfigRequest(_ id: String, url:URL, params: [String: String]?, completionHandler: @escaping (Configuration?, NSError?) -> Void) {
        let configurationServiceRequest = WLResourceRequest (url: url, method: WLHttpMethodGet, scope: liveupdateClientScope)
        
        OCLogger.getLogger().logTraceWithMessages("sendConfigRequest: id = \(id), url = \(url), params = \(String(describing: params))")
        
        if params != nil {
            for (paramName, paramValue) in params! {
                configurationServiceRequest?.setQueryParameterValue(paramValue, forName: paramName)
            }
        }
        configurationServiceRequest?.send { wlResponse, wlError in
            var configuration: Configuration? = nil
            
            if (wlError == nil) {
                var json = wlResponse?.responseJSON as? [String: AnyObject]
                
                if json == nil {
                    OCLogger.getLogger().logFatalWithMessages("sendConfigRequest: invalid JSON response")
                    json = [String: AnyObject]()
                }
                configuration = ConfigurationInstance(id :id, data: json!)
                // Save to cache
                
                OCLogger.getLogger().logTraceWithMessages("sendConfigRequest: saving configuration to cache. configuration = \(String(describing: configuration))")
                LocalCache.saveConfiguration(configuration!)
            } else {
                OCLogger.getLogger().logFatalWithMessages("sendConfigRequest: error while retriving configuration from server. error = \(String(describing: wlError))")
            }
            completionHandler(configuration, wlError as NSError?)
        }
    }
    
    fileprivate func buildIDFromParams (_ params: [String: String]?)->String {
        OCLogger.getLogger().logTraceWithMessages("buildIDFromParams: params = \(String(describing: params))")
        var paramsId = ""
        if (params?.count > 0) {
            for (paramName, paramValue) in params! {
                paramsId += "_\(paramName)_\(paramValue)"
            }
        }
        OCLogger.getLogger().logTraceWithMessages("buildIDFromParams: paramsId = \(paramsId)")
        return paramsId
    }
    
    fileprivate func ecodeString(_ path: String?) -> String? {
        return path?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
    }
    
    fileprivate func isValidUrl(url: String) -> Bool {
        let urlRegEx = "http[s]?://(([^/:.[:space:]]+(.[^/:.[:space:]]+)*)|([0-9](.[0-9]{3})))(:[0-9]+)?((/[^?#[:space:]]+)([^#[:space:]]+)?(#.+)?)?"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: url)
        return result
    }
}
