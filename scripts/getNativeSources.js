
var androidFilesToCopy = [
    'com/worklight/ibmmobilefirstplatformfoundationliveupdate/LiveUpdateManager.java',
    'com/worklight/ibmmobilefirstplatformfoundationliveupdate/ConfigurationInstance.java',
    'com/worklight/ibmmobilefirstplatformfoundationliveupdate/api/Configuration.java',
    'com/worklight/ibmmobilefirstplatformfoundationliveupdate/api/ConfigurationListener.java',
    'com/worklight/ibmmobilefirstplatformfoundationliveupdate/cache/CacheFileManager.java',
    'com/worklight/ibmmobilefirstplatformfoundationliveupdate/cache/LocalCache.java'
];

var iosFilesToCopy = [
    'API/Configuration.swift',
    'API/ConfigurationInstance.swift',
    'API/LiveUpdateManager.swift',
    'Cache/CacheFileManager.swift',
    'Cache/LocalCache.swift',
    'Logger/OCLoggerSwiftExtension.swift'
];


var androidBaseUrl = 'https://raw.githubusercontent.com/mfpdev/mfp-live-update-android-sdk/master/IBMMobileFirstPlatformFoundationLiveUpdate/ibmmobilefirstplatformfoundationliveupdate/src/main/java/';
var iosBaseUrl = 'https://raw.githubusercontent.com/mfpdev/mfp-live-update-ios-sdk/master/IBMMobileFirstPlatformFoundationLiveUpdate/Source/';

// this is the function cordova will execute
module.exports = function (context) {

    https = context.requireCordovaModule('https');
    fs = context.requireCordovaModule('fs');
    path = context.requireCordovaModule('path');

    var pluginBaseDir = context.opts.plugin.dir;

    // download android in anycase to support case when user calls `cordova platform add` then `cordova plugin add` and also in reverse order
    //if (context.opts.cordova.platforms.indexOf('android') >= 0) {
        // there is an android platform in this application
        console.log("Copying native Live Update Android SDK from github.");
        downloadAll(pluginBaseDir, androidBaseUrl, 'android', androidFilesToCopy);
    //}

    // download ios in anycase to support case when user calls `cordova platform add` then `cordova plugin add` and also in reverse order
    //if (context.opts.cordova.platforms.indexOf('ios') >= 0) {
        // there is an iOS platform in this application
        console.log("Copying native Live Update iOS SDK from github.");
        downloadAll(pluginBaseDir, iosBaseUrl, 'ios', iosFilesToCopy);
    //}

}

function downloadAll(pluginBaseDir, baseUrl, platform, fileList) {
    fileList.forEach(function (filename) {
        var fileOnDisk = pluginBaseDir + '/src/' + platform + '/' + filename;
        var url = baseUrl + filename;
        makeFolder(fileOnDisk);
        downloadFile(url, fileOnDisk);
    });
}

// create a folder if it does not exist yet
function makeFolder(filePath) {
    var folder = path.dirname(filePath);
    if (!fs.existsSync(folder)) {
        fs.mkdirSync(folder);
    }
}

function downloadFile(url, destination) {
    var file = fs.createWriteStream(destination);
    var request = https.get(url, function (response) {
        response.pipe(file);
        response.on('error', function (e) {
            console.error('Unable to copy files from github');
            console.error(e);
        });
    });
}
