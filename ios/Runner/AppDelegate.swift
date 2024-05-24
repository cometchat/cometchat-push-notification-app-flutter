import UIKit
import Flutter
import PushKit
import flutter_callkit_incoming
import Foundation
import Firebase
import CallKit

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
class AppDelegate:FlutterAppDelegate, PKPushRegistryDelegate {
    
    var pushRegistry: PKPushRegistry!
    

   override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
 GeneratedPluginRegistrant.register(with: self)
       
               UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate

               // Request permission for notifications
               UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                   // Handle the authorization result
                   if granted {
                       print("Notification authorization granted")
                   } else {
                       print("Notification authorization denied")
                   }
               }

 let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
 let appInfoChannel = FlutterMethodChannel(name: "com.cometchat.flutter_pn",
     binaryMessenger: controller.binaryMessenger)
 
 appInfoChannel.setMethodCallHandler({
       (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
       if call.method == "getAppInfo" {
         var appInfo: [String: String] = [:]
         appInfo["bundleId"] = Bundle.main.bundleIdentifier
         appInfo["version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
         result(appInfo)
       } else if call.method == "endCall" {
           if let activeCall = self.activeCallSession {
               SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(activeCall)

               result(true)
           }else {
           result(false)}
         } else {
         result(FlutterMethodNotImplemented)
       }
     })
 

        
        // Register for VoIP pushes
        pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        
        return true
    }

    // MARK: - PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        //Save deviceToken to your server
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {

        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }
    

    var activeCallSession: flutter_callkit_incoming.Data?
    
    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
        
        // Check if the app is in the foreground
                if UIApplication.shared.applicationState == .active {
                    
                    // App is in the foreground, do nothing or perform any desired action
                    return
                }
        
        guard type == .voIP else { return }

        if let payloadData = payload.dictionaryPayload as? [String : Any] {
            
            
            let category = payloadData["type"] as! String

            
            switch category {
            case "chat": break
            case "action": break
            case "custom": break
            case "call":
                
                    let callAction = payloadData["callAction"] as! String
                
                let senderName = payloadData["senderName"] as! String;
                let handle = senderName
                let sessionid = payloadData["sessionId"] as! String;
                let callType = payloadData["callType"] as! String;
                let callUUID = createUUID(sessionid: sessionid)
                
                let data = flutter_callkit_incoming.Data(id: callUUID, nameCaller: senderName, handle: handle, type: callType == "audio" ? 0:1 )
                data.extra = ["message": convertDictionaryToJsonString(dictionary: payloadData)]

                    switch callAction {
                    case "initiated":
                                            
                           data.duration = 55000 // has to be greater than the CometChat duration
                        
                            activeCallSession = data
                            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true)
                            
                     
                           
                                        break
                    case "unanswered", "cancelled", "rejected":
                                SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(data)
                        
                                break
                    default: break
                    }
                 break
            default: break
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            
            completion()
        }
    }

   
    
    // This method is called when a notification is received while the app is in the foreground
       override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
           // Check if the app is in the foreground
           if UIApplication.shared.applicationState == .active {
               // Suppress the notification when the app is in the foreground
               completionHandler([])
           } else {
               // Allow the notification to be displayed when the app is in the background or terminated
               completionHandler([.alert, .sound, .badge])
           }
       }
}



