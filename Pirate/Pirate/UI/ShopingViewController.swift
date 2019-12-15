//
//  ShopingViewController.swift
//  Pirate
//
//  Created by Pirate on 2019/9/22.
//  Copyright © 2019 Pirate. All rights reserved.
//

import Cocoa
import DecentralizedShadowSocks

class ShopingViewController: NSViewController {
        
        enum TransactionStatus {
                case InitApprove
                case ApproveStart
                case ProcessApprove
                case ApproveFailed
                case ApproveSuccess
                case BuyStart
                case ProcessBuy
                case BuyFailed
                case BuySuccess
        }
        
        @IBOutlet weak var loggingView: NSScrollView!
        @IBOutlet weak var approveTx: NSTextField!
        @IBOutlet weak var RechargeTx: NSTextField!
        @IBOutlet weak var ApproveStatus: NSTextField!
        @IBOutlet weak var RechargeStatus: NSTextField!
        
        var buyForAddr:String = ""
        var buyFromAddr:String = ""
        var auth:String = ""
        var tokenNo:Double = 0.0
        var status:TransactionStatus = .InitApprove
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        func setStatusInof(status:TransactionStatus, desc:String){
                self.status = status
                DispatchQueue.main.async{
                        switch status{
                        case .InitApprove:
                                self.ApproveStatus.stringValue = "Init"
                                self.loggingView.documentView?.insertText("\nstart to approve action on blockchain......")
                                break
                        case .ProcessApprove:
                                self.loggingView.documentView?.insertText("\n\(desc)")
                                break
                        case .ApproveFailed:
                                self.ApproveStatus.stringValue = "Failed"
                                self.loggingView.documentView?.insertText("\napprove action failed[\(desc)]")
                                break
                        case .ApproveStart:
                                self.ApproveStatus.stringValue = "Packaging"
                                self.approveTx.stringValue = desc
                                self.loggingView.documentView?.insertText("\napprove action packaging at tx:[\(desc)]")
                                break
                        case .ApproveSuccess:
                                self.ApproveStatus.stringValue = "Success"
                                self.RechargeStatus.stringValue = "Init"
                                self.loggingView.documentView?.insertText("\napprove success......\nstart to buy packet......")
                                break
                        case .BuyStart:
                                self.RechargeStatus.stringValue = "Packaging"
                                self.RechargeTx.stringValue = desc
                                self.loggingView.documentView?.insertText("\nbuying request success at[\(desc)]......")
                                break
                        case .BuyFailed:
                                self.RechargeStatus.stringValue = "Failed"
                                self.loggingView.documentView?.insertText("\nfailed to buy packet for:[\(desc)]")
                                break
                        case .ProcessBuy:
                                self.loggingView.documentView?.insertText("\n\(desc)")
                                break
                        case .BuySuccess:
                                self.RechargeStatus.stringValue = "Success"
                                self.loggingView.documentView?.insertText("\nBuy packet action save on blockchain success")
                                break
                        }
                }
        }
        
        func waitTxToSuccess(tx:String){
                var packaging = true
                var times = 0
                while packaging{
                        sleep(2)
                        times += 1
                        if 0 == TxProcessStatus(tx.toGoString()){
                                self.setStatusInof(status: .ProcessApprove, desc: "processing transaction[\(tx)(\(times * 2)s)]......")
                                continue
                        }
                        packaging = false
                }
        }
        func startBlockChainAction(buyFrom pool:String, For user:String, auth:String, tokenNo:Double) {
                
                if  Wallet.CurrentWallet.HasApproved.doubleValue < tokenNo{
                        self.setStatusInof(status: .InitApprove, desc: "")
                        let appRet = AuthorizeTokenSpend(auth.toGoString(), tokenNo)
                        guard let txData = appRet.r0 else{
                                guard let errData = appRet.r1 else{
                                        return
                                }
                                self.setStatusInof(status: .ApproveFailed, desc: String(cString: errData))
                                return
                        }
                        let tx = String(cString:txData)
                        self.setStatusInof(status:.ApproveStart, desc:tx)
                        waitTxToSuccess(tx:tx)
                        self.setStatusInof(status: .ApproveSuccess, desc: "")
                }
                
                let ret = BuyPacket(user.toGoString(), pool.toGoString(), auth.toGoString(), tokenNo)
                guard let txData = ret.r0 else{
                        guard let errData = ret.r1 else{
                                return
                        }
                        self.setStatusInof(status: .BuyFailed, desc: String(cString: errData))
                        return
                }
                
                let tx = String(cString: txData)
                self.setStatusInof(status: .BuyStart, desc: tx)
                
                waitTxToSuccess(tx:tx)
                
                self.setStatusInof(status: .BuySuccess, desc: "")
        }
}

func ShowShopingDialog(buyFrom poolAddr:String, For userAddr:String, auth:String, tokenNo:Double) ->Void{
        
        let alert = NSAlert()
        alert.messageText = "Blockchain process informations".localized
        alert.alertStyle = .informational
        let shopVC = ShopingViewController()
        Service.sharedInstance.contractQueue.async {
                shopVC.startBlockChainAction(buyFrom: poolAddr, For: userAddr, auth: auth, tokenNo: tokenNo)
        }
        alert.accessoryView = shopVC.view
        alert.addButton(withTitle: "Cancel".localized)
        alert.runModal()
}
