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


/// Cordova plugin implementation that uses the LiveUpdate native SDK
@objc(LiveUpdatePlugin) class LiveUpdatePlugin : CDVPlugin {
    /**
     Get configuration from the server.

     - Parameter command - A CDVInvokedUrlCommand object containing the arguments sent from JavaScript.

     - Returns: A CDVPluginResult object with status and message.
     */
    func getConfiguration (command: CDVInvokedUrlCommand){
        let actionName = "getConfiguration"
        if let configuration = command.arguments[0] as? NSDictionary{
            print("\(actionName): Configuration parameters are: \(configuration)")

            let segmentId = configuration.valueForKey("segmentId") as? String ?? ""
            let useClientCache = configuration.valueForKey("useClientCache") as? Bool ?? true
            let params = configuration.valueForKey("params") as? [String:String] ?? [String:String]()

            if (segmentId != ""){
                getConfigurationWithSegmentId(segmentId, useClientCache: useClientCache, command: command)
            } else {
                getConfigurationWithParams(params, useClientCache: useClientCache, command: command)
            }
        } else {
            print("\(actionName): Invalid arguments.")
            self.commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Invalid arguments."), callbackId: command.callbackId)
        }
    }

    func getConfigurationWithSegmentId(segmentId: String, useClientCache: Bool, command: CDVInvokedUrlCommand){
        LiveUpdateManager.sharedInstance.obtainConfiguration(segmentId, useCache: useClientCache, completionHandler: completionHandler("getConfigurationWithSegmentId", command: command))
    }

    func getConfigurationWithParams(params: [String:String], useClientCache: Bool, command: CDVInvokedUrlCommand){
        LiveUpdateManager.sharedInstance.obtainConfiguration(params, useCache: useClientCache, completionHandler: completionHandler("getConfigurationWithParams", command: command))
    }

    func completionHandler(actionName: String, command: CDVInvokedUrlCommand) -> (configuration: Configuration?, error: NSError?) -> Void {
        func ch (configuration: Configuration?, error: NSError?) -> Void {
            if (error == nil){
                let configurationInstance = configuration as! ConfigurationInstance
                print("\(actionName): obtainConfiguration success with data: \(configurationInstance.data["data"])")
                self.commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:configurationInstance.data["data"] as! [NSObject:AnyObject]), callbackId: command.callbackId)
            } else {
                let failResponse: [String:AnyObject] = ["errorMsg":error!.localizedDescription]
                print("\(actionName): obtainConfiguration with error: \(failResponse)")
                self.commandDelegate!.sendPluginResult(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsDictionary: failResponse), callbackId: command.callbackId)
            }
        }
        return ch
    }
}
