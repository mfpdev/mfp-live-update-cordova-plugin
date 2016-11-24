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

public class LiveUpdateManager {
    private let serviceURL: String = "adapters/liveUpdateAdapter/configuration"
    private let configurationScope : String = "configuration-user-login"
    
    public static let sharedInstance = LiveUpdateManager()
    
    private init() {
    }
    
    /**
     Obtains a configuration from server / cache by a segment id
     
     - Parameter segment - the segment id which will be used by configuration adapter to return configuration
     
     - Parameter useCache - default is true, use false to explicitly obtain the configuration from the configuration adapter
     
     - Parameter completionHandler - the competition for retrieving the Configuration
     */
    public func obtainConfiguration (segment: String!, useCache: Bool = true, completionHandler: (configuration: Configuration?, error: NSError?) -> Void) {
        let encodedSegment = ecodeString(segment)
        let url = NSURL(string: serviceURL.stringByAppendingString("/\(encodedSegment!)"))!
        
        OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: segment = \(segment), useCache = \(useCache), url = \(url)")
        self.obtainConfiguration(segment, url: url, params: nil, useCache: useCache, completionHandler: completionHandler)
        
        
    }
    
    /**
    Obtains a configuration from server / cache by params
     
     - Parameter params - the parameters which will be used by configuration adapter to return configuration
     
     - Parameter useCache - default is true, use false to explicitly obtain the configuration from the configuration adapter
     
     - Parameter completionHandler - the competition for retrieving the Configuration
     */
    public func obtainConfiguration (params: [String:String], useCache: Bool = true, completionHandler: (configuration: Configuration?, error: NSError?) -> Void) {
        let url = NSURL(string: serviceURL)!
        let id = buildIDFromParams(params)
       
    
        
        OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: params = \(params), useCache = \(useCache), url = \(url)")
        self.obtainConfiguration(id, url: url, params: params, useCache: useCache, completionHandler: completionHandler)
    }
    
    
    private func obtainConfiguration (id : String, url: NSURL, params: [String: String]?, useCache: Bool, completionHandler: (configuration: Configuration?, error: NSError?) -> Void) {
        if let cachedConfig = LocalCache.getConfiguration(id) where useCache == true {
            // Get cached configuration
            OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: Retrieved cached configuration. configuration = \(cachedConfig)")
            completionHandler(configuration: cachedConfig, error: nil)
        } else {
            sendConfigRequest(id, url: url, params: params) { configuration, error in
                OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: Retrieving new configuration from server. configuration = \(configuration)")
                completionHandler(configuration: configuration, error: error)
            }
        }
    }
    
    private func sendConfigRequest(id: String, url:NSURL, params: [String: String]?, completionHandler: (Configuration?, NSError?) -> Void) {
        let configurationServiceRequest = WLResourceRequest (URL: url, method: WLHttpMethodGet, scope: configurationScope)
        
        OCLogger.getLogger().logTraceWithMessages("sendConfigRequest: id = \(id), url = \(url), params = \(params)")
        
        if params != nil {
            for (paramName, paramValue) in params! {
                configurationServiceRequest.setQueryParameterValue(paramValue, forName: paramName)
            }
        }
        configurationServiceRequest.sendWithCompletionHandler { wlResponse, wlError in
            var configuration: Configuration? = nil
            
            if (wlError == nil) {
                var json = wlResponse.responseJSON as? [String: AnyObject]
                
                if json == nil {
                    OCLogger.getLogger().logFatalWithMessages("sendConfigRequest: invalid JSON response")
                    json = [String: AnyObject]()
                }
                configuration = ConfigurationInstance(id :id, data: json!)
                // Save to cache
                
                OCLogger.getLogger().logTraceWithMessages("sendConfigRequest: saving configuration to cache. configuration = \(configuration)")
                LocalCache.saveConfiguration(configuration!)
            } else {
                OCLogger.getLogger().logFatalWithMessages("sendConfigRequest: error while retriving configuration from server. error = \(wlError)")
            }
            completionHandler(configuration, wlError)
        }
    }
    
    private func buildIDFromParams (params: [String: String]?)->String {
        OCLogger.getLogger().logTraceWithMessages("buildIDFromParams: params = \(params)")
        var paramsId = ""
        if (params?.count > 0) {
            for (paramName, paramValue) in params! {
                paramsId += "_\(paramName)_\(paramValue)"
            }
        }
        OCLogger.getLogger().logTraceWithMessages("buildIDFromParams: paramsId = \(paramsId)")
        return paramsId
    }
    
    private func ecodeString(path: String?) -> String? {
        return path?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())
    }
}