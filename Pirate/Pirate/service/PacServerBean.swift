//
//  PacServerBean.swift
//  pirate
//
//  Created by Pirate on 2019/4/11.
//  Copyright © 2019年 lab All rights reserved.
//

import Foundation
class  PacServer :NSObject{
        var webServer:GCDWebServer? = nil
        var originalData:Data? = nil
        
        override init() {
                super.init()
                do{ try initWebServer() }catch{
                        exit(1)
                }
        }
        
        func initWebServer() throws {
                let bundleURL = Bundle.main.resourceURL!
                let url = bundleURL.appendingPathComponent("gfw_test.js")//gfw.js
                self.originalData = try Data(contentsOf: url)
                        
                webServer = GCDWebServer()
                webServer?.addHandler(forMethod: "GET",
                                      path: "/proxy.pac",
                                      request: GCDWebServerRequest.self,
                                      processBlock: {
                                        (request) -> GCDWebServerResponse? in
                                        return GCDWebServerDataResponse(data: self.originalData!,
                                                                        contentType: "application/x-ns-proxy-autoconfig")
                })
        }
        
        public func startPACServer() throws{
                try webServer?.start(options: ["BindToLocalhost" : true as AnyObject, "Port":PACServerPort as AnyObject])
        }
}
