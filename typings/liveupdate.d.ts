declare module LiveUpdateManager {
  /**
    * Retrieves MFP server configuration for given parameters.
    * This API should be called after Corodova was loaded (i.e. onDeviceReady() event).
    * Recommended place in MFP is wlCommonInit() method.
    *
    * @param {liveUpdateParams} a JSON string which specifies Configuration parameters.
    * currently we support 3 JSON elements: segmentId,map and useClientCache.
    * useClientCache : true (default) tells the native iOS/Android code if we want to cache the result of the calls . cache expiratrion
    * is set in the MFP admin console.
    * segmentId : direct lookup for specific segment ID in the MFP server live update DB.
    * map : (optional) - if supplied a JSON map (key:value) , this overrides any segmentId value and will search a configuration
    *             that matches the included key-value pairs.
    * for example: var liveUpdateParams = { segmentId :'18' , map :  {longitude:'31.47N' , latitude:'35.13E' } };
    * another example: var liveUpdateParams = { segmentId :'18' ,useClientCache : false};
    * @param {Function} success Mandatory function. The callback function that is invoked if the configuration search was successful
    * @param {Function} failure Mandatory function. The callback function that is invoked if the configuration lookup failed
                        the failure description in iOS is less descriptive than Android. 
    *
    * @methodOf LiveUpdatePluin#
    */
  function obtainConfiguration(
    liveUpdateParams: Object,
    success: Function,
    failure: Function
  ): void;
}
