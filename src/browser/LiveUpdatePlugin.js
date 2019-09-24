const serviceURL = "adapters/liveUpdateAdapter/configuration";
const configurationScope = "configuration-user-login";
//const logger = WL.Logger.create({pkg: 'MFPLiveUpdate'});

function isEmpty(obj) {
  for (var prop in obj) {
    if (obj.hasOwnProperty(prop))
      return false;
  }
  return true;
}

function buildIDFromParams(params) {
  //OCLogger.getLogger().logTraceWithMessages("buildIDFromParams: params = \(String(describing: params))")
  var paramsId = "";
  if (!isEmpty(params)) {
    for (var key in params) {
      if (params.hasOwnProperty(key)) {
        configurationServiceRequest.setQueryParameter(key, params[key]);
        paramsId += "_" + key + "_" + params[key];
      }
    }
  }
  //OCLogger.getLogger().logTraceWithMessages("buildIDFromParams: paramsId = \(paramsId)")
  return paramsId
}

function configurationInstance(id, data) {
  var data = data;
  var id = id;
  
  this.isFeatureEnabled = function (featureId) {
    let features = data["features"];
    if (!isEmpty(features[featureId])) {
      let feature = features[featureId];
      return feature;
    }
    return false;
  }

  this.getProperty = function (propertyId) {
    let properties = data["properties"];
    if (!isEmpty(properties[propertyId])) {
      let property = properties[propertyId];
      return property;
    }
    return null;
  }

  this.data = data;
  this.id = id;
};

function sendConfigRequest(id, url, params) {
  return new Promise((resolve, reject) => {
    var configurationServiceRequest = new WLResourceRequest( url, WLResourceRequest.GET, { scope: configurationScope });
    //OCLogger.getLogger().logTraceWithMessages("sendConfigRequest: id = \(id), url = \(url), params = \(String(describing: params))")
    if (!isEmpty(params)) {
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
            // OCLogger.getLogger().logFatalWithMessages("sendConfigRequest: invalid JSON response")
            json = {};
        }
        let configuration = new configurationInstance(id, json["data"]);
        resolve(configuration);
      },
      (error) => {
        // OCLogger.getLogger().logFatalWithMessages("sendConfigRequest: error while retriving configuration from server. error = \(String(describing: wlError))")
        reject(error);
      }    
    );
  });
}

function obtainConfiguration(id, url, params, useCache, success, error) {
  if (false) {
    const cachedConfig = LocalCache.getConfiguration(id);
    // OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: Retrieved cached configuration. configuration = \(cachedConfig)");
    success(cachedConfig);
  } else {
    sendConfigRequest(id, url, params).then(
      (configuration) => {
        success(configuration);
       // OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: Retrieving new configuration from server. configuration = \(String(describing: configuration))")
      }, (er) => {
        error(er);
      // OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: Retrieving new configuration from server. configuration = \(String(describing: configuration))")
      });
  }
}

function getConfigurationWithSegmentId(segmentId, useClientCache, success, error) {
  const encodedSegment = encodeURI(segmentId);;
  const url = serviceURL + "/" + encodedSegment;
  //OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: segment = \(String(describing: segment)), useCache = \(useCache), url = \(url)")
  obtainConfiguration(segmentId, url, {}, useClientCache, success, error);
}

function getConfigurationWithParams(params, useClientCache, success, error) {
  const url = serviceURL;
  const id = buildIDFromParams(params)
  //OCLogger.getLogger().logDebugWithMessages("obtainConfiguration: params = \(params), useCache = \(useCache), url = \(url)")
  obtainConfiguration(id, url, params, useClientCache, success, error);
}

function getConfiguration(success, error, options) {
  const segmentId = (typeof options['segmentId'] !== "undefined") ? options['segmentId'] : 'all';
  const useClientCache = (typeof options['useClientCache'] !== "undefined" && typeof options['useClientCache'] === "boolean") ? options['useClientCache'] : true;
  const params = (typeof options['params'] !== "undefined") ? options['segmentId'] : {};
  if (isEmpty(params)) {
    getConfigurationWithSegmentId(segmentId, useClientCache, success, error);
  } else {
    getConfigurationWithParams(params, useClientCache, success, error);
  }
}

module.exports = {
  getConfiguration: getConfiguration
}

require('cordova/exec/proxy').add('LiveUpdatePlugin', module.exports);