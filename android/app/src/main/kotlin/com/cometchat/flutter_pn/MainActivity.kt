package com.cometchat.flutter_pn

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.cometchat.flutter_pn"
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getAppInfo") {
                val appInfo = HashMap<String, String>()
                appInfo["bundleId"] = applicationContext.packageName
                appInfo["version"] = packageManager.getPackageInfo(applicationContext.packageName, 0).versionName
                result.success(appInfo)
            } else {
                result.notImplemented()
            }
        }
    }
}
