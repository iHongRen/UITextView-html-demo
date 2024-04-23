//
//  WebViewController.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/23.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>
#import "UIViewController+Ext.h"

@interface WebViewController ()<WKNavigationDelegate>
@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (nonatomic, assign) CFAbsoluteTime startTime;
@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.startTime = CFAbsoluteTimeGetCurrent();

    [self.webView loadHTMLString:[self htmlFormJson] baseURL:nil];
    
    self.webView.navigationDelegate = self;
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();

    // 计算执行时间
    NSTimeInterval executionTime = endTime - self.startTime;
    NSLog(@"webview 耗时: %f 秒", executionTime);
    
    [self setupRight:executionTime];
}


@end
