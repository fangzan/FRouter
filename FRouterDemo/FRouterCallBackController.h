//
//  FRouterCallBackController.h
//  FRouterDemo
//
//  Created by AoChen on 2019/6/3.
//  Copyright © 2019 Ac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TestCallback)(NSString *callbackStr);

@interface FRouterCallBackController : UIViewController

-(void)testCallBack:(TestCallback)callback;

@property (nonatomic,strong) NSString *infoStr;

@end

NS_ASSUME_NONNULL_END
