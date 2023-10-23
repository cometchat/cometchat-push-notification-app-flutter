import UIKit
import Flutter
import PushKit
import flutter_callkit_incoming
import Foundation

func createUUID(sessionid: String) -> String {
    let components = sessionid.components(separatedBy: ".")

    if let lastComponent = components.last {
        let truncatedString = String(lastComponent.prefix(32)) // Discard extra characters
        let uuid = truncatedString.replacingOccurrences(of: "(\\w{8})(\\w{4})(\\w{4})(\\w{4})(\\w{12})", with: "$1-$2-$3-$4-$5", options: .regularExpression, range: nil).uppercased()
        return uuid;
    }

    return UUID().uuidString;
}

func convertDictionaryToJsonString(dictionary: [String: Any]) -> String? {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .sortedKeys)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
    } catch {
        print("Error converting dictionary to JSON: \(error.localizedDescription)")
    }

    return nil
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        if #available(iOS 11.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        let appInfoChannel = FlutterMethodChannel(name: "com.cometchat.flutter_pn",
            binaryMessenger: controller.binaryMessenger)
        
        appInfoChannel.setMethodCallHandler({
              (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
              if call.method == "getAppInfo" {
                var appInfo: [String: String] = [:]
                appInfo["bundleId"] = Bundle.main.bundleIdentifier
                appInfo["version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                result(appInfo)
              } else {
                result(FlutterMethodNotImplemented)
              }
            })

        //Setup VOIP
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Call back from Recent history
    override func application(_ application: UIApplication,
                              continue userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard let handleObj = userActivity.handle else {
            return false
        }

        guard let isVideo = userActivity.isVideo else {
            return false
        }
        let objData = handleObj.getDecryptHandle()
        let nameCaller = objData["nameCaller"] as? String ?? ""
        let handle = objData["handle"] as? String ?? ""
        let data = flutter_callkit_incoming.Data(id: UUID().uuidString, nameCaller: nameCaller, handle: handle, type: isVideo ? 1 : 0)
        //set more data...
        //data.nameCaller = nameCaller
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.startCall(data, fromPushKit: true)

        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        //Save deviceToken to your server
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("didInvalidatePushTokenFor")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }

    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("didReceiveIncomingPushWith")
        guard type == .voIP else { return }
        print("93 didReceiveIncomingPushWith")

        if let userInfo = payload.dictionaryPayload as? [String : Any], let messageObject =
            userInfo["message"], let dict = messageObject as? [String : Any] {
            let category = dict["category"] as! String

            print("99 didReceiveIncomingPushWith category: \(category)")
            switch category {
            case "message": break
            case "action": break
            case "custom": break
            case "call":
                if let callDataObject = dict["data"], let callData = callDataObject as? [String : Any] {
                    let callStatus = callData["action"] as! String
                    print("99 didReceiveIncomingPushWith callStatus: \(callStatus)")

                    switch callStatus {
                    case "initiated":
                        if let entitiesDataObject = callData["entities"], let entitiesData = entitiesDataObject as? [String : Any] {
                            if let byDataObject = entitiesData["by"], let byData = byDataObject as? [String : Any] {
                                if let byEntityDataObject = byData["entity"], let byEntityData = byEntityDataObject  as? [String : Any] {
                                    if let onDataObject = entitiesData["on"], let onData = onDataObject as? [String : Any] {
                                        if let onEntityDataObject = onData["entity"], let onEntityData = onEntityDataObject  as? [String : Any] {
                                            let nameCaller = byEntityData["name"] as! String;
                                            let handle = nameCaller
                                            let sessionid = onEntityData["sessionid"] as! String;
                                            let callUUID = createUUID(sessionid: sessionid)
                                            let data = flutter_callkit_incoming.Data(id: callUUID, nameCaller: nameCaller, handle: handle, type: 1)
                                            data.extra = ["message": convertDictionaryToJsonString(dictionary: dict)]
                                            data.duration = 55000 // has to be greater than the CometChat duration
                                            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
                                        }
                                    }
                                }
                            }
                        }; break
                    case "unanswered", "cancelled", "rejected":
                        if let entitiesDataObject = callData["entities"], let entitiesData = entitiesDataObject as? [String : Any] {
                            if let byDataObject = entitiesData["by"], let byData = byDataObject as? [String : Any] {
                                if let byEntityDataObject = byData["entity"], let byEntityData = byEntityDataObject  as? [String : Any] {
                                    if let onDataObject = entitiesData["on"], let onData = onDataObject as? [String : Any] {
                                        if let onEntityDataObject = onData["entity"], let onEntityData = onEntityDataObject  as? [String : Any] {
                                            let nameCaller = byEntityData["name"] as! String;
                                            let handle = nameCaller
                                            let sessionid = onEntityData["sessionid"] as! String;
                                            let callUUID = createUUID(sessionid: sessionid);

                                            let data = flutter_callkit_incoming.Data(id: callUUID, nameCaller: nameCaller, handle: handle, type: 0)
                                            data.extra = ["message": convertDictionaryToJsonString(dictionary: dict)]
                                            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
                                        }
                                    }
                                }
                            }
                        }; break
                    default: break
                    }
                }; break
            default: break
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("DispatchQueue.main.asyncAfter called")
            completion()
        }
    }
}
