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
package com.worklight.ibmmobilefirstplatformfoundationliveupdate;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import com.worklight.ibmmobilefirstplatformfoundationliveupdate.api.Configuration;
import com.worklight.ibmmobilefirstplatformfoundationliveupdate.api.ConfigurationListener;
import com.worklight.wlclient.api.WLFailResponse;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

/**
 * Cordova plugin implementation: read the action and parse the json parameters
 * depending on the json content the plugin will call the Live Update adapter
 * by using the Live Update native SDK.
 * @owner Mordechai Taitelman
 */
public class LiveUpdatePlugin extends CordovaPlugin {

    public static final String ACTION_GET_CONFIG = "getConfiguration";
    public static final String SEG_PARAM_KEY = "segmentId";
    public static final String CACHE_PARAM_KEY = "useClientCache";
    public static final String PARAMETERS_PARAM_KEY = "params";

    /**
     * @param action          the action to execute. currently only "getConfiguration" is supported
     * @param args            JSON Array of arguments for the plugin. The JSON can contains three elements: segmentId, useClientCache and params.
     * For example : {"params": { "a": 2, "c": true} , "useClientCache": true } , or {"segmentId": "vip" , "useClientCache": true }
     * In normal flow only one of the two will be used: either 'segmentId' or 'params'.
     * If , accidentally user supplies both, the method will ignore the params.
     * @param callbackContext the callbackContext used when calling back into JavaScript.
     * @return A PluginResult object with a status and message along with boolean success result.
     */
    public boolean execute(final String action, final CordovaArgs args, final CallbackContext callbackContext) throws JSONException {
        LOG.d("execute", "entering with action:" + action);
        try {
            if (ACTION_GET_CONFIG.equals(action)) {
                final String firstParam = args.getString(0);

                // if the user sent non-JSON object , the parser will throw an exception
                JSONObject actionParams = new JSONObject(firstParam);
                LOG.d("execute", "json parameters are:" + actionParams.toString());
                final String segmentId = actionParams.optString(SEG_PARAM_KEY, null);
                final Boolean useClientCache = actionParams.optBoolean(CACHE_PARAM_KEY, true); // cache will be enabled by default
                final JSONObject params = actionParams.optJSONObject(PARAMETERS_PARAM_KEY);
                if (segmentId != null) {
                    // If the user supplied segment ID, we'll use it and ignore the params.
                    getBySegmentId(callbackContext, segmentId, useClientCache);
                } else {
                    LOG.d("execute", "trying to find configuration from:" + params);
                    // if user supplied params, use it.
                    getByMap(callbackContext, params, useClientCache);
                }
            } else {
                LOG.d("execute", "unsupported action " + action + " for this plugin");
                PluginResult pluginResult = new PluginResult(PluginResult.Status.INVALID_ACTION, action);
                callbackContext.sendPluginResult(pluginResult);
            }

            return true;

        } catch (Exception e) {
            String errorMsg = e.getLocalizedMessage();

            if (e.getMessage().startsWith("End of input")) {
                // the JSON exception message for empty string is not helpful so we'll replace it:
                errorMsg  = "Invalid JSON format for first parameter";
            }
            LOG.d("exception:", e.getLocalizedMessage());
            callbackContext.error(errorMsg);
            return false;
        }
    }

    private void getBySegmentId(final CallbackContext callbackContext, String segmentId, Boolean useClientCache) {
        LiveUpdateManager.getInstance().obtainConfiguration(segmentId, useClientCache, new PluginConfigurationListener(callbackContext));
    }

    private void getByMap(final CallbackContext callbackContext, JSONObject params, Boolean useClientCache) {
        Map<String, String> map = new HashMap<String, String>();
        // If we have params, use them, otherwise, we'll send an empty map, which means without user-defined parameters.
        if (params != null) {
            Iterator<String> iterator = params.keys();
            while(iterator.hasNext()) {
                String key = iterator.next();
                map.put(key, params.optString(key,""));
            }
        }
        LOG.d("getByMap", "map size:"+map.size());
        LiveUpdateManager.getInstance().obtainConfiguration(map, useClientCache, new PluginConfigurationListener(callbackContext));
    }


    class PluginConfigurationListener implements ConfigurationListener {
        final CallbackContext callbackContext;

        public PluginConfigurationListener(final CallbackContext callback) {
             callbackContext = callback;
        }

        @Override
        public void onSuccess(final Configuration configuration) {
            PluginResult pluginResult = null;
            try {
                LOG.d("onSuccess", "got :" + configuration);
                JSONObject json = ((ConfigurationInstance)configuration).getData().getJSONObject(ConfigurationInstance.DATA_KEY);
                pluginResult = new PluginResult(PluginResult.Status.OK,json);
            } catch (JSONException ex) {
                LOG.d("exception:", ex.getLocalizedMessage());
                pluginResult = new PluginResult(PluginResult.Status.ERROR,ex.getLocalizedMessage());
            }
            callbackContext.sendPluginResult(pluginResult);
        }

        @Override
        public void onFailure(WLFailResponse wlFailResponse) {
            PluginResult pluginResult = null;

            JSONObject failResponse = new JSONObject();
            try {
                LOG.d("onFailure", "got :" + wlFailResponse);
                failResponse = wlFailResponseToJson(wlFailResponse);
                pluginResult = new PluginResult(PluginResult.Status.ERROR, failResponse);
            } catch (JSONException ex) {
                LOG.d("exception:", ex.getLocalizedMessage());
                pluginResult = new PluginResult(PluginResult.Status.ERROR, ex.getLocalizedMessage());
            }
            callbackContext.sendPluginResult(pluginResult);
        }

        private JSONObject wlFailResponseToJson (WLFailResponse wlFailResponse) throws JSONException {
            JSONObject failResponse = new JSONObject();
            failResponse.put("status", wlFailResponse.getStatus());
            if (wlFailResponse.getResponseJSON() != null) {
                LOG.d("wlFailResponseToJson", "found JSON resonse");
                failResponse.put("errorMsg", wlFailResponse.getResponseJSON());
            } else if (wlFailResponse.getResponseText() != ""){
                LOG.d("wlFailResponseToJson", "found Text resonse");
                failResponse.put("errorMsg", wlFailResponse.getResponseText());
            } else {
                LOG.d("wlFailResponseToJson", "found only error code");
                failResponse.put("errorMsg", wlFailResponse.getErrorMsg());
            }
            return failResponse;
        }

    }
}
