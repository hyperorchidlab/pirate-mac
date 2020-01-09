//
//  ExtendTokens.swift
//  Pirate
//
//  Created by hyperorchid on 2020/1/4.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks

let KEY_FOR_CACHED_TOKENS_OF = "KEY_FOR_CACHED_TOKENS_"

class ExtendToken: NSObject, NSCoding {
        
        var Balance:NSNumber = 0.0
        
        var PaymentContract:String = ""// common.Address
        var TokenI:String = ""//          common.Address
        var Symbol:String = ""//          [8]byte
        var Decimal:Int = 0//         *big.Int
        var MBytesPerToken:Int = 0//  *big.Int
        
        static public var AllExTokens:[ExtendToken] = []
        
        override init() {
                super.init()
        }
        
        init(dict:NSDictionary) {
                super.init()
                self.PaymentContract = dict["PaymentContract"] as? String ?? ""
                self.TokenI = dict["TokenI"] as? String ?? ""
                self.Symbol = dict["Symbol"] as? String ?? ""
                
                self.MBytesPerToken = dict["MBytesPerToken"] as? Int ?? 0
                self.Decimal = dict["Decimal"] as? Int ?? 0
        }
        
        func encode(with aCoder: NSCoder) {
               aCoder.encode(PaymentContract, forKey: "PaymentContract")
               aCoder.encode(TokenI, forKey: "TokenI")
               aCoder.encode(Symbol, forKey: "Symbol")
               aCoder.encode(MBytesPerToken, forKey: "MBytesPerToken")
               aCoder.encode(Decimal, forKey: "Decimal")
        }

        required init?(coder aDecoder: NSCoder) {
                PaymentContract = aDecoder.decodeObject(forKey: "PaymentContract") as! String
                TokenI = aDecoder.decodeObject(forKey: "TokenI") as! String
                Symbol = aDecoder.decodeObject(forKey: "Symbol") as! String
                
                MBytesPerToken = aDecoder.decodeInteger(forKey:"MBytesPerToken")
                Decimal = aDecoder.decodeInteger(forKey: "Decimal")
        }
        
        public static func loadTokens(){
               guard let md = UserDefaults.standard.data(forKey: KEY_FOR_CACHED_TOKENS_OF) else{
                        AllExTokens = syncTokens()
                        return
               }
               AllExTokens = NSKeyedUnarchiver.unarchiveObject(with: md) as! [ExtendToken]
        }
        
        public static func syncTokens()-> [ExtendToken]{
                
                guard let ret = ExtendTokens() else{
                        return []
                }
                
                guard let data = String(cString: ret).data(using: .utf8) else{
                        return []
                }
                
                guard let tokenArray = try? JSONSerialization.jsonObject(with: data,
                        options: .mutableContainers) as? NSArray else {
                        return []
                }
                               
                var tokens:[ExtendToken] = []
                for (_, value) in tokenArray.enumerated() {
                        guard let dict = value as? NSDictionary else{
                                continue
                        }
                        let miner = ExtendToken.init(dict:dict)
                        tokens.append(miner)
                }
                
                let md = NSKeyedArchiver.archivedData(withRootObject: tokens)
                UserDefaults.standard.set(md, forKey: KEY_FOR_CACHED_TOKENS_OF)
                
                return tokens
        }
}
