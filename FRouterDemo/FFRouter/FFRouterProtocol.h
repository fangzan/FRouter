//
//  FFRouterProtocol.h
//  FRouterDemo
//
//  Created by AoChen on 2019/6/15.
//  Copyright © 2019 Ac. All rights reserved.
//

//此类为协议基础类
/***
 协议写法注意事项:
 1.一个协议只能对应一个模块实现类，不能对应多个不然会随机调用其中一个实现类
 2.模块实现类遵循的组件化协议必须是放在第一位 如:@interface HomeModule : NSObject<MoudleHome,NSCopying>
 3.模块协议必须遵循FFRouterProtocol协议
 ***/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FFRouter.h"

typedef void(^FFCallBackBlock)(id _Nullable parameter);

NS_ASSUME_NONNULL_BEGIN
#pragma mark -基础组件 这里可以定义一些公共的api和属性

@protocol FFRouterProtocol <NSObject>
@optional;
//回调
@property (nonatomic, copy) FFCallBackBlock callbackBlock;
//schemesUrl
@property (nonatomic, copy) NSString *schemesUrl;

@end

NS_ASSUME_NONNULL_END

