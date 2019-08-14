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
    @objc func getConfiguration (_ command: CDVInvokedUrlCommand){
        let actionName = "getConfiguration"
        if let configuration = command.arguments[0] as? NSDictionary{
            print("\(actionName): Configuration parameters are: \(configuration)")

            let segmentId = configuration.value(forKey: "segmentId") as? String ?? "all"
            let useClientCache = configuration.value(forKey: "useClientCache") as? Bool ?? true
            let params = configuration.value(forKey: "params") as? [String:String] ?? [String:String]()

            if (params.isEmpty){
                getConfigurationWithSegmentId(segmentId, useClientCache: useClientCache, command: command)
            } else {
                getConfigurationWithParams(params, useClientCache: useClientCache, command: command)
            }
        } else {
            print("\(actionName): Invalid arguments.")
            self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid arguments."), callbackId: command.callbackId)
        }
    }

    func getConfigurationWithSegmentId(_ segmentId: String, useClientCache: Bool, command: CDVInvokedUrlCommand){
        LiveUpdateManager.sharedInstance.obtainConfiguration(segmentId, useCache: useClientCache, completionHandler: completionHandler("getConfigurationWithSegmentId", command: command))
    }

    func getConfigurationWithParams(_ params: [String:String], useClientCache: Bool, command: CDVInvokedUrlCommand){
        LiveUpdateManager.sharedInstance.obtainConfiguration(params, useCache: useClientCache, completionHandler: completionHandler("getConfigurationWithParams", command: command))
    }

    func completionHandler(_ actionName: String, command: CDVInvokedUrlCommand) -> (_ configuration: Configuration?, _ error: NSError?) -> Void {
        func ch (_ configuration: Configuration?, error: NSError?) -> Void {
            if (error == nil){
                let configurationInstance = configuration as! ConfigurationInstance
                print("\(actionName): obtainConfiguration success with data: \(String(describing: configurationInstance.data["data"]))")
                self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs:configurationInstance.data["data"] as? [AnyHashable: Any]), callbackId: command.callbackId)
            } else {
                let failResponse: [String:AnyObject] = ["errorMsg":error!.localizedDescription as AnyObject]
                print("\(actionName): obtainConfiguration with error: \(failResponse)")
                self.commandDelegate!.send(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: failResponse), callbackId: command.callbackId)
            }
        }
        return ch
    }
}
