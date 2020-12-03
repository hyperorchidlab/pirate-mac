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

class ExtendToken: NSObject {
        
        var Balance:NSNumber = 0.0
        var PaymentContract:String = ""
        var TokenI:String = ""
        var Symbol:String = ""
        var Decimal:Int = 0
        
        override init() {
                super.init()
                
                self.PaymentContract = MICROPAY_SYSTEM_ADDRESS
                self.Symbol = "HOP"
                self.TokenI = TOKEN_ADDRESS
                self.Balance = 0
                self.Decimal = 18
        }
}
