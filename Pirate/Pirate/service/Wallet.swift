//
//  AccountBean.swift
//  Pirate
//
//  Created by Pirate on 2019/4/11.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Foundation
import DecentralizedShadowSocks

class Wallet:NSObject{
        
        public static var CurrentWallet:Wallet = Wallet()
        var Status:Bool = false
        var MainAddress:String = ""
        var SubAddress:String = ""
        var EthBalance:NSNumber = 0
        var TokenBalance:NSNumber = 0
        var HasApproved:NSNumber = 0
        
        static public var PoolsOfUser:[MinerPool] = []
        
        override init() {
                super.init()
                load()
        }
        
        func load(){
                let ret = WalletInfo()
                guard let mainData = ret.r0 else {
                        self.MainAddress = ""
                        return
                }
                self.MainAddress = String(cString: mainData)
                self.SubAddress = String(cString: ret.r1)
                self.syncWalletData()
                self.allMyPools()
                self.Status = ret.r2 == 1
                
                NotificationCenter.default.post(name: UserDataSyncSuccess, object: self, userInfo:nil)
        }
        
        public func IsEmpty() -> Bool{
                return self.MainAddress == ""
        }
        
        private func resetWallet(replaced:Bool) throws{
                if replaced{
                        self.MainAddress = ""
                        self.SubAddress = ""
                        self.EthBalance = 0
                        self.TokenBalance = 0
                }
                
                stopApp()
                Thread.sleep(forTimeInterval: 3)
                try Service.sharedInstance.StartApp()
                load()
                NotificationCenter.default.post(name: WalletBalanceChanged, object:self, userInfo:nil)
        }
        
        public func CreateNewWallet(passPhrase:String, replaceOld:Bool) -> Bool{
                do{
                        let ret = NewWallet(passPhrase.toGoString())
                        if ret.r0 == 0{
                                let err = String(cString:ret.r1)
                                throw ServiceError.NewWalletErr(err)
                        }
                        
                        try resetWallet(replaced: replaceOld)
                        
                }catch let err{
                        dialogOK(question: "Error", text: err.localizedDescription)
                        return false
                }
                
                dialogOK(question: "Success", text: "Create new wallet success!")
                return true
        }
        
        func syncWalletData() {
                
                guard let ret = SyncWalletBalance(self.MainAddress.toGoString()) else{
                        return
                }
                
                guard let data = String(cString:ret).data(using: .utf8) else{
                        return
                }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any]else{
                        return
                }
                self.EthBalance = json["eth"] as? NSNumber ?? 0
                self.TokenBalance = json["token"] as? NSNumber ?? 0
                self.HasApproved = json["approved"] as? NSNumber ?? 0
        }
        
   
        func ExportWallet(dst:URL?) throws{
                
                guard let err = ExportWalletTo(dst!.path.toGoString()) else{
                        return
                }
                let str = String(cString:err)
                throw ServiceError.ExportWalletErr(str)
        }
        
        func ImportWallet(path: String, password:String, replaceOld:Bool) throws{
                guard let err = ImportWalletFrom(path.toGoString(), password.toGoString())  else {
                        try resetWallet(replaced: replaceOld)
                        return
                }
                
                let str = String(cString:err)
                throw ServiceError.ImportWalletErr(str)
        }
        
        func allMyPools(){
                Wallet.PoolsOfUser.removeAll()
                guard let ret = PoolDataOfUser(self.MainAddress.toGoString()) else {
                        return
                }
                guard let data = String(cString: ret).data(using: .utf8) else{
                        return
                }
                
            guard let poolMap = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary else {
                        return
                }
                for (_, value) in poolMap.allValues.enumerated() {
                        
                        guard let dict = value as? NSDictionary else{
                                continue
                        }
                        
                        let pool = MinerPool.init(dict:dict)
                       Wallet.PoolsOfUser.append(pool)
                }
        }
        
        func CloseWallet() {
                closeWallet()
                self.Status = false
        }
        
        func OpenWallet(auth:String) throws{
                guard let ret = openWallet(auth.toGoString()) else{
                        self.Status = true
                        return
                }
                throw ServiceError.OpenWalletErr(String(cString: ret))
        }
}
