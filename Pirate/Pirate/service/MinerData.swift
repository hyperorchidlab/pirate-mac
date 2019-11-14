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

let KEY_FOR_CACHED_MINER_OF = "KEY_FOR_CACHED_MINER_OF_"

class MinerTestData:NSObject{
        
        var IPAddr:String = ""
        var Ping:Double = 0.0
        
        override init(){
                super.init()
        }
        
        init(dict:NSDictionary){
        }
}

class MinerData: NSObject, NSCoding {
        
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
        
        func encode(with aCoder: NSCoder) {
                aCoder.encode(SubAddr, forKey: "SubAddr")
                aCoder.encode(Zone, forKey: "Zone")
                aCoder.encode(GTN, forKey: "GTN")
        }
        
        required init?(coder aDecoder: NSCoder) {
                SubAddr = aDecoder.decodeObject(forKey: "SubAddr") as! String
                Zone = aDecoder.decodeObject(forKey: "Zone") as! String
                GTN = aDecoder.decodeDouble(forKey: "GTN")
        }
        
        
        public static func LoadMiners(PoolAddr:String)-> [MinerData]{
                let key = "\(KEY_FOR_CACHED_MINER_OF)_\(PoolAddr)"
                guard let md = UserDefaults.standard.data(forKey: key) else{
                        return SyncMiners(PoolAddr: PoolAddr)
                }
                
                let miners = NSKeyedUnarchiver.unarchiveObject(with: md) as! [MinerData]
                return miners
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
                
                let key = "\(KEY_FOR_CACHED_MINER_OF)_\(PoolAddr)"
                let md = NSKeyedArchiver.archivedData(withRootObject: miners)
                UserDefaults.standard.set(md, forKey: key)
                return miners
        }
}
