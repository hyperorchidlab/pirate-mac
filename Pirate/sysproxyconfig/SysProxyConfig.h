//
//  SysProxyConfig.h
//  sysproxyconfig
//
//  Created by Pirate on 2019/3/6.
//  Copyright © 2019 Pirate All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef SysProxyConfig_h
#define SysProxyConfig_h
NSString* const kSysProxyConfigVersion = @"0.1.7";
int const PACServerPort = 41087;
int const ProxyLocalPort = 41080;
NSString* const kDefaultPacURL = @"http://127.0.0.1:41087/proxy.pac";
#endif /* SysProxyConfig_h */
