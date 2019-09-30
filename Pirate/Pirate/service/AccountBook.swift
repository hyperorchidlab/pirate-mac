//
//  AccountBook.swift
//  Pirate
//
//  Created by hyperorchid on 2019/9/30.
//  Copyright © 2019年 hyperorchid. All rights reserved.
//

import Cocoa

class AccountBook: NSObject {
        var payer:String = ""
        var payee:String = ""
        
        var Counter:Int = 0
        var InRecharge:Int = 0
        var Nonce:Int = 0
        var UnClaimed:Int64 = 0
        
        override init() {
                super.init()
        }
}
