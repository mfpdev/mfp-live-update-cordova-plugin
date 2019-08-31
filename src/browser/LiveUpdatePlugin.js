function getConfiguration(success,error,options) {
  error({"errorMsg" : "Live Update is not supported in browser or preview mode"});
}

module.exports = {
  getConfiguration : getConfiguration
}

require('cordova/exec/proxy').add('LiveUpdatePlugin', module.exports);