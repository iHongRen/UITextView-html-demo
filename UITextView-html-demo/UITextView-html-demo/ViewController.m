//
//  ViewController.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/21.
//

#import "ViewController.h"
#import <SDWebImage/SDImageCache.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)onClearCache:(id)sender {
    [SDImageCache.sharedImageCache clearDiskOnCompletion:^{
            
    }];
}

@end
