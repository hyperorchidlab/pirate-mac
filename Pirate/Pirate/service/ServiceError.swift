//
//  ServiceError.swift
//  Pirate
//
//  Created by Pirate on 2019/4/11.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Foundation

enum ServiceError:Error {
        case SysPorxyMountErr
        case SysProxyRemoveErr
        case SysProxySetupErr
        case InvalidPathErr
        case ParseJsonErr
        case InitHopErr(String)
        
        case NewWalletErr(String)
        case EmptyWalletErr
        case ExportWalletErr(String)
        case ImportWalletErr(String)
        case OpenWalletErr
        
        case NoPaymentChanErr
        case SdkActionErr(String)
}

extension ServiceError: LocalizedError {
        
        public var errorDescription: String? {
                switch self {
                case .SysPorxyMountErr:
                        return NSLocalizedString("Mount system proxy model error".localized, comment: "System Error")
                case .SysProxyRemoveErr:
                        return NSLocalizedString("Remove the system proxy setting error".localized, comment: "System Error")
                case .SysProxySetupErr:
                        return NSLocalizedString("Setup system proxy error".localized, comment: "System Error")
                case .ParseJsonErr:
                        return NSLocalizedString("Pasrese json data failed".localized, comment: "System Error")
                case .InitHopErr(let str):
                        return str
                case .InvalidPathErr:
                        return NSLocalizedString("File path invalid".localized, comment: "System Error")
                case .NewWalletErr(let str):
                        return str
                case .EmptyWalletErr:
                        return NSLocalizedString("Empty walllet error".localized, comment: "Wallet Error")
                case .ExportWalletErr(let str):
                        return NSLocalizedString(str.localized, comment: "Wallet Error")
                case .ImportWalletErr(let str):
                        return NSLocalizedString(str.localized, comment: "Wallet Error")
                case .OpenWalletErr:
                        return NSLocalizedString("Open walllet error".localized, comment: "Wallet Error")
                case .NoPaymentChanErr:
                        return NSLocalizedString("No selected miner pool error".localized, comment: "Channel Error")
                case .SdkActionErr(let str):
                        return str
                }
        }
}
