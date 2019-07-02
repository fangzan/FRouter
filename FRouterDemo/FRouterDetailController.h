//
//  FRouterDetailController.h
//  FRouterDemo
//
//  Created by AoChen on 2019/6/3.
//  Copyright © 2019 Ac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FRouterDetailController : UIViewController


- (void)addLogText:(NSString *)text;
- (void)setLogImage:(UIImage *)image;

- (NSString *)testDetailObjectResult;

- (void)setParameters:(NSDictionary *)parameter;

@end

NS_ASSUME_NONNULL_END
