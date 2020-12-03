import Foundation
import GCDWebServers

open class SysProxyHelper {
        
        static let kProxyConfigPath = "/Library/Application Support/Pirate/sysproxyconfig"
        public let kDefaultPacURL = "http://127.0.0.1:41087/proxy.pac";
        static public let kSysProxyConfigVersion = "0.1.7";
        
        public static func checkVersion() -> Bool {
                let task = Process()
                task.launchPath = kProxyConfigPath
                task.arguments = ["version"]

                let pipe = Pipe()
                task.standardOutput = pipe
                let fd = pipe.fileHandleForReading
                task.launch()

                task.waitUntilExit()

                if task.terminationStatus != 0 {
                        return false
                }

                let res = String(data: fd.readDataToEndOfFile(), encoding: String.Encoding.utf8) ?? ""
                if res.contains(kSysProxyConfigVersion) {
                        return true
                }
                return false
        }

        public static func install() -> Bool {
                
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: kProxyConfigPath) || !checkVersion() {
                        let scriptPath = "\(Bundle.main.resourcePath!)/install_proxy_helper.sh"
                        let appleScriptStr = "do shell script \"bash \(scriptPath)\" with administrator privileges"
                        let appleScript = NSAppleScript(source: appleScriptStr)
                        
                        var dict: NSDictionary?
                        if let _ = appleScript?.executeAndReturnError(&dict) {
                                return true
                        } else {
                                return false
                        }
                }
                return true
        }
        
        static func SetupProxy(isGlocal:Bool) -> Bool{
                if isGlocal{
                        return executeSetting(args: ["global"])
                }else{
                        return executeSetting(args: ["pac"])
                }
        }
        
        static func RemoveSetting() -> Bool{
                return executeSetting(args: ["disable"])
        }
        
        static private func executeSetting(args:[String]?) -> Bool{
                let task = Process()
                task.launchPath = kProxyConfigPath
                task.arguments = args
                task.launch()
                task.waitUntilExit()
                return task.terminationStatus == 0
        }
}
