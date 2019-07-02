//
//  FRouterCallBackController.m
//  FRouterDemo
//
//  Created by AoChen on 2019/6/3.
//  Copyright © 2019 Ac. All rights reserved.
//

#import "FRouterCallBackController.h"

@interface FRouterCallBackController ()

@property (nonatomic,strong) TestCallback callback;

@property (nonatomic, strong) UIButton *callbackBtn;

@property (nonatomic, strong) UILabel *infoLabel;

@end

@implementation FRouterCallBackController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _callbackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _callbackBtn.frame = CGRectMake(100, 100, 100, 30);
    [_callbackBtn setTitle:@"回调并返回" forState:UIControlStateNormal];
    [_callbackBtn addTarget:self action:@selector(callbackBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_callbackBtn];
    
    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 180, 100, 100)];
    [self.view addSubview:_infoLabel];
    
    self.infoLabel.text = self.infoStr;
    
}

-(void)testCallBack:(TestCallback)callback {
    self.callback = callback;
}

- (IBAction)callbackBtnClick:(id)sender {
    if (self.callback) {
        NSString *callbackStr = [NSString stringWithFormat:@"我是回调过来的字符串 %@",[self getCurrentTime]];
        self.callback(callbackStr);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)getCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *dateNow = [NSDate date];
    NSString *currentTimeString = [formatter stringFromDate:dateNow];
    return currentTimeString;
}

@end
