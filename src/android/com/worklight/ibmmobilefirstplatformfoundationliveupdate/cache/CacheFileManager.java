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
package com.worklight.ibmmobilefirstplatformfoundationliveupdate.cache;

import com.worklight.common.Logger;
import com.worklight.ibmmobilefirstplatformfoundationliveupdate.ConfigurationInstance;
import com.worklight.ibmmobilefirstplatformfoundationliveupdate.api.Configuration;
import com.worklight.wlclient.api.WLClient;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone;

/**
 * CacheFileManager
 *
 * @since 8.0.0
 * @author Ishai Borovoy
 */
public class CacheFileManager {
    private static final Logger logger = Logger.getInstance(CacheFileManager.class.getName());

    //CacheFileManager static functions
    protected static boolean isExpired(String configurationId) {
        MetadataFile metadataFile = new MetadataFile();
        return metadataFile.isExpired(configurationId);
    }

    protected static Configuration configuration(String configurationId) {
        ConfigurationFile configurationFile = new ConfigurationFile();
        return configurationFile.readConfiguration(configurationId);
    }

    protected static void save(Configuration configuration) {
        ConfigurationFile configurationFile = new ConfigurationFile();
        configurationFile.save(configuration);
    }


    //CacheFile
    private  static class CacheFile {
        private final static String FOLDER_CACHE = "liveupdate/cache";

        private String name;

        public CacheFile(String name) {
            this.name = name;
        }

        protected File getFolder(String configurationId) {
            return new File(WLClient.getInstance().getContext().getCacheDir(), FOLDER_CACHE + "/" + configurationId);
        }

        protected File getFile (String configurationId) {
            return new File(getFolder(configurationId), name);
        }

    }

    //JSONFile => CacheFile
    private static abstract class JSONFile extends CacheFile{

        public JSONFile(String name) {
            super(name);
        }

        /**
         * Read cached JSON file and convert it to JSONObject
         * @param configurationId -  the configuration id
         * @return JSONObject
         */
        protected JSONObject read(String configurationId) {
            BufferedReader in = null;
            File cachedFile = getFile(configurationId);

            if (!cachedFile.exists()) {
                return null;
            }

            JSONObject json = null;

            try {
                logger.trace("read: configurationId = " + configurationId);
                FileReader reader = new FileReader(cachedFile);
                in = new BufferedReader(reader);

                StringBuilder jsonSB = new StringBuilder();
                String line;
                while((line = in.readLine()) != null){
                    jsonSB.append(line);
                }
                json =  new JSONObject(jsonSB.toString());
            }  catch (IOException e) {
                logger.error("read: cannot read json file:" + cachedFile.getAbsolutePath(), null, e);
            } catch (JSONException e) {
                logger.error("read: cannot read json file to JSONObject", null, e);
            } finally {
                try {
                    if (in != null) {
                        in.close();
                    }
                }  catch (IOException e) {
                    logger.fatal("read: cannot close file:" + cachedFile.getAbsolutePath(), null, e);
                }
            }
            return json;
        }

        protected void save(Configuration configuration) {
            logger.trace("save: configurationId = " + configuration);

            if (configuration != null && configuration instanceof ConfigurationInstance) {
                JSONObject json = generateJson((ConfigurationInstance) configuration);
                if (json != null) {
                    save(((ConfigurationInstance) configuration).getId(), json);
                    return;
                }
            }

            logger.error("save: cannot save configuration. configuration = " + configuration);
        }

        private void save(String configurationId, JSONObject json) {
            BufferedWriter out = null;
            File cachedFile = getFile(configurationId);
            File cachedDir = getFolder(configurationId);

            try {
                createDirsAndFile(cachedFile, cachedDir);
                logger.trace("save: configurationId = " + configurationId + ",json = " + json);
                FileWriter writer = new FileWriter(cachedFile, false);
                out = new BufferedWriter(writer);
                out.write(json.toString());
            }  catch (IOException e) {
                logger.fatal("save: cannot save file:" + cachedFile.getAbsolutePath(), null, e);
            }  finally {
                try {
                    if (out != null) {
                        out.flush();
                        out.close();
                    }
                }  catch (IOException e) {
                    logger.fatal("save: cannot close file:" + cachedFile.getAbsolutePath(), null, e);
                }
            }
        }

        private void createDirsAndFile(File cachedFile, File cachedDir) throws IOException {
            if (!cachedDir.exists()) {
                boolean isDirsCreated = cachedDir.mkdirs();
                if (isDirsCreated) {
                    logger.error("createDirsAndFile: cannot create dirs file:" + cachedDir.getAbsolutePath());
                }
            }
            if (!cachedFile.exists()) {
                boolean isFileCreated = cachedFile.createNewFile();
                if (isFileCreated) {
                    logger.error("createDirsAndFile: cannot create file file:" + cachedFile.getAbsolutePath());
                }
            }
        }

        protected abstract JSONObject generateJson(ConfigurationInstance configuration) ;

    }

    //ConfigurationFile => JSONFile
    private static class ConfigurationFile extends JSONFile {

        public ConfigurationFile() {
            super("configuration.json");
        }

        public Configuration readConfiguration (String configurationId) {
            JSONObject json = super.read(configurationId);
            return json != null ? new ConfigurationInstance(configurationId, json) : null;
        }

        @Override
        public void save(Configuration configuration) {
            if (configuration != null) {
                super.save(configuration);
                new MetadataFile().save(configuration);
            }
        }

        @Override
        protected JSONObject generateJson(ConfigurationInstance configurationInstance) {
            return configurationInstance.getData();
        }
    }

    //MetadataFile => JSONFile
    private static class MetadataFile extends JSONFile {
        private final static String ATTRIBUTE_EXPIRES_AT  = "expiresAt";
        private final static String FORMATTER_PATTERN    = "EEE, dd MMM yyyy HH:mm:ss z";
        private final static String FORMATTER_TIMEZONE  = "GMT";

        public MetadataFile() {
            super("metadata.json");
        }

        public boolean isExpired(String configurationId) {
            boolean isExpired = true;
            JSONObject json = read(configurationId);
            if (json != null) {
                try {
                    String expiresAt = json.getString(ATTRIBUTE_EXPIRES_AT);
                    SimpleDateFormat expiresSimpleDateFormat = new SimpleDateFormat(FORMATTER_PATTERN, Locale.US);
                    expiresSimpleDateFormat.setTimeZone(TimeZone.getTimeZone(FORMATTER_TIMEZONE));

                    Date expireDate = expiresSimpleDateFormat.parse(expiresAt);
                    isExpired = new Date().after(expireDate);
                } catch (Exception e) {
                    logger.error("isExpired: cannot get expiresAt field");
                }
            }
            return isExpired;
        }

        @Override
        protected JSONObject generateJson(ConfigurationInstance configuration) {
            JSONObject json = new JSONObject();
            try {
                json.put(ATTRIBUTE_EXPIRES_AT, configuration.getData().getString(ATTRIBUTE_EXPIRES_AT));
            } catch (JSONException e) {
                logger.error("generateJson: cannot add expiresAt metadata field");
                json = null;
            }
            return json;
        }
    }

}
