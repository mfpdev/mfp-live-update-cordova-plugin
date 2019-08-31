function getConfiguration(success,error,options) {
  setTimeout(()=>{
    error({"errorMsg" : "Live Update is not supported in browser or preview mode"});
  },1000)
}

module.exports = {
  getConfiguration : getConfiguration
}

require('cordova/exec/proxy').add('LiveUpdatePlugin', module.exports);