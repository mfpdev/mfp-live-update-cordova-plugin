//
//  LocalCache.swift
//  configuration-service-sdk-ios
//
//  Created by Oleg Sternberg & Ishai Borovoy on 19/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

class LocalCache {
    private static let lock = NSLock()
    
    static func getConfiguration(configurationId: String) -> Configuration? {
        lock.lock()
        defer {lock.unlock()}
        
        return CacheFileManager.isExpired(configurationId) ? nil : CacheFileManager.configuration(configurationId)
    }
    
    static func saveConfiguration(configuration: Configuration) {
        lock.lock()
        defer {lock.unlock()}
        
        CacheFileManager.save(configuration)
    }
}