//
//  UserData.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/10.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Foundation
import DecentralizedShadowSocks
import SwiftyJSON

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
        
        init(json:JSON){
                super.init()
                self.InCharge = 0.0
                self.MainAddr = json["user"].string ?? ""
                self.Nonce = json["nonce"].int64  ?? -1
                self.TokenInUsed = json["balance"].number ?? 0.00
                self.PacketBalance = json["reminder"].double ?? 0.0
                let expired = json["expire"].string ?? "-"
                self.RefundTime = expired
                self.Epoch = json["epoch"].int64 ?? 0
                self.Credit = json["credit"].double ?? 0.0
                self.MicrNonce = json["microNonce"].int64 ?? 0
        }
        
        static func LoadUserDataUnder(pool:String) -> UserData?{
                let uAddr = Wallet.CurrentWallet.MainAddress
                if uAddr == "" || pool == ""{
                        return nil
                }
                guard let ret = UserDataOfPool(uAddr.toGoString(), pool.toGoString()) else {
                        return nil
                }
                return UserData(json:JSON(ret))
        }
}
