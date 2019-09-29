//
//  TransferViewController.swift
//  Pirate
//
//  Created by Pirate on 2019/9/4.
//  Copyright © 2019年 Pirate All rights reserved.
//

import Cocoa

class TransferViewController: NSViewController {
        
        var tokenTypeArr:[String] = ["ETH", "Token"]
        var tokenType:Int = -1
        
        @IBOutlet weak var TokenBalanceField: NSTextField!
        @IBOutlet weak var WalletPasswordField: NSSecureTextField!
        @IBOutlet weak var TargetAddressField: NSTextField!
        @IBOutlet weak var TokenTypeBox: NSComboBox!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.TokenTypeBox.selectItem(at: 0)
        }
}

extension TransferViewController:NSComboBoxDelegate{
        func comboBoxSelectionDidChange(_ notification: Notification){
                let box = notification.object as! NSComboBox
                tokenType = box.indexOfSelectedItem
                if tokenType == 0{
                        TokenBalanceField.placeholderString = String(format: "Current Balance(%.4f)", Wallet.sharedInstance.EthBalance.CoinValue())
                }else{
                        TokenBalanceField.placeholderString = String(format: "Current Balance(%.4f)", Wallet.sharedInstance.TokenBalance.CoinValue())
                }
                
        }
        
        func comboBoxSelectionIsChanging(_ notification: Notification){
                
        }
}

extension TransferViewController:NSComboBoxDataSource{
        func numberOfItems(in comboBox: NSComboBox) -> Int{
                return 2
        }
        
        func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any?{
                return tokenTypeArr[index]
        }
}

func ShowTransferDialog() -> (String, String, Double, Int){
        
        let alert = NSAlert()
        alert.messageText = "Transfer Token".localized
        alert.informativeText = "Please select token type you want to transfer".localized
        alert.alertStyle = .informational
        let transView = TransferViewController()
        alert.accessoryView = transView.view
        alert.addButton(withTitle: "OK".localized)
        alert.addButton(withTitle: "Cancel".localized)
        let butSel = alert.runModal()
        if butSel == .alertFirstButtonReturn{
                return (transView.WalletPasswordField.stringValue,
                        transView.TargetAddressField.stringValue,
                        transView.TokenBalanceField.doubleValue,
                        transView.tokenType)
        }
        return ("", "", 0.0, -1)
}
