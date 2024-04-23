//
//  TextHtmlController.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/21.
//

#import "TextHtmlController.h"
#import "NSString+Html.h"
#import "UIViewController+Ext.h"

@interface TextHtmlController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation TextHtmlController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.editable = NO;

    [self loadHtml];
}

- (void)loadHtml {
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSAttributedString *htmlAttrString = [[self htmlFormJson] htmlToAttr];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.textView.attributedText = htmlAttrString;
            
            CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
            NSTimeInterval executionTime = endTime - startTime;
            NSLog(@"直接加载耗时: %.2f 秒", executionTime);
            
            [self setupRight:executionTime];

        });
    });
    
}


@end
