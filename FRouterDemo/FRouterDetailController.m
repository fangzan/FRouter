//
//  FRouterDetailController.m
//  FRouterDemo
//
//  Created by AoChen on 2019/6/3.
//  Copyright © 2019 Ac. All rights reserved.
//

#import "FRouterDetailController.h"

@interface FRouterDetailController ()

@property (nonatomic, strong) UILabel *textLB;

@property (nonatomic, strong) UIImageView *imgView;


@property (nonatomic,strong) NSString *logText;
@property (nonatomic,strong) UIImage *logImg;

@end

@implementation FRouterDetailController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor grayColor];
    
    _imgView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.frame) - 100)/2, 100, 100, 100)];
    [self.view addSubview:_imgView];
    
    
    _textLB = [[UILabel alloc] initWithFrame:CGRectMake(50, 250, CGRectGetWidth(self.view.frame) - 100, 200)];
    _textLB.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_textLB];
    
}

- (void)setParameters:(NSDictionary *)parameter
{
    NSLog(@"%@",parameter);
}


- (void)addLogText:(NSString *)text {
    if (self.logText.length > 0) { 
        self.logText = [NSString stringWithFormat:@"%@\n------------------------\n%@",self.logText,text];
    }else{
        self.logText = text;
    }
}

- (void)setLogImage:(UIImage *)image {
    self.logImg = image;
}

- (NSString *)testDetailObjectResult {
    return @"这是来自RouterDetailController的字符串";
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
