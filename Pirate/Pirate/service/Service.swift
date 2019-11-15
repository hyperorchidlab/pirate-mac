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
public let MICROPAY_SYSTEM_ADDRESS = "0x9a04dC6d9DE10F6404CaAfbe3F80e70f2dAec7DB"
public let BLOCKCHAIN_API_URL = "https://ropsten.infura.io/v3/f3245cef90ed440897e43efc6b3dd0f7"
public let BaseEtherScanUrl = "https://ropsten.etherscan.io"  //"https://ropsten.etherscan.io"//"https://etherscan.io"

public let PoolsInMarketChanged = Notification.Name(rawValue: "PoolsInMarketChanged")
public let TransactionStatusChanged = Notification.Name(rawValue: "TransactionStatusChanged")
public let WalletBalanceChanged = Notification.Name(rawValue: "WalletBalanceChanged")
public let WalletStatusChanged = Notification.Name(rawValue: "WalletStatusChanged")
public let UserDataSyncSuccess = Notification.Name(rawValue: "UserDataSyncSuccess")
public let VPNStatusChanged = Notification.Name(rawValue: "VPNStatusChanged")
public let NewLibLogs = Notification.Name(rawValue: "NewLibLogs")
public let SelectPoolOrMinerChanged = Notification.Name(rawValue: "SelectPoolOrMinerChanged")


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
        mutating func parseSysSetting(setting:String){
                guard let dict = try? JSONSerialization.jsonObject(with: setting.data(using: .utf8)!, options: .mutableContainers)
                        as! NSDictionary else { return }
                self.packetPrice = (dict["MBytesPerToken"] as! Double)
                self.refundTime = (dict["RefundDuration"] as! Double)/(24*3600)
                self.PoolGTN = (dict["PoolGTN"] as! Double)
                self.MinerGTN = (dict["MinerGTN"] as! Double)
        }
}


func LogTypeStr(typ:Int) -> String{
        switch typ {
        case 1:
                return "User Data"
        case 2:
                return "Receipt"
        case 3:
                return "Basic Block Chain Data"
        case 4:
                return "Pools Under User"
        case 5:
                return "Pools Sync Thread"
        default:
                return "unkown now"
        }
}

class Service: NSObject {
        var srvConf = BasicConfig()
        var systemCallBack:UserInterfaceAPI = {actTyp, logTyp, v in
                print("---\(actTyp)---\(logTyp)---\(String(cString:v!))---")
                
                switch actTyp {
                case Int32(Log.rawValue):
                        let strLog = "[\(LogTypeStr(typ:Int(logTyp)))]=\(String(cString:v!))"
                        
                        if LogCache.count > 1000{
                                LogCache.remove(at: 0)
                        }
                        LogCache.append(strLog) 
                        NotificationCenter.default.post(name: NewLibLogs, object:
                        self, userInfo:["log":strLog])
                        
                        return
                case Int32(Notification.rawValue):
                        print("noti")
                        return
                case Int32(ExitByErr.rawValue):
                        print("err")
                        return
                default:
                        print("unknown system call back typ:", actTyp)
                        return
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
                
                let ret2  = initDataSrv()
                if ret2.r0 != 0 {
                        throw ServiceError.SdkActionErr("init data cache service err: no:[\(ret2.r0)] msg:[\(String(cString:ret2.r1))]")
                }
  
                guard let ret4 = systemSettings() else{
                        throw ServiceError.SdkActionErr("init config err: can't load contract system settings!")
                }
                
                srvConf.parseSysSetting(setting: String(cString:ret4))
                
                try  ensureLaunchAgentsDirOwner()
                if !SysProxyHelper.install(){
                        throw ServiceError.SysPorxyMountErr
                }
                
                try pacServ.startPACServer()
                
                if Wallet.CurrentWallet.IsEmpty() {
                        return
                }

                let ret3 = initHopSrv()
                if ret3.r0 != 0 {
                        throw ServiceError.SdkActionErr("init hyper orchid protocol err: no:[\(ret3.r0)] msg:[\(String(cString:ret3.r1))]")
                }
        }
        
        public func StopServer() throws{
                
                if !SysProxyHelper.RemoveSetting(){
                        throw ServiceError.SysProxyRemoveErr
                }
                
                stopService()
                self.srvConf.isTurnon = false
        }
        
        
        public func StartServer(password:String) throws{
                
                if Wallet.CurrentWallet.IsEmpty(){
                        throw ServiceError.EmptyWalletErr
                }
                
                guard let pool = self.srvConf.poolInUsed else {
                        throw ServiceError.NoPaymentChanErr
                }
    
                if !SysProxyHelper.SetupProxy(isGlocal: self.srvConf.isGlobal){
                        throw ServiceError.SysProxySetupErr
                }
                
                serviceQueue.async {
                        let ret = startServing("127.0.0.1:\(ProxyLocalPort)".toGoString(),
                                               password.toGoString(),
                                               pool.toGoString())
                       
                        
                        self.srvConf.isTurnon = false
                        NotificationCenter.default.post(name: VPNStatusChanged, object:
                                self, userInfo:["msg":String(cString: ret.r1), "errNo":ret.r0])
                }
                
                NotificationCenter.default.post(name: VPNStatusChanged, object:
                        self, userInfo:nil)
                self.srvConf.isTurnon = true
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
