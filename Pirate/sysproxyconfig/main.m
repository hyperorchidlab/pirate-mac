//
//  main.m
//  sysproxyconfig
//
//  Created by hyperorchid on 2019/2/27.
//  Copyright © 2019年 hyperorchidlab All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "SysProxyConfig.h"

int main(int argc, const char * argv[]){
        if (argc != 2) {
                NSLog(@"Usage: sysproxyconfig [version]/[disable, pac global]>");
                return 1;
        }
        
        if (strncmp(argv[1], "version", strlen("version")) == 0) {
                printf("%s", [kSysProxyConfigVersion UTF8String]);
                exit(EXIT_SUCCESS);
        }
        int model = 0;
        if (strncmp(argv[1], "pac", strlen("pac")) == 0){
                model = 1;
        }else if ((strncmp(argv[1], "global", strlen("global")) == 0)){
                model = 2;
        }
        
        
        
        static AuthorizationRef authRef;
        static AuthorizationFlags authFlags;
        authFlags = kAuthorizationFlagDefaults
        | kAuthorizationFlagExtendRights
        | kAuthorizationFlagInteractionAllowed
        | kAuthorizationFlagPreAuthorize;
        OSStatus authErr = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, authFlags, &authRef);
        if (authErr != noErr) {
                authRef = nil;
                NSLog(@"Error when create authorization");
                return 1;
        }
        if (authRef == NULL) {
                NSLog(@"No authorization has been granted to modify network configuration");
                return 1;
        }
        
        NSSet* proxyExceptions = [[NSSet alloc] initWithObjects:@"127.0.0.1", @"localhost", @"192.168.0.0/16", @"10.0.0.0/8", @"FE80::/64", @"::1", @"FD00::/8", nil];
        
        SCPreferencesRef prefRef = SCPreferencesCreateWithAuthorization(nil, CFSTR("Pirate"), nil, authRef);
        
        NSDictionary *sets = (__bridge NSDictionary *)SCPreferencesGetValue(prefRef, kSCPrefNetworkServices);
        
        NSMutableDictionary *proxies = [[NSMutableDictionary alloc] init];
        
        for (NSString *key in [sets allKeys]) {
                NSMutableDictionary *dict = [sets objectForKey:key];
                NSString *hardware = [dict valueForKeyPath:@"Interface.Hardware"];
                
                if (!([hardware isEqualToString:@"AirPort"]
                    || [hardware isEqualToString:@"Wi-Fi"]
                    || [hardware isEqualToString:@"Ethernet"])){
                        continue;
                }
                NSString* prefPath = [NSString stringWithFormat:@"/%@/%@/%@", kSCPrefNetworkServices
                                      , key, kSCEntNetProxies];
                if (model == 1){
                        [proxies setObject:kDefaultPacURL forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
                        [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
                }else if (model == 2){
                        [proxies setObject:@"127.0.0.1" forKey:(NSString *)
                         kCFNetworkProxiesSOCKSProxy];
                        [proxies setObject:[NSNumber numberWithInteger:ProxyLocalPort] forKey:(NSString*)
                         kCFNetworkProxiesSOCKSPort];
                        [proxies setObject:[NSNumber numberWithInt:1] forKey:(NSString*)
                         kCFNetworkProxiesSOCKSEnable];
                        [proxies setObject:[proxyExceptions allObjects] forKey:(NSString *)kCFNetworkProxiesExceptionsList];
                }else {
                        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigEnable];
                        [proxies setObject:@"" forKey:(NSString *)kCFNetworkProxiesProxyAutoConfigURLString];
                        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPEnable];
                        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesHTTPSEnable];
                        [proxies setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCFNetworkProxiesSOCKSEnable];
                        [proxies setObject:@[] forKey:(NSString *)kCFNetworkProxiesExceptionsList];
                }
                
                
                SCPreferencesPathSetValue(prefRef, (__bridge CFStringRef)prefPath
                                            , (__bridge CFDictionaryRef)proxies);
        }
        
        BOOL commitRet = SCPreferencesCommitChanges(prefRef);
        BOOL applyRet =SCPreferencesApplyChanges(prefRef);
        SCPreferencesSynchronize(prefRef);
        
        AuthorizationFree(authRef, kAuthorizationFlagDefaults);
        NSLog(@"System proxy set result commitRet=%d, applyRet=%d", commitRet, applyRet);
}
