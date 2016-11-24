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
//  CacheFileManager.swift
//
//  Created by Oleg Sternberg & Ishai Borovoy on 19/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import IBMMobileFirstPlatformFoundation

class CacheFileManager {
    
    //Static methods
    static func isExpired(configurationId: String) -> Bool {
        let metadataFile = MetadataFile()
        return metadataFile.isExpired(configurationId)
    }
    
    static func configuration(configurationId: String) -> Configuration? {
        let configurationFile = ConfigurationFile()
        return configurationFile.read(configurationId)
    }
    
    static func save(configuration: Configuration) {
        let configurationFile = ConfigurationFile()
        
        configurationFile.save(configuration)
    }
    
    //CacheFile
    class CacheFile {
        private static let folderCache = "liveupdate/cache"
        
        private static let manager = NSFileManager.defaultManager()
        private static let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        private static let documents: AnyObject = paths[0]
        
        private var name: String
        
        init(name: String) {
            self.name = name
        }
        
        private static func getFolder(configurationId: String) -> String {
            return documents.stringByAppendingPathComponent("\(folderCache)/\(configurationId)")
        }
        
        private func getFullName(configurationId: String) -> String {
            return CacheFile.getFolder(configurationId) + "/" + name
        }
    }

    //JsonFile
    class JsonFile: CacheFile {
        
        func save(configuration: Configuration) {
            OCLogger.getLogger().logTraceWithMessages("\(NSStringFromClass(JsonFile)) save: configurationId = \(configuration)")
            
            if let configInstance  =  configuration as? ConfigurationInstance{
                save(configInstance.id, json: generateJson(configInstance))
            } else {
                OCLogger.getLogger().logFatalWithMessages("\(NSStringFromClass(JsonFile)) save: cannot save configuration. configuration = \(configuration)")
            }
        }
        
        func save(configurationId: String, json: [String: AnyObject]) {
            do {
                OCLogger.getLogger().logTraceWithMessages("\(NSStringFromClass(JsonFile)) save: configurationId = \(configurationId) ,json = \(json)")
                try NSFileManager.defaultManager().createDirectoryAtPath(CacheFile.getFolder(configurationId), withIntermediateDirectories: true, attributes: nil)
                
                let data = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue: 0))
                
                if !data.writeToFile(getFullName(configurationId), atomically: false) {
                    OCLogger.getLogger().logFatalWithMessages("failed to write file '\(name)'")
                }
            } catch let error as NSError {
                OCLogger.getLogger().logFatalWithMessages("\(NSStringFromClass(JsonFile)) save: Cannot save configuration. error = \(error), configurationId = \(configurationId) ,json = \(json)")
            }
        }
        
        func read(configurationId: String) -> [String: AnyObject]? {
            OCLogger.getLogger().logTraceWithMessages("\(NSStringFromClass(JsonFile)) read: configurationId = \(configurationId)")
            
            let fullName = getFullName(configurationId)
            
            if !CacheFile.manager.fileExistsAtPath(fullName) {
                return nil
            }
            
            do {
                let content = try String(contentsOfFile: fullName, encoding: NSUTF8StringEncoding)
                
                if let data = content.dataUsingEncoding(NSUTF8StringEncoding) {
                    return try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String: AnyObject]
                }
            } catch let error as NSError {
                OCLogger.getLogger().logFatalWithMessages("\(NSStringFromClass(JsonFile)) save: Cannot read configuration. error = \(error), configurationId = \(configurationId)")
            }
            
            return nil
        }
        
        private func generateJson(configuration: ConfigurationInstance) -> [String: AnyObject] {
            preconditionFailure("'JsonFile.savedJson' method must be overridden")
        }
    }
    
    
    
    // ConfigurationFile
    private class ConfigurationFile: JsonFile {
        private static let configurationName = "configuration.json"
        private let metadataFile = MetadataFile()
        
        init() {
            super.init(name: ConfigurationFile.configurationName)
        }
        
        override func save(configuration: Configuration) {
            if let configInstance = configuration as? ConfigurationInstance{
                //Save metadata and configuration files
                super.save(configInstance)
                metadataFile.save(configInstance)
            }
        }
        
        func read(configurationId: String) -> ConfigurationInstance? {
            if let json = super.read(configurationId) {
                return ConfigurationInstance(id: configurationId, data: json)
            }
            
            return nil
        }
        
        override func generateJson(configuration: ConfigurationInstance) -> [String: AnyObject] {
            return configuration.data
        }
    }

    //MetadataFile
    private class MetadataFile: JsonFile {
        private static let metaDataName       = "metadata.json"
        private static let attributeExpireAt  = "expiresAt"
        private static let formatterPatern    = "EEE, dd MMM yyyy HH:mm:ss z"
        private static let formatterTimeZone  = "GMT"
        private static let formatterLocale    = "US"
        
        init() {
            super.init(name: MetadataFile.metaDataName)
        }
        
        override func generateJson(configuration: ConfigurationInstance) -> [String: AnyObject] {
            var json = [String: AnyObject]()
            json[MetadataFile.attributeExpireAt]  = configuration.data[MetadataFile.attributeExpireAt] as? String
            return json
        }
        
        func isExpired(configurationId: String) -> Bool {
            OCLogger.getLogger().logTraceWithMessages("isExpired: configurationId = \(configurationId)")
            
            if let metadata = read(configurationId), expiresAt = metadata[MetadataFile.attributeExpireAt] as? String {
                // NSDateFormatter is not thread-safe on versions earlier than 7
                let formatter = NSDateFormatter()
                
                formatter.dateFormat = MetadataFile.formatterPatern
                formatter.timeZone = NSTimeZone(name: MetadataFile.formatterTimeZone)
                formatter.locale = NSLocale(localeIdentifier: MetadataFile.formatterLocale)
                
                if let expiresAtDate = formatter.dateFromString(expiresAt) {
                    let now = NSDate()
                    OCLogger.getLogger().logTraceWithMessages("isExpired: expiresAtDate = \(expiresAtDate) isExpired = \(expiresAtDate.compare(now) == NSComparisonResult.OrderedAscending)")
                    return expiresAtDate.compare(now) == NSComparisonResult.OrderedAscending
                }
            } else {
                OCLogger.getLogger().logTraceWithMessages("isExpired: metadata not found. configurationId = \(configurationId)")
            }
            
            return true
        }
    }
}