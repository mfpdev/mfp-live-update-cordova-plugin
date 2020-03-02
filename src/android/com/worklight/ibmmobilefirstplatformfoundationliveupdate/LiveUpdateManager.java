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

import android.content.Context;
import android.webkit.URLUtil;

import com.worklight.common.Logger;
import com.worklight.ibmmobilefirstplatformfoundationliveupdate.api.Configuration;
import com.worklight.ibmmobilefirstplatformfoundationliveupdate.api.ConfigurationListener;
import com.worklight.ibmmobilefirstplatformfoundationliveupdate.cache.LocalCache;
import com.worklight.wlclient.api.WLClient;
import com.worklight.wlclient.api.WLFailResponse;
import com.worklight.wlclient.api.WLResourceRequest;
import com.worklight.wlclient.api.WLResponse;
import com.worklight.wlclient.api.WLResponseListener;

import org.json.JSONObject;

import java.net.URI;
import java.net.URL;
import java.util.Map;

/**
 * LiveUpdateManager
 * </p>
 * A manager class for the  LiveUpdate APIs
 *
 * @author Ishai Borovoy
 * @since 8.0.0
 */

public class LiveUpdateManager {

    private static LiveUpdateManager instance = null;
    private final static String LIVEUPDATE_CLIENT_SCOPE = "liveupdate.mobileclient";
    private String SERVICE_URL;


    private static final Logger logger = Logger.getInstance(LiveUpdateManager.class.getName());
    /**
     * getInstance
     *
     * @param context Android {@link Context}
     * @return LiveUpdateManager singleton instance
     */
    public static synchronized LiveUpdateManager getInstance(Context context) {
        if (instance == null) {
            instance = new LiveUpdateManager(context);
        }
        return instance;
    }

    private LiveUpdateManager(Context context) {
        try {
            WLClient client = null;
            // Get the applicationId and backend route from core
            try {
                client = WLClient.getInstance();
            } catch (Exception e) {
                client = WLClient.createInstance(context);
            }
            URL url = client.getServerUrl();
            StringBuilder routeBuilder = new StringBuilder();
            routeBuilder.append(url.getProtocol());
            routeBuilder.append("://");
            routeBuilder.append(url.getHost());
            int port = url.getPort();
            if(port != -1) {
                routeBuilder.append(":");
                routeBuilder.append(port);
            }
            String urlPath = url.getPath();
            String[] split = urlPath.split("/api");
            String contextRoute = urlPath.substring(0, split[0].lastIndexOf( "/" ));
            routeBuilder.append(contextRoute);

            String applicationRoute = routeBuilder.toString();
            String packageName = context.getPackageName();
            SERVICE_URL =  applicationRoute + "/mfpliveupdate/v1/" + packageName + "/configuration";
            if (!URLUtil.isValidUrl(SERVICE_URL)) {
                throw new RuntimeException("LiveUpdateManager:initialize() - An error occured while initializing Liveupdate service. Reason : Invalid HOST URL");
            }
        } catch (Exception e) {
            logger.error("LiveUpdateManager:initialize() - An error occured while initializing Liveupdate service.");
            throw new RuntimeException(e);
        }
    }

    /**
     * obtainConfiguration - obtains a configuration from server / cache by a segment id
     * </p>
     * The cache is enabled for this API
     *
     * @param segmentId - the segment id
     * @param configurationListener - the configuration listener for receiving the configuration
     */
    public void obtainConfiguration (String segmentId, ConfigurationListener configurationListener) {
        this.obtainConfiguration(segmentId, true, configurationListener);
    }

    /**
     * obtainConfiguration - obtains a configuration from server / cache by params
     * </p>
     * The cache is enabled for this API
     *
     * @param params - the params used by the server to return a configuration.
     * @param configurationListener - the configuration listener for receiving the configuration
     */
    public void obtainConfiguration (Map<String,String> params, ConfigurationListener configurationListener) {
        this.obtainConfiguration(params, true, configurationListener);
    }


    /**
     * obtainConfiguration - obtains a configuration from server / cache
     * @param useCache - true to use cache, false to always obtains from server
     * @param configurationListener - the configuration listener for receiving the configuration
     */
    public void obtainConfiguration (boolean useCache, ConfigurationListener configurationListener) {
        URI url = URI.create(SERVICE_URL + "/all");


        logger.debug("obtainConfiguration: useCache = " + useCache + ", url = " + url);
        this.obtainConfiguration("all", url, null, useCache, configurationListener);
    }

    /**
     * obtainConfiguration - obtains a configuration from server / cache by a segment id
     * @param segmentId - the segment id
     * @param useCache - true to use cache, false to always obtains from server
     * @param configurationListener - the configuration listener for receiving the configuration
     */
    public void obtainConfiguration (String segmentId, boolean useCache, ConfigurationListener configurationListener) {
        URI url = URI.create(SERVICE_URL + "/" + segmentId);


        logger.debug("obtainConfiguration: segment = " + segmentId + ", useCache = " + useCache + ", url = " + url);
        this.obtainConfiguration(segmentId, url, null, useCache, configurationListener);
    }

    /**
     * obtainConfiguration - obtains a configuration from server / cache by params
     * @param params - the params used by the server to return a configuration
     * @param useCache - true to use cache, false to always obtain configuration from server
     * @param configurationListener - the configuration listener for receiving the configuration
     */
    public void obtainConfiguration (Map<String,String> params, boolean useCache, ConfigurationListener configurationListener) {
        URI url = URI.create(SERVICE_URL);
        String id = buildIDFromParams(params);

        logger.debug("obtainConfiguration: params = " + params + ", useCache = " + useCache + ", url = " + url);
        this.obtainConfiguration(id, url, params, useCache, configurationListener);
    }


    private void obtainConfiguration (String id, URI url, Map<String,String> params, boolean useCache, final ConfigurationListener configurationListener) {
        Configuration cachedConfiguration = LocalCache.getConfiguration(id);

        if (cachedConfiguration != null && useCache) {
            logger.debug("obtainConfiguration: Retrieved cached configuration. configuration = " + cachedConfiguration);
            configurationListener.onSuccess(cachedConfiguration);
        } else {
            sendConfigRequest(id, url, params, configurationListener);
        }
    }


    private void sendConfigRequest(final String id, URI url, Map<String,String> params, final ConfigurationListener configurationListener) {
        WLResourceRequest configurationServiceRequest = new WLResourceRequest(url, WLResourceRequest.GET, LIVEUPDATE_CLIENT_SCOPE);

        logger.trace("sendConfigRequest: id = " + id + ", url = " + url + "params = " + params);

        if (params != null) {
            for (String paramKey : params.keySet()) {
                configurationServiceRequest.setQueryParameter(paramKey, params.get(paramKey));
            }

        }

        configurationServiceRequest.send(new WLResponseListener() {
            @Override
            public void onSuccess(WLResponse wlResponse) {
                JSONObject json = wlResponse.getResponseJSON();

                if (json == null) {
                    logger.error("sendConfigRequest: invalid JSON response");
                    json = new JSONObject();
                }
                Configuration configuration = new ConfigurationInstance(id, json);
                // Save to cache

                logger.trace("sendConfigRequest: saving configuration to cache. configuration = " +configuration);
                LocalCache.saveConfiguration(configuration);
                configurationListener.onSuccess(configuration);
            }

            @Override
            public void onFailure(WLFailResponse wlFailResponse) {
                logger.error("sendConfigRequest: error while retriving configuration from server. error = " + wlFailResponse.getErrorMsg());
                configurationListener.onFailure(wlFailResponse);
            }
        });
    }

    private String buildIDFromParams (Map<String,String> params) {
        logger.trace("buildIDFromParams: params = " + params);
        String paramsId = "";
        if (params != null && params.size() > 0) {
            for (String paramKey : params.keySet()) {
                paramsId += "_" + paramKey + "" + params.get(paramKey);
            }
        }
        logger.trace("buildIDFromParams: paramsId = " + paramsId);
        return paramsId;
    }
}
