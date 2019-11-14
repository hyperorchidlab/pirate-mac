//
//  MinerData.swift
//  Pirate
//
//  Created by hyperorchid on 2019/11/14.
//  Copyright © 2019 hyperorchid. All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks
let MAX_MINER_NO = 16

let KEY_FOR_CACHED_MINER_OF = "KEY_FOR_CACHED_MINER_OF_%s"

class MinerTestData:NSObject{
        
        var IPAddr:String = ""
        var Ping:Double = 0.0
        
        override init(){
                super.init()
        }
        
        init(dict:NSDictionary){
                
        }
}

class MinerData: NSObject { 
        var SubAddr:String = ""
        var Zone:String = ""
        var GTN:Double = 0.0
        
        override init(){
                super.init()
        }
        
        init(dict:NSDictionary){
                super.init()
                
                self.SubAddr = dict["SubAddr"] as? String ?? ""
                self.Zone = dict["Zone"] as? String ?? ""
                self.GTN = dict["GTN"] as? Double ?? 0.0
        }
        
        public static func LoadMiners(PoolAddr:String)-> [MinerData]{
                let key = String(format: KEY_FOR_CACHED_MINER_OF, PoolAddr)
                guard let miners = UserDefaults.standard.array(forKey: key) else{
                        return SyncMiners(PoolAddr: PoolAddr)
                }
                return miners as! [MinerData]
        }
        
        public static func SyncMiners(PoolAddr:String)-> [MinerData]{
                guard let ret = RandomMiner(PoolAddr.toGoString(), GoInt(MAX_MINER_NO)) else{
                        return []
                }
                
                guard let data = String(cString: ret).data(using: .utf8) else{
                        return []
                }
                guard let minerData = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                        as! NSArray else {
                                return[]
                }
                
                var miners:[MinerData] = []
                for (_, value) in minerData.enumerated() {
                        guard let dict = value as? NSDictionary else{
                                continue
                        }
                        let miner = MinerData.init(dict:dict)
                        miners.append(miner)
                }
                
                let key = String(format: KEY_FOR_CACHED_MINER_OF, PoolAddr)
                UserDefaults.standard.set(miners, forKey: key)
                return miners
        }
}
