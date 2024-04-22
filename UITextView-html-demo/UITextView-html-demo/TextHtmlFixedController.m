//
//  TextHtmlFixedController.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/21.
//

#import "TextHtmlFixedController.h"
#import "NSString+Html.h"


@interface TextHtmlFixedController ()<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, copy) NSArray *imgUrls;
@end

@implementation TextHtmlFixedController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.editable = YES;
    self.textView.delegate = self;
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.layoutManager.usesFontLeading = NO;
    self.textView.layoutManager.allowsNonContiguousLayout = NO;
    
    [self loadHtml];
}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    NSString *fileName = textAttachment.fileWrapper.filename;
    NSLog(@"%@=======",fileName);
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    
    NSLog(@"%@=======",URL);
    return YES;
}

- (void)loadHtml {
    
    // 记录开始时间
    __block CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    CGFloat contentWidth = UIScreen.mainScreen.bounds.size.width;
    [[self htmlFormJson] htmlFont16ContentWidth:contentWidth block:^(NSDictionary *obj, BOOL finish) {
        self.textView.attributedText = obj[@"att"];
        self.imgUrls = obj[@"imgUrls"];
        
        // 记录结束时间
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();

        // 计算执行时间
        NSTimeInterval executionTime = endTime - startTime;
        NSLog(@"优化后耗时: %f 秒", executionTime);
        
        startTime = endTime;
        
        [self setupRight:executionTime];
    }];
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
