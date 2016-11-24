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

import com.worklight.common.Logger;
import com.worklight.ibmmobilefirstplatformfoundationliveupdate.api.Configuration;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * ConfigurationInstance - an implementation class for Configuration
 *
 * @since 8.0.0
 * @author Ishai Borovoy
 * @see Configuration
 */
public class ConfigurationInstance implements Configuration{
    private static final Logger logger = Logger.getInstance(ConfigurationInstance.class.getName());
    
    public static final String FEATURES_KEY = "features";
    public static final String PROPERTIES_KEY = "properties";
    public static final String DATA_KEY = "data";

    private JSONObject data;
    private String id;

    public JSONObject getData() {
        return data;
    }

    public String getId() {
        return id;
    }

    public ConfigurationInstance(String id, JSONObject data) {
        this.id = id;
        this.data = data;
    }

    @Override
    public Boolean isFeatureEnabled(String featureId) {
        Boolean isFeatureEnabled = null;
        try {
            isFeatureEnabled =  this.data.getJSONObject(DATA_KEY).getJSONObject(FEATURES_KEY).getBoolean(featureId);
        } catch (JSONException e) {
            logger.error("isFeatureEnabled: Cannot get feature " + featureId);
        }
        return isFeatureEnabled;
    }

    @Override
    public String getProperty(String propertyId) {
        String property = null;
        try {
            property =  this.data.getJSONObject(DATA_KEY).getJSONObject(PROPERTIES_KEY).getString(propertyId);
        } catch (JSONException e) {
            logger.error("getProperty: Cannot get property " + propertyId);
        }
        return property;
    }

    @Override
    public String toString() {
        return "ConfigurationInstance{" +
                "data=" + data +
                ", id='" + id + '\'' +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        ConfigurationInstance that = (ConfigurationInstance) o;

        if (data != null ? !data.equals(that.data) : that.data != null) return false;
        return id != null ? id.equals(that.id) : that.id == null;
    }

    @Override
    public int hashCode() {
        int result = data != null ? data.hashCode() : 0;
        result = 31 * result + (id != null ? id.hashCode() : 0);
        return result;
    }
}
