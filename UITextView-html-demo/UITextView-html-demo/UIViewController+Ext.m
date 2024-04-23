//
//  UIViewController+Ext.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/23.
//

#import "UIViewController+Ext.h"

@implementation UIViewController (Ext)

- (void)setupRight:(CGFloat)time {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"耗时: %.2f 秒", time] style:(UIBarButtonItemStylePlain) target:nil action:Nil];
    self.navigationItem.rightBarButtonItem = item;
}

- (NSString*)htmlFormJson {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"html-text" withExtension:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfURL:url];
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
    
    NSString *text = jsonDict[@"text"];
    return text;
}

- (void)showToast:(NSString*)text {
    CGFloat width = UIScreen.mainScreen.bounds.size.width;
    CGFloat height = UIScreen.mainScreen.bounds.size.height;

    UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake((width-260)/2, height/2-25, 260, 60)];
    lab.textColor = UIColor.whiteColor;
    lab.font = [UIFont systemFontOfSize:14];
    lab.numberOfLines = 2;
    lab.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    lab.layer.masksToBounds = YES;
    lab.layer.cornerRadius = 8;
    [self.view addSubview:lab];
    
    lab.text = text;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [lab removeFromSuperview];
    });
}

@end
