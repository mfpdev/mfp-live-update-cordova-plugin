const serviceURL = "adapters/liveUpdateAdapter/configuration";
const configurationScope = "configuration-user-login";
let logger;

var __LocalCache = function () {
  var LIVEUPDATE_KEY = 'com.mfp.liveupdate.';

  // .................... Private methods ...........................

  function __isExpired(configuration) {
    if(configuration &&  typeof configuration['data'] !== "undefined" && typeof configuration.data['expiresAt'] !== "undefined") {
      var currentTime = Date.now();
      var expireTime = Date.parse(configuration.data.expiresAt);
      return expireTime < currentTime;
    }
    return true;
  }

  // .................... Public methods ...........................

  this.getConfiguration = (configurationId) => {
    var key = LIVEUPDATE_KEY + configurationId;
    var configuration = WL.DAO.getItem(key);
    return __isExpired(configuration) ? null : configuration;
  }

  this.saveConfiguration = (configurationId, Configuration) => {
    var key = LIVEUPDATE_KEY + configurationId;
    WL.DAO.setItem(key, Configuration);
  }
};

var WLLiveupdateCache = new __LocalCache();

function __isEmpty(obj) {
  for (var prop in obj) {
    if (obj.hasOwnProperty(prop))
      return false;
  }
  return true;
}

function __buildIDFromParams(params) {
  logger.trace('trace', "__buildIDFromParams: params = " + JSON.stringify(params) );
  var paramsId = "";
  if (!__isEmpty(params)) {
    for (var key in params) {
      if (params.hasOwnProperty(key)) {
        configurationServiceRequest.setQueryParameter(key, params[key]);
        paramsId += "_" + key + "_" + params[key];
      }
    }
  }
  logger.trace('trace', "__buildIDFromParams: paramsId = " + paramsId );
  return paramsId
}

function __configurationInstance(id, data) {
  var data = data;
  var id = id;

  this.isFeatureEnabled = function (featureId) {
    let features = data["features"];
    if (!__isEmpty(features[featureId])) {
      let feature = features[featureId];
      return feature;
    }
    return false;
  }

  this.getProperty = function (propertyId) {
    let properties = data["properties"];
    if (!__isEmpty(properties[propertyId])) {
      let property = properties[propertyId];
      return property;
    }
    return null;
  }

  this.data = data;
  this.id = id;
};

function __sendConfigRequest(id, url, params) {
  return new Promise((resolve, reject) => {
    var configurationServiceRequest = new WLResourceRequest(url, WLResourceRequest.GET, { scope: configurationScope });
    logger.trace('trace',"__sendConfigRequest: id = " + id + ", url = " + url + ", params = " + JSON.stringify(params) );
    
    if (!__isEmpty(params)) {
      for (var key in params) {
        if (params.hasOwnProperty(key)) {
          configurationServiceRequest.setQueryParameter(key, params[key]);
        }
      }
    }
    configurationServiceRequest.send().then(
      (response) => {
        var json = response.responseJSON;
        if (typeof json === "undefined") {
          logger.fatal('fatal', "__sendConfigRequest: invalid JSON response");
          json = {};
        }
        var data = json["data"];
        data["expiresAt"] = json["expiresAt"];
        let configuration = new __configurationInstance(id, data);
        WLLiveupdateCache.saveConfiguration(id, configuration);
        resolve(configuration);
      },
      (error) => {
        logger.fatal('fatal', "__sendConfigRequest: error while retriving configuration from server. error = " + JSON.stringify(error));
        reject(error);
      }
    );
  });
}

function __obtainConfiguration(id, url, params, useCache, success, error) {
  if (WLLiveupdateCache.getConfiguration(id) && useCache) {
    const cachedConfig = WLLiveupdateCache.getConfiguration(id);
    logger.debug('debug', "__obtainConfiguration: Retrieved cached configuration. configuration = " + JSON.stringify(cachedConfig));
    success(cachedConfig);
  } else {
    __sendConfigRequest(id, url, params).then(
      (configuration) => {
        success(configuration);
        logger.debug('debug', "__obtainConfiguration: Retrieving new configuration from server. configuration = " + JSON.stringify(configuration));
      }, (er) => {
        error(er);
        logger.debug('debug', "__obtainConfiguration: Error in Retrieving configuration from server. Error = " + JSON.stringify(er));
      });
  }
}

function __getConfigurationWithSegmentId(segmentId, useClientCache, success, error) {
  const encodedSegment = encodeURI(segmentId);;
  const url = serviceURL + "/" + encodedSegment;
  logger.debug('debug', "__obtainConfiguration: segment = " + segmentId + ", useCache = " + useClientCache + ", url = " + url);
  __obtainConfiguration(segmentId, url, {}, useClientCache, success, error);
}

function __getConfigurationWithParams(params, useClientCache, success, error) {
  const url = serviceURL;
  const id = __buildIDFromParams(params)
  logger.debug('debug', "__obtainConfiguration: params = " + JSON.stringify(params) + ", useCache = " + useClientCache + ", url = " + url);
  __obtainConfiguration(id, url, params, useClientCache, success, error);
}

function getConfiguration(success, error, options) {
  logger = WL.Logger.create({pkg: 'com.mfp.liveupdate'});
  if (typeof options[0] !== "undefined") {
    options = options[0];
  }
  const segmentId = (typeof options['segmentId'] !== "undefined") ? options['segmentId'] : 'all';
  const useClientCache = (typeof options['useClientCache'] !== "undefined" && typeof options['useClientCache'] === "boolean") ? options['useClientCache'] : true;
  const params = (typeof options['params'] !== "undefined") ? options['segmentId'] : {};
  if (__isEmpty(params)) {
    __getConfigurationWithSegmentId(segmentId, useClientCache, success, error);
  } else {
    __getConfigurationWithParams(params, useClientCache, success, error);
  }
}

module.exports = {
  getConfiguration: getConfiguration
}

require('cordova/exec/proxy').add('LiveUpdatePlugin', module.exports);