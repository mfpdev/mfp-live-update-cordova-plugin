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
package com.worklight.ibmmobilefirstplatformfoundationliveupdate.api;

import com.worklight.wlclient.api.WLFailResponse;

/**
 * ConfigurationListener interface
 * </p>
 * Listener for obtainConfiguration API
 *
 * @see com.worklight.ibmmobilefirstplatformfoundationliveupdate.LiveUpdateManager
 * @author Ishai Borovoy
 * @since 8.0.0
 */
public interface ConfigurationListener {
    /***
     * This method is called when obtain configuration from the server / cache is successful
     *
     * @param configuration - the obtained configuration from server / cache
     * @see Configuration
     */
    void onSuccess(Configuration configuration);

    /***
     * This method is called when obtain configuration from the server / cache is unsuccessful
     *
     * @param wlFailResponse - the failure response object
     * @see  WLFailResponse
     */
    void onFailure(WLFailResponse wlFailResponse);
}
