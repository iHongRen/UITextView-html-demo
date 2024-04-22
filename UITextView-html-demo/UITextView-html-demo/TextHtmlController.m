//
//  TextHtmlController.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/21.
//

#import "TextHtmlController.h"
#import "NSString+Html.h"

@interface TextHtmlController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation TextHtmlController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.editable = NO;
    self.textView.layoutManager.usesFontLeading = NO;
    self.textView.layoutManager.allowsNonContiguousLayout = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    NSAttributedString *htmlAttrString = [[self htmlFormJson] toHtmlAttr];
    self.textView.attributedText = htmlAttrString;
    
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval executionTime = endTime - startTime;
    NSLog(@"直接加载耗时: %.2f 秒", executionTime);
    
    [self setupRight:executionTime];
}

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


@end
