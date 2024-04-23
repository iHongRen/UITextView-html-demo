//
//  TextHtmlFixedController.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/21.
//

#import "TextHtmlFixedController.h"
#import "NSString+Html.h"
#import <SDWebImage/SDWebImage.h>
#import "UIViewController+Ext.h"


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
    
    //
    self.textView.layoutManager.usesFontLeading = NO;
    self.textView.layoutManager.allowsNonContiguousLayout = NO;
    
    [self loadHtml];
}

#pragma mark - UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    
//    NSLog(@"imgUrls: %@", self.imgUrls);
    
    // 实现点击图片查看大图
    NSString *fileName = textAttachment.fileWrapper.filename;
    if (!fileName) {
        return YES;
    }
    
    for (NSInteger i=0; i<self.imgUrls.count; i++) {
        NSString *imgUrl = self.imgUrls[i];
        NSString *key = [imgUrl storeKeyForUrl];
        NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:key];
        if (path && [path containsString:fileName]) {
            
            NSLog(@"选中Url: %@", imgUrl);
            NSLog(@"选中FileURL: %@", [NSURL fileURLWithPath:path]);

            NSLog(@"选中index: %@", @(i));
            
            NSString *url = imgUrl;
            if ([imgUrl isBase64Url]) {
                url = path;
            }
            
            [self showToast:[NSString stringWithFormat:@"你点击了第%@张图片\n%@",@(i),url]];
            break;
        }
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    // 点击 URL 交互拦截
    NSLog(@"URL:%@",URL);
    return YES;
}

- (void)loadHtml {
    
    // 记录开始时间
    __block CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    CGFloat contentWidth = UIScreen.mainScreen.bounds.size.width;
    NSString *html = [[self htmlFormJson] addImgStyle:contentWidth];
    [html asyncHtmlToAttr:^(NSAttributedString *attr, NSArray *imgUrls, BOOL finish) {
        
        self.textView.attributedText = attr;
        self.imgUrls = imgUrls;
        
        // 记录结束时间
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();

        // 计算执行时间
        NSTimeInterval executionTime = endTime - startTime;
        NSLog(@"优化后耗时: %f 秒", executionTime);
        
        startTime = endTime;
        [self setupRight:executionTime];
    }];
}

// 计算高度
- (CGFloat)heightForAttr:(NSAttributedString *)attr width:(CGFloat)width {
    CGSize contextSize = [attr boundingRectWithSize:(CGSize){width, CGFLOAT_MAX} options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    return contextSize.height;
}

// 设置行高
- (NSAttributedString*)addLineHeight:(CGFloat)lineHeight attr:(NSAttributedString*)attr {
    [attr enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, attr.length) options:(NSAttributedStringEnumerationLongestEffectiveRangeNotRequired) usingBlock:^(NSMutableParagraphStyle *style, NSRange range, BOOL * _Nonnull stop) {
        NSAttributedString *att = [attr attributedSubstringFromRange:range];
        // 忽略 table 标签
        if (![[att description] containsString:@"NSTextTableBlock"]) {
            style.lineSpacing = 8;
        }
    }];
    return attr;
}
@end
