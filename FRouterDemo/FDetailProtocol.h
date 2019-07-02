//
//  FDetailProtocol.h
//  FRouterDemo
//
//  Created by AoChen on 2019/6/17.
//  Copyright © 2019 Ac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FFRouterProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@protocol FDetailProtocol <FFRouterProtocol>

- (id)interfaceViewController;

- (void)setParameters:(NSDictionary *)parameters;

- (void)showAlterViewCallBackInViewController:(UIViewController*)viewController;

@end

NS_ASSUME_NONNULL_END

