//
//  AppDelegate.swift
//  Pirate
//
//  Created by Pirate on 2019/9/29.
//  Copyright © 2019年 Pirate. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

        @IBOutlet weak var window: NSWindow!
        func applicationDidFinishLaunching(_ aNotification: Notification) {
               
                signal(SIGPIPE, SIG_IGN);

                do {
                        try Service.sharedInstance.amountService()
                }catch{
                        print(error)
                        exit(-1)
                }
        }

        func applicationWillTerminate(_ aNotification: Notification) {
                Service.sharedInstance.Exit()
        }
}

