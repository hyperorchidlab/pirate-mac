//
//  UserData.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/10.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Foundation
import DecentralizedShadowSocks

class UserData: NSObject {
        
        var InCharge:Double = 0.0
        var MainAddr:String = ""
        var Nonce:Int64 = 0
        var TokenInUsed:NSNumber = 0.0
        var PacketBalance:Double = 0.0
        var RefundTime:String = ""
        var Epoch:Int64 = 0
        var Credit:Double = 0.0
        var MicrNonce:Int64 = 0
        
        
        override init(){
                super.init()
        }
        
        init(dict:NSDictionary, inch:Double){
                super.init()
                self.InCharge = inch
                self.MainAddr = dict["user"] as? String ?? ""
                self.Nonce = dict["nonce"] as? Int64  ?? -1
                self.TokenInUsed = dict["balance"] as? NSNumber ?? 0.00
                self.PacketBalance = dict["reminder"] as? Double ?? 0.0
                let expired = dict["expire"] as? String ?? "-"
                self.RefundTime = expired//ConvertTime(val: expired)                
                self.Epoch = dict["epoch"] as?Int64 ?? 0
                self.Credit = dict["credit"] as?Double ?? 0.0
                self.MicrNonce = dict["microNonce"] as?Int64 ?? 0
        }
        
        static func LoadUserDataUnder(pool:String) -> UserData?{
                let uAddr = Wallet.CurrentWallet.MainAddress
                if uAddr == "" || pool == ""{
                        return nil
                }
                let ret = UserDataOfPool(uAddr.toGoString(), pool.toGoString())
                
                guard let strRet = ret.r0 else {
                        return nil
                }
                
                guard let data = String(cString: strRet).data(using: .utf8) else{ return nil }
            guard let dic = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary else {
                        return nil
                }
                return UserData(dict:dic, inch:Double(ret.r1))
        }
}
