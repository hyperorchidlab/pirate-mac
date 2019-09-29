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
        var ciphereTxt:Data?
        var Counter:Int = 0
        var InRecharge: Int = 0
        var Nonce   :   Int = 0
        var UnClaimed:  Int64  = 0
        
        override init() {
                super.init()
                loadWalletData()
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
                        loadWalletData()
                }catch let err{
                        dialogOK(question: "Error", text: err.localizedDescription)
                        return false
                }
                
                dialogOK(question: "Success", text: "Create new wallet success!")
                return true
        }
        
        func syncWalletData() {
                SyncWalletInfo()
        }
        
        func loadWalletData() {
                guard let ret = LoadWalletInfo() else{
                        return
                }
                guard let data = String(cString:ret).data(using: .utf8) else{
                        return
                }
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]else{
                        return
                }
                
                self.MainAddress = json["mainAddress"] as? String ?? ""
                self.SubAddress = json["subAddress"] as? String ?? ""
                let eth = json["eth"] as? NSNumber ?? 0
                let lin = json["token"] as? NSNumber ?? 0
                let app = json["approved"] as? NSNumber ?? 0
                print("\n\n\teth:\(eth)\tlin:\(lin)\tapp:\(app)\n\n")
                
                
                self.EthBalance = json["eth"] as? NSNumber ?? 0
                self.TokenBalance = json["token"] as? NSNumber ?? 0
                self.HasApproved = json["approved"] as? NSNumber ?? 0
                self.ciphereTxt = json["cipher"] as? Data
                self.Counter =  json["counter"] as? Int ?? 0
                self.InRecharge = json["charging"] as? Int ?? 0
                self.Nonce = json["nonce"] as? Int ?? 0
                self.UnClaimed  = json["unclaimed"] as? Int64 ?? 0
        }
        
        func ExportWallet(dst:URL?) throws{
                
                guard let data = self.ciphereTxt  else {
                        throw ServiceError.InvalidWalletErr
                }
                try data.write(to: dst!, options: .atomicWrite)
        }
        
        func ImportWallet(json: String, password:String) throws{
                guard WalletVerify(json.toGoString(), password.toGoString()) != 0 else {
                        throw ServiceError.InvalidWalletErr
                }
                loadWalletData()
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
