//
//  UserData.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/10.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Cocoa

class UserData: NSObject {
        
        var MainAddr:String = ""
        var Nonce:Int64 = 0
        var TokenInUsed:Double = 0.0
        var PacketBalance:Double = 0.0
        var RefundTime:String = ""
        var Epoch:Int64 = 0
        var LastClaimedAmount:Double = 0.0
        var LastClaimedNonce:Int64 = 0
        
        override init(){
                super.init()
        }
        
        init(dict:NSDictionary){
                super.init()
                self.MainAddr = dict["MainAddr"] as? String ?? ""
                self.Nonce = dict["nonce"] as? Int64  ?? -1
                self.TokenInUsed = dict["tokenBalance"] as? Double ?? 0.00
                self.PacketBalance = dict["PacketBalance"] as? Double ?? 0.0
                let expired = dict["expiration"] as? Double ?? 0
                self.RefundTime = ConvertTime(val: expired)                
                self.Epoch = dict["epoch"] as?Int64 ?? 0
                self.LastClaimedAmount = dict["claimedAmount"] as?Double ?? 0.0
                self.LastClaimedNonce = dict["claimedMicNonce"] as?Int64 ?? 0
        }
        
}
