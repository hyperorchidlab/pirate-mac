//
//  Service.swift
//  Pirate
//
//  Created by Pirateon 2019/4/11.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Foundation
import DecentralizedShadowSocks

let KEY_FOR_SWITCH_STATE          = "KEY_FOR_SWITCH_STATE"
let KEY_FOR_Pirate_MODEL        = "KEY_FOR_Pirate_MODEL"
let KEY_FOR_CURRENT_POOL_INUSE    = "KEY_FOR_CURRENT_SEL_POOL_v2"

public let TOKEN_ADDRESS = "0x7001563e8f2ec996361b72f746468724e1f1276c"
public let MICROPAY_SYSTEM_ADDRESS = "0x572b89B86D37A990E828F45c85e31b8e8Ae222eF"
public let BLOCKCHAIN_API_URL = "https://ropsten.infura.io/v3/f3245cef90ed440897e43efc6b3dd0f7"
public let BaseEtherScanUrl = "https://ropsten.etherscan.io"  //"https://ropsten.etherscan.io"//"https://etherscan.io"

public let PoolsInMarketChanged = Notification.Name(rawValue: "PoolsInMarketChanged")
public let WalletDataChangedNoti = Notification.Name(rawValue: "WallentDataChangedNotification")
public let BuyPacketResultNoti = Notification.Name(rawValue: "WalletBuyPacketResultNoti")
public let TokenTransferResultNoti = Notification.Name(rawValue: "WalletTokenTransferResultNoti")
public let PayChannelChangedNoti = Notification.Name(rawValue: "PayChannelChangedNoti")

struct BasicConfig{
        
        var isTurnon: Bool = false
        var isGlobal:Bool = false
        var packetPrice:Int64 = -1
        var baseDir:String = ".Pirate"
        var poolInUsed:String? = nil
        
        mutating func loadConf(){
                self.isGlobal = UserDefaults.standard.bool(forKey: KEY_FOR_Pirate_MODEL)
                self.poolInUsed = UserDefaults.standard.string(forKey: KEY_FOR_CURRENT_POOL_INUSE)
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
        }
        
        func save(){
//                UserDefaults.standard.set(isTurnon, forKey: KEY_FOR_SWITCH_STATE)
                UserDefaults.standard.set(isGlobal, forKey: KEY_FOR_Pirate_MODEL)
        }
}

class Service: NSObject {
        
        var srvConf = BasicConfig()
        var systemCallBack:SystemActionCallBack = {typ, v in
                switch typ {
                case Int32(BalanceSynced.rawValue):
                        NotificationCenter.default.post(name: WalletDataChangedNoti, object: nil)
                        print("BalanceSynced")
                        return
                default:
                        print("unknown system call back typ:", typ)
                        return
                }
        }
        
        var blockchainSynced:BlockChainDataSyncNotifier = {typ, v in
                
                switch typ {
                case Int32(SubPoolSynced.rawValue):
                        MPCManager.loadMyChannels()
                        NotificationCenter.default.post(name: PayChannelChangedNoti, object: nil)
                        print("SubPoolSynced")
                        return
                case Int32(MarketPoolSynced.rawValue):
                        MinerPool.PoolInfoInMarket()
                        NotificationCenter.default.post(name: PoolsInMarketChanged, object: nil)
                        print("MarketPoolSynced")
                        return
                default:
                        print("unknown data service call back typ:", typ)
                        return
                }
        }
        
        var pacServ:PacServer = PacServer()
        
        public static let VPNStatusChanged = Notification.Name(rawValue: "VPNStatusChanged")
        
        public let contractQueue = DispatchQueue(label: "smart contract queue")
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
                srvConf.loadConf()
                let ret = initApp(TOKEN_ADDRESS.toGoString(),
                                  MICROPAY_SYSTEM_ADDRESS.toGoString(),
                                  BLOCKCHAIN_API_URL.toGoString(),
                                  srvConf.baseDir.toGoString(),
                                  systemCallBack,
                                  blockchainSynced)
                if ret.r0 != 0 {
                        throw ServiceError.SdkActionErr("init app err: no:[\(ret.r0)] msg:[\(String(cString:ret.r1))]")
                }
                
                self.srvConf.packetPrice = SysPacketPrice()
                self.contractQueue.async {
                        asyncAppDataFromBlockChain()
                }
                
                try  ensureLaunchAgentsDirOwner()
                if !SysProxyHelper.install(){
                        throw ServiceError.SysPorxyMountErr
                }
                
                try pacServ.startPACServer()
        }
        
        public func StopServer() throws{
                
                if !SysProxyHelper.RemoveSetting(){
                        throw ServiceError.SysProxyRemoveErr
                }
                
                stopService()
                self.srvConf.isTurnon = false
        }
        
        
        public func StartServer(password:String) throws{
                
                if Wallet.sharedInstance.IsEmpty(){
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
                        NotificationCenter.default.post(name: Service.VPNStatusChanged, object:
                                self, userInfo:["msg":String(cString: ret.r1), "errNo":ret.r0])
                }
                
                NotificationCenter.default.post(name: Service.VPNStatusChanged, object:
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
