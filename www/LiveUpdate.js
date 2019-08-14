/**
 * Copyright 2016 IBM Corp.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var NATIVE_CLASS_NAME = "LiveUpdatePlugin";

/**
 * @param segmentId - the segement to look for.
 * @param map - this map (as JSON Array) is convered to query params to be analyzed by the Live Update Resolver API
 * for example: var liveUpdateParams = { segmentId :'18' ,useClientCache : true };
 */
var manager = {
  obtainConfiguration: function(options, successCallback, errorCallback) {
    cordova.exec(
      successCallback, // success callback function
      errorCallback, // error callback function
      NATIVE_CLASS_NAME, // Maps to Java/Swift Class
      "getConfiguration", // action name
      [options]
    );
  }
};

module.exports = manager;
