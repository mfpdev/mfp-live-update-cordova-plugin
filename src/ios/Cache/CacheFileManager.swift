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
    static func isExpired(_ configurationId: String) -> Bool {
        let metadataFile = MetadataFile()
        return metadataFile.isExpired(configurationId)
    }
    
    static func configuration(_ configurationId: String) -> Configuration? {
        let configurationFile = ConfigurationFile()
        return configurationFile.read(configurationId)
    }
    
    static func save(_ configuration: Configuration) {
        let configurationFile = ConfigurationFile()
        
        configurationFile.save(configuration)
    }
    
    //CacheFile
    class CacheFile {
        fileprivate static let folderCache = "liveupdate/cache"
        
        fileprivate static let manager = FileManager.default
        fileprivate static let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        fileprivate static let documents: AnyObject = paths[0] as AnyObject
        
        fileprivate var name: String
        
        init(name: String) {
            self.name = name
        }
        
        fileprivate static func getFolder(_ configurationId: String) -> String {
            return documents.appendingPathComponent("\(folderCache)/\(configurationId)")
        }
        
        fileprivate func getFullName(_ configurationId: String) -> String {
            return CacheFile.getFolder(configurationId) + "/" + name
        }
    }

    //JsonFile
    class JsonFile: CacheFile {
        
        func save(_ configuration: Configuration) {
            OCLogger.getLogger().logTraceWithMessages("\(NSStringFromClass(JsonFile.self)) save: configurationId = \(configuration)")
            
            if let configInstance  =  configuration as? ConfigurationInstance{
                save(configInstance.id, json: generateJson(configInstance))
            } else {
                OCLogger.getLogger().logFatalWithMessages("\(NSStringFromClass(JsonFile.self)) save: cannot save configuration. configuration = \(configuration)")
            }
        }
        
        func save(_ configurationId: String, json: [String: AnyObject]) {
            do {
                OCLogger.getLogger().logTraceWithMessages("\(NSStringFromClass(JsonFile.self)) save: configurationId = \(configurationId) ,json = \(json)")
                try FileManager.default.createDirectory(atPath: CacheFile.getFolder(configurationId), withIntermediateDirectories: true, attributes: nil)
                
                let data = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions(rawValue: 0))
                
                if !((try? data.write(to: URL(fileURLWithPath: getFullName(configurationId)), options: [])) != nil) {
                    OCLogger.getLogger().logFatalWithMessages("failed to write file '\(name)'")
                }
            } catch let error as NSError {
                OCLogger.getLogger().logFatalWithMessages("\(NSStringFromClass(JsonFile.self)) save: Cannot save configuration. error = \(error), configurationId = \(configurationId) ,json = \(json)")
            }
        }
        
        func read(_ configurationId: String) -> [String: AnyObject]? {
            OCLogger.getLogger().logTraceWithMessages("\(NSStringFromClass(JsonFile.self)) read: configurationId = \(configurationId)")
            
            let fullName = getFullName(configurationId)
            
            if !CacheFile.manager.fileExists(atPath: fullName) {
                return nil
            }
            
            do {
                let content = try String(contentsOfFile: fullName, encoding: String.Encoding.utf8)
                
                if let data = content.data(using: String.Encoding.utf8) {
                    return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
                }
            } catch let error as NSError {
                OCLogger.getLogger().logFatalWithMessages("\(NSStringFromClass(JsonFile.self)) save: Cannot read configuration. error = \(error), configurationId = \(configurationId)")
            }
            
            return nil
        }
        
        fileprivate func generateJson(_ configuration: ConfigurationInstance) -> [String: AnyObject] {
            preconditionFailure("'JsonFile.savedJson' method must be overridden")
        }
    }
    
    
    
    // ConfigurationFile
    fileprivate class ConfigurationFile: JsonFile {
        fileprivate static let configurationName = "configuration.json"
        fileprivate let metadataFile = MetadataFile()
        
        init() {
            super.init(name: ConfigurationFile.configurationName)
        }
        
        override func save(_ configuration: Configuration) {
            if let configInstance = configuration as? ConfigurationInstance{
                //Save metadata and configuration files
                super.save(configInstance)
                metadataFile.save(configInstance)
            }
        }
        
        func read(_ configurationId: String) -> ConfigurationInstance? {
            if let json = super.read(configurationId) {
                return ConfigurationInstance(id: configurationId, data: json)
            }
            
            return nil
        }
        
        override func generateJson(_ configuration: ConfigurationInstance) -> [String: AnyObject] {
            return configuration.data
        }
    }

    //MetadataFile
    fileprivate class MetadataFile: JsonFile {
        fileprivate static let metaDataName       = "metadata.json"
        fileprivate static let attributeExpireAt  = "expiresAt"
        fileprivate static let formatterPatern    = "EEE, dd MMM yyyy HH:mm:ss z"
        fileprivate static let formatterTimeZone  = "GMT"
        fileprivate static let formatterLocale    = "US"
        
        init() {
            super.init(name: MetadataFile.metaDataName)
        }
        
        override func generateJson(_ configuration: ConfigurationInstance) -> [String: AnyObject] {
            var json = [String: AnyObject]()
            json[MetadataFile.attributeExpireAt]  = configuration.data[MetadataFile.attributeExpireAt] as? String as AnyObject?
            return json
        }
        
        func isExpired(_ configurationId: String) -> Bool {
            OCLogger.getLogger().logTraceWithMessages("isExpired: configurationId = \(configurationId)")
            
            if let metadata = read(configurationId), let expiresAt = metadata[MetadataFile.attributeExpireAt] as? String {
                // NSDateFormatter is not thread-safe on versions earlier than 7
                let formatter = DateFormatter()
                
                formatter.dateFormat = MetadataFile.formatterPatern
                formatter.timeZone = TimeZone(identifier: MetadataFile.formatterTimeZone)
                formatter.locale = Locale(identifier: MetadataFile.formatterLocale)
                
                if let expiresAtDate = formatter.date(from: expiresAt) {
                    let now = Date()
                    OCLogger.getLogger().logTraceWithMessages("isExpired: expiresAtDate = \(expiresAtDate) isExpired = \(expiresAtDate.compare(now) == ComparisonResult.orderedAscending)")
                    return expiresAtDate.compare(now) == ComparisonResult.orderedAscending
                }
            } else {
                OCLogger.getLogger().logTraceWithMessages("isExpired: metadata not found. configurationId = \(configurationId)")
            }
            
            return true
        }
    }
}
