//
//  Service.swift
//  Pirate
//
//  Created by Pirateon 2019/4/11.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Foundation
import DecentralizedShadowSocks

let KEY_FOR_SWITCH_STATE = "KEY_FOR_SWITCH_STATE"
let KEY_FOR_Pirate_MODEL = "KEY_FOR_Pirate_MODEL"
let KEY_FOR_DNS_IP = "KEY_FOR_DNS_IP"
let KEY_FOR_CURRENT_POOL_INUSE = "KEY_FOR_CURRENT_SEL_POOL_v2"
let KEY_FOR_CURRENT_MINER_INUSE = "KEY_FOR_CURRENT_SEL_Miner_v2"

public let TOKEN_ADDRESS = "0x3adc98d5e292355e59ae2ca169d241d889b092e3"
public let MICROPAY_SYSTEM_ADDRESS = "0x660c2B067b0EE6a602305Fe167279385C123e322"
public let BLOCKCHAIN_API_URL = "https://ropsten.infura.io/v3/f3245cef90ed440897e43efc6b3dd0f7"
public let BaseEtherScanUrl = "https://ropsten.etherscan.io"  //"https://ropsten.etherscan.io"//"https://etherscan.io"

public let PoolsInMarketChanged = Notification.Name(rawValue: "PoolsInMarketChanged")
public let WalletBalanceChanged = Notification.Name(rawValue: "WalletBalanceChanged")
public let WalletStatusChanged = Notification.Name(rawValue: "WalletStatusChanged")
public let UserDataSyncSuccess = Notification.Name(rawValue: "UserDataSyncSuccess")
public let VPNStatusChanged = Notification.Name(rawValue: "VPNStatusChanged")
public let NewLibLogs = Notification.Name(rawValue: "NewLibLogs")
public let SelectPoolOrMinerChanged = Notification.Name(rawValue: "SelectPoolOrMinerChanged")
public let DataCounterChanged = Notification.Name(rawValue: "DataCounterChanged")


struct BasicConfig{
        
        var isTurnon: Bool = false
        var isGlobal:Bool = false
        var baseDir:String = ".Pirate"
        var dns:String = "167.179.112.108"
        var poolInUsed:String? = nil
        
        var packetPrice:Double = -1.0
        var refundTime:Double = -1.0
        var PoolGTN:Double = -1.0
        var MinerGTN:Double = -1.0
        
        mutating func loadConf(){
                self.isGlobal = UserDefaults.standard.bool(forKey: KEY_FOR_Pirate_MODEL)
                self.poolInUsed = UserDefaults.standard.string(forKey: KEY_FOR_CURRENT_POOL_INUSE)
                self.dns = UserDefaults.standard.string(forKey: KEY_FOR_DNS_IP) ?? "167.179.112.108"
                do {
                        self.baseDir = try touchDirectory(directory: ".Pirate").path
                }catch let err{
                        print(err)
                        self.baseDir = ".Pirate"
                }
        }
        
        mutating func changeUsedPool(addr:String){
                self.poolInUsed = addr
                UserDefaults.standard.set(addr, forKey: KEY_FOR_CURRENT_POOL_INUSE)
                
                NotificationCenter.default.post(name: SelectPoolOrMinerChanged, object:
                        self, userInfo:nil)
        }
        
        func CurMiner() -> String?{
                guard let pool = self.poolInUsed else{
                        return nil
                }
                return UserDefaults.standard.string(forKey: "\(KEY_FOR_CURRENT_MINER_INUSE)_\(pool)")
                
        }
        
        func SetCurMiner(addr:String, forPool:String) throws{
                
                if self.poolInUsed != forPool{
                        throw ServiceError.PoolChangedErr
                }
                
                UserDefaults.standard.set(addr, forKey: "\(KEY_FOR_CURRENT_MINER_INUSE)_\(forPool)")
                NotificationCenter.default.post(name: SelectPoolOrMinerChanged, object:
                        self, userInfo:nil)
        }
        mutating func SetDNS(dns:String){
                self.dns = dns
                UserDefaults.standard.set(dns, forKey: KEY_FOR_DNS_IP)
        }
        
        func save(){
                UserDefaults.standard.set(isGlobal, forKey: KEY_FOR_Pirate_MODEL)
        }
        
        mutating func loadSetting(){
                guard let ret = systemSettings() else{
                        return
                }
                
                let setting = String(cString:ret)
                guard let dict = try? JSONSerialization.jsonObject(with: setting.data(using: .utf8)!, options: .mutableContainers)
                        as! NSDictionary else { return }
                self.packetPrice = (dict["MBytesPerToken"] as! Double)
                self.refundTime = (dict["RefundDuration"] as! Double)/(24*3600)
                self.PoolGTN = dict["PoolGTN"] as? Double ?? 0.0
                self.MinerGTN = dict["MinerGTN"] as? Double ?? 0.0
        }
}

class Service: NSObject {
        var srvConf = BasicConfig()
        
        var systemCallBack:UserInterfaceAPI = {actTyp, logTyp, v in
//                print("\naction type:\(actTyp)\t log type:\(logTyp)")
//                print("\n",String(cString:v!))
                Service.sharedInstance.serviceQueue.async {
                switch actTyp {
                case Int32(ProtocolLog.rawValue):
                        let strLog = String(cString:v!) 
                        if LogCache.count > 1000{
                                LogCache.remove(at: 0)
                        }
                        LogCache.append(strLog)
                        Swift.print(strLog)
                        NotificationCenter.default.post(name: NewLibLogs, object:
                        self, userInfo:["log":strLog])
                        return
                case Int32(ProtocolNotification.rawValue):
                        switch logTyp{
                        case 1:
                                Service.sharedInstance.srvConf.loadSetting()
                        case 3:
                                NotificationCenter.default.post(name: DataCounterChanged, object:
                                        self, userInfo:["count":String(cString:v!)])
                        case 5:
                                Service.sharedInstance.srvConf.isTurnon = false
                                NotificationCenter.default.post(name: VPNStatusChanged, object:
                                        self, userInfo:["msg":"TX Wire Closed", "errNo":-3])
                                print("TX Wire Closed!")
                        default:
                                print("unkown action type:\(logTyp)")
                        }
                        return
                case Int32(ProtocolExit.rawValue):
                        Service.sharedInstance.srvConf.isTurnon = false
                        NotificationCenter.default.post(name: VPNStatusChanged, object:
                                self, userInfo:["msg":String(cString: v!), "errNo":-1])
                        print("exit by interal error!")
                        return
                        
                case Int32(ServiceClosed.rawValue):
                        Service.sharedInstance.srvConf.isTurnon = false
                        NotificationCenter.default.post(name: VPNStatusChanged, object:
                                self, userInfo:["msg":"Service quit", "errNo":-2])
                        print("service is closed!")
                        return
                default:
                        print("unknown system call back typ:", actTyp)
                        return
                }
                }
        }
        
        var pacServ:PacServer = PacServer()
        public let contractQueue = DispatchQueue(label: "smart contract queue")
        public static var LogCache:[String] = []
        
        private let serviceQueue = DispatchQueue(label: "vpn service queue")
        public static func getDocumentsDirectory() -> URL {
                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                return paths[0]
        }
        
        private override init(){
                super.init()
                srvConf.loadConf()
        }
        
        class var sharedInstance: Service {
                struct Static {
                        static let instance: Service = Service()
                }
                return Static.instance
        }
        
        public func amountService() throws{
                let ret = initConf(srvConf.baseDir.toGoString(),
                         TOKEN_ADDRESS.toGoString(),
                         MICROPAY_SYSTEM_ADDRESS.toGoString(),
                         BLOCKCHAIN_API_URL.toGoString(),
                         srvConf.dns.toGoString(),
                         systemCallBack)
                
                if ret != nil{
                        throw ServiceError.SdkActionErr("init config err: msg:[\(String(cString:ret!))]")
                }
                
                try  ensureLaunchAgentsDirOwner()
                
                if !SysProxyHelper.install(){
                        throw ServiceError.SysPorxyMountErr
                }
                
                try pacServ.startPACServer()
                
                try StartApp()
                
                self.srvConf.loadSetting()
                
                _ = Wallet.CurrentWallet
        }
        
        public func StartApp()throws{
                guard let ret   = startApp() else{
                        return
                }
                
                throw ServiceError.SdkActionErr("Start Protocol err:[\(String(cString:ret))]")
        }
        
        public func StopApp(){
                stopApp()
        }
        
        public func StopServer() throws{
                
                if !SysProxyHelper.RemoveSetting(){
                        throw ServiceError.SysProxyRemoveErr
                }
                
                stopService()
                self.srvConf.isTurnon = false
        }
        
        
        public func StartServer() throws{
                
                guard let miner = self.srvConf.CurMiner() else {
                        throw ServiceError.NoMinerErr
                }
                
                guard let pool = self.srvConf.poolInUsed else {
                        throw ServiceError.NoPaymentChanErr
                }
    
                if !SysProxyHelper.SetupProxy(isGlocal: self.srvConf.isGlobal){
                        throw ServiceError.SysProxySetupErr
                }
                
                let ret = startServing("127.0.0.1:\(ProxyLocalPort)".toGoString(),
                                       pool.toGoString(),
                                       miner.toGoString())
                
                
                guard let errMsg = ret.r1 else{
                        self.srvConf.isTurnon = true
                        NotificationCenter.default.post(name: VPNStatusChanged, object:
                                self, userInfo:["msg":"", "errNo":0])
                        return
                }
                
                self.srvConf.isTurnon = false
                NotificationCenter.default.post(name: VPNStatusChanged, object:
                                self, userInfo:["msg":String(cString: errMsg), "errNo":ret.r0])
        }
        
        
        public func ChangeModel(global:Bool) throws{
                self.srvConf.isGlobal = global
                if !self.srvConf.isTurnon{
                        return
                }
                
                if !SysProxyHelper.SetupProxy(isGlocal: global){
                       throw ServiceError.SysProxySetupErr
                }
        }
        
        public func Exit(){
                self.srvConf.save()
                _ = SysProxyHelper.RemoveSetting()
        }
        
        func loadCallBack(msgTyp:Int)->Void{
        }
}
