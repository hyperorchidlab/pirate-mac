//
//  PacketPool.swift
//  pirate
//
//  Created by Pirate on 2019/8/29.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Foundation
import DecentralizedShadowSocks

class MinerPool: NSObject {
        
        static var cachedPools:[String:MinerPool] = [:]
        static func objAt(idx:Int) -> MinerPool{
                return Array(cachedPools.values)[idx]
        }
        var MainAddr:String = ""
        var Payer:String = ""
        var GuaranteedNo:Double = 0.0
        var ShortName:String = ""
        var Email:String = ""
        var Url:String = ""
        
        override init(){
                super.init()
        }
        
        init(dict:NSDictionary){
                super.init()
                self.MainAddr = dict["MainAddr"] as? String ?? ""
                self.Payer = dict["PayerAddr"] as? String ?? ""
                self.GuaranteedNo = dict["GTN"] as? Double ?? 0.00
                self.ShortName = dict["Name"] as? String ?? ""
                self.Email = dict["Email"] as? String ?? ""
                self.Url = dict["Url"] as? String ?? ""
        } 
        
        static private func parsePoolsData(data:Data){
                guard let poolMap = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! NSDictionary else {
                        return
                }
                
                cachedPools.removeAll()
                
                for (_, value) in poolMap.allValues.enumerated() {
                        
                        guard let dict = value as? NSDictionary else{
                                continue
                        }
                        
                        let channel = MinerPool.init(dict:dict)
                        cachedPools[channel.MainAddr] = channel
                }
        }
        
        static func PoolInfoInMarket(){
                
                guard let ret = PoolInfosInMarket() else {
                        return
                }
                
                guard let data = String(cString: ret).data(using: .utf8) else{
                        return
                }
                self.parsePoolsData(data: data)
        }
}
