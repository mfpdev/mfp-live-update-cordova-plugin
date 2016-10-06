# IBM MobileFirst Foundation Live Update SDK plug-in
To add IBM MobileFirst Foundation Live Update capabilities to an existing Cordova application, you add the `cordova-plugin-mfp-liveupdate` plug-in to your application.

The Live Update Cordova plug-in lets you query runtime configuration properties and features which you set in the Live Update Settings screen in the MobileFirst Operations Console. With Live Update integrated in your application you can implement feature toggling, A/B testing, feature segmentation and more.

To learn more on how to use Live Update [review this tutorial](https://mobilefirstplatform.ibmcloud.com/tutorials/en/foundation/8.0/using-the-mfpf-sdk/live-update/).

## Installation
Add this plug-in in the same way that you add any other Cordova plug-in to your application.  
For example, with the Cordova CLI type: 
`cordova create MyNewPRoject com.mycompany.name
cd MyNewPRoject
cordova plugin add cordova-plugin-mfp-liveupdate@latest
cordova platform add android`
(or `cordova plugin add http://github.com/mfpdev/mfp-live-update-cordova-plugin` to get latest).

As this plugin depends on cordova-plugin-mfp logger, it will automatically download it too in case your Cordova application does not have it already.

## Supported platforms
- Android v4.1 and above
- iOS v8.0 and above

## Configuration In MobileFirst Operation Console
1. Download and deploy the Live Update adapter as [instructed in the tutorial](https://mobilefirstplatform.ibmcloud.com/tutorials/en/foundation/8.0/using-the-mfpf-sdk/live-update/#adding-live-update-to-mobilefirst-server).

2. Add a scope mapping for `configuration-user-login` in MobileFirst Operations Console → [your application] → Security tab → Scope-Elements Mapping. Map it to an empty string if you want to use the
default protection or to a security check if you're using one.

	> Learn more about [scope mapping](https://mobilefirstplatform.ibmcloud.com/tutorials/en/foundation/8.0/authentication-and-security/authorization-concepts/#scope-mapping)

3. once you deployed the adapter you can add schemas and features from the MobileFirst Operations Console → [your application] → Live Update Settings

Once you've setup schemas and features you can start use the client side API.

## Sample Usages of the API

```javascript
    LiveUpdateManager.obtainConfiguration({
            segmentId: "segment1",
            useClientCache: false
        }, function(configuration) {
            console.log('ObtainConfiguration succeeded. Property1: ' + JSON.stringify(configuration.properties.property1));
        },
        function(err) {
            console.log("ObtainConfiguration failed with error:\n" + JSON.stringify(err));
        });

    LiveUpdateManager.obtainConfiguration({
            params: {param1: 'value1'},
            useClientCache: false
        }, function(configuration) {
            console.log('ObtainConfiguration succeeded. Property1: ' + JSON.stringify(configuration.properties.property1));
        },
        function(err) {
            console.log("ObtainConfiguration failed with error:\n" + JSON.stringify(err));
        });
```

## Licnense
Copyright 2016 IBM Corp.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
