
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

    // download android and iOS native sources from external GIT repo
    // regardless of the actual installed platforms to support case when user calls
    //`cordova platform add` then `cordova plugin add` and also in reverse order
    console.log("Copying native Live Update sources from github.");
    downloadAll(pluginBaseDir, androidBaseUrl, 'android', androidFilesToCopy);
    downloadAll(pluginBaseDir, iosBaseUrl, 'ios', iosFilesToCopy);

}

function downloadAll(pluginBaseDir, baseUrl, platform, fileList) {
    fileList.forEach(function (filename) {
        var fileOnDisk = pluginBaseDir + '/src/' + platform + '/' + filename;
        var url = baseUrl + filename;
        console.log('copying '+ url + ' to '+  fileOnDisk)
        makeFolder(fileOnDisk);
        downloadFile(url, fileOnDisk);
    });
}

// create a folder if it does not exist yet
function makeFolder(filePath) {
    var folder = path.dirname(filePath);
    if (!fs.existsSync(folder)) {
        console.log('creating folder '+folder)
        fs.mkdirSync(folder);
    }
}

function downloadFile(url, destination) {
    var file = fs.createWriteStream(destination);
    console.log('downloading '+url)
    var request = https.get(url, function (response) {
        response.pipe(file);
        response.on('error', function (e) {
            console.error('Unable to copy files from github');
            console.error(e);
        });
    });
}
