//
//  SysProxyConfig.h
//  sysproxyconfig
//
//  Created by hyperorchid on 2019/3/6.
//  Copyright © 2019 hyperorchidlab All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef SysProxyConfig_h
#define SysProxyConfig_h
NSString* const kSysProxyConfigVersion = @"0.1.3";
int const PACServerPort = 41087;
int const ProxyLocalPort = 41080;
NSString* const kDefaultPacURL = @"http://127.0.0.1:\(PACServerPort)/proxy.pac";
#endif /* SysProxyConfig_h */
