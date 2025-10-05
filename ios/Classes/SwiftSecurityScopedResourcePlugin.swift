import Flutter
import UIKit

public class SwiftSecurityScopedResourcePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "security_scoped_resource", binaryMessenger: registrar.messenger())
        let instance = SwiftSecurityScopedResourcePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any> else {
            result(FlutterError(code: "InvalidArguments", message: "Arguments needs to be a dictionary", details: nil))
            return
        }
        
        switch call.method {
        case "startAccessingSecurityScopedResource":
            guard let dir = args["path"] as? String,
                  let isDirectory = args["isDirectory"] as? Bool else {
                result(FlutterError(code: "InvalidArguments", message: "argument 'path' or 'isDirectory' invalid", details: nil))
                return
            }
            let url = URL(fileURLWithPath: dir, isDirectory: isDirectory)
            result(url.startAccessingSecurityScopedResource())
            
        case "stopAccessingSecurityScopedResource":
            guard let dir = args["path"] as? String,
                  let isDirectory = args["isDirectory"] as? Bool else {
                result(FlutterError(code: "InvalidArguments", message: "argument 'path' or 'isDirectory' invalid", details: nil))
                return
            }
            let url = URL(fileURLWithPath: dir, isDirectory: isDirectory)
            url.stopAccessingSecurityScopedResource()
            result(true)
            
        case "createBookmark":
            guard let dir = args["path"] as? String,
                  let isDirectory = args["isDirectory"] as? Bool else {
                result(FlutterError(code: "InvalidArguments", message: "argument 'path' or 'isDirectory' invalid", details: nil))
                return
            }
            let url = URL(fileURLWithPath: dir, isDirectory: isDirectory)
            do {
                let data = try url.bookmarkData(options: [.withSecurityScope],
                                                includingResourceValuesForKeys: nil,
                                                relativeTo: nil)
                result(FlutterStandardTypedData(bytes: data))
            } catch {
                result(FlutterError(code: "CreateBookmarkFailed", message: error.localizedDescription, details: nil))
            }
            
        case "restoreBookmark":
            guard let rawData = args["bookmarkData"] as? FlutterStandardTypedData else {
                result(FlutterError(code: "InvalidArguments", message: "argument 'bookmarkData' is invalid", details: nil))
                return
            }
            let data = rawData.data
            do {
                var isStale: ObjCBool = false
                let url = try NSURL(resolvingBookmarkData: data,
                                    options: [.withSecurityScope],
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale) as URL
                let success = url.startAccessingSecurityScopedResource()
                result([
                    "path": url.path,
                    "stale": isStale.boolValue,
                    "started": success
                ])
            } catch {
                result(FlutterError(code: "RestoreBookmarkFailed", message: error.localizedDescription, details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
