//
//  FRouterDetail.m
//  FRouterDemo
//
//  Created by AoChen on 2019/6/17.
//  Copyright © 2019 Ac. All rights reserved.
//

#import "FRouterDetail.h"
#import "FRouterDetailController.h"
@interface FRouterDetail ()<UIAlertViewDelegate>

@end

@implementation FRouterDetail
// 实现属性扩展
@synthesize schemesUrl;

- (NSString *)schemesUrl{
    return  @"frouterdemo://page/FRouterDetailController";
}

- (id)interfaceViewController
{
    return [[FRouterDetailController alloc]init];
}

- (void)setParameters:(NSDictionary *)parameters
{
    NSLog(@"%@",parameters);
}

- (void)showAlterViewCallBackInViewController:(UIViewController*)viewController
{
    UIAlertController *alter = [UIAlertController alertControllerWithTitle:@"" message:@"测试回调函数" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.callbackBlock) {
            self.callbackBlock(@"1234");
        }
    }];
    [alter addAction:sureAction];
    
    [viewController presentViewController:alter animated:YES completion:nil];
}

@end
