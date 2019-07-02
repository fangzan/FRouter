//
//  FFRouterConfig.m
//  FRouterDemo
//
//  Created by AoChen on 2019/6/3.
//  Copyright © 2019 Ac. All rights reserved.
//

#import "FFRouterConfig.h"
#import "FDetailProtocol.h"
#import "FRouterDetailController.h"
@implementation FFRouterConfig

+ (void)initialRegisterRouteURL
{
    // Home组件
    id <FDetailProtocol> detailMoudle = [FFRouter interfaceCacheModuleForProtocol:@protocol(FDetailProtocol)];
    
    [FFRouter registerRouteURL:detailMoudle.schemesUrl handler:^(NSDictionary *routerParameters) {
        
//        FRouterDetailController *mRouterDetailController = [[FRouterDetailController alloc]init];
        [detailMoudle setParameters:routerParameters];
        [FFRouterNavigation pushViewController:detailMoudle.interfaceViewController animated:YES];
//        [mRouterDetailController setParameters:routerParameters];
    }];
}

@end
