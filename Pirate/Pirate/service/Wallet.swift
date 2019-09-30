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
        let BALANCE_TOKEN_KEY = "BALANCE_TOKEN_KEY"
        let BALANCE_ETH_KEY = "BALANCE_ETH_KEY"
        
        var defaults = UserDefaults.standard
        var MainAddress:String = ""
        var SubAddress:String = ""
        
        var EthBalance:NSNumber = 0
        var TokenBalance:NSNumber = 0
        var HasApproved:NSNumber = 0
        
        override init() {
                super.init()
                loadWalletInfo()
        }
        
        
        func loadWalletInfo(){
                let ret = WalletAddress()
                
                guard let mainData = ret.r0 else {
                        return
                }
                self.MainAddress = String(cString: mainData)
                self.SubAddress = String(cString: ret.r1)
                syncWalletData()
        }
        
        class var sharedInstance: Wallet {
                struct Static {
                        static let instance: Wallet = Wallet()
                }
                return Static.instance
        }
        
        public func IsEmpty() -> Bool{
                return self.MainAddress == ""
        }
        
        public func CreateNewWallet(passPhrase:String) -> Bool{
                do{
                        let ret = NewWallet(passPhrase.toGoString())
                        if ret.r0 == 0{
                                let err = String(cString:ret.r1)
                                throw ServiceError.NewWalletErr(err)
                        }
                        loadWalletInfo()
                }catch let err{
                        dialogOK(question: "Error", text: err.localizedDescription)
                        return false
                }
                
                dialogOK(question: "Success", text: "Create new wallet success!")
                return true
        }
        
        func syncWalletData() {
                if self.MainAddress == ""{
                        return
                }
                
                guard let ret = SyncWalletBalance(self.MainAddress.toGoString()) else{
                        return
                }
                
                guard let data = String(cString:ret).data(using: .utf8) else{
                        return
                }
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]else{
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
        
        func ImportWallet(path: String, password:String) throws{
                guard let err = ImportWalletFrom(path.toGoString(), password.toGoString())  else {
                        loadWalletInfo()
                        return
                }
                
                let str = String(cString:err)
                throw ServiceError.ImportWalletErr(str)
        }
        func EthTransfer(password:String, target:String, no:Double){
                Service.sharedInstance.contractQueue.async {
                        let ret = TransferEth(password.toGoString(), target.toGoString(), no)
                        ProcessTransRet(tx: String(cString: ret.r0),
                                             err: String(cString: ret.r1),
                                             noti: TokenTransferResultNoti)
                }
        }
        
        func LinTokenTransfer(password:String, target:String, no:Double){
                Service.sharedInstance.contractQueue.async {
                        let ret = TransferLinToken(password.toGoString(), target.toGoString(), no)
                        ProcessTransRet(tx: String(cString: ret.r0),
                                             err: String(cString: ret.r1),
                                             noti: TokenTransferResultNoti)
                }
        }
}
