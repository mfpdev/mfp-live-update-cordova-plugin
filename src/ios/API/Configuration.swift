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
//  Configuration.swift
//  IBMMobileFirstPlatformFoundationConfigService
//
//  Created by Ishai Borovoy on 02/05/2016.
//
//  This protocol provides API for an obtained configuration.
//  This API checks if a feature is enabled or getting value for a property.

import Foundation

public protocol Configuration {
    /**
     Check if a feature is enabled
     
     - Parameter featureId - the feature id to be checked
     
     - Returns: true if feature is enabled or nil for non existing feature.
     */
    func isFeatureEnabled (_ featureId : String)->Bool?
    
    /**
     Get value of a property
     
     - Parameter propertyId - the property id
     
     - Returns: the value for the given propertyId, or nil in case the property doesn't exist
     */
    func getProperty (_ propertyId : String)->String?
}
