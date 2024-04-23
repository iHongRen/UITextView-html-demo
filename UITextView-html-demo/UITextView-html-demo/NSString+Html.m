//
//  NSString+Html.m
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/22.
//

#import "NSString+Html.h"
#import <SDWebImage/SDWebImage.h>
#import <CommonCrypto/CommonDigest.h>

#define TEST_MAX_FILE_EXTENSION_LENGTH (NAME_MAX - CC_MD5_DIGEST_LENGTH * 2 - 1)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static inline NSString * _Nonnull kTempFileNameForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15]];
    return filename;
}
#pragma clang diagnostic pop



@implementation NSString (Html)

- (NSAttributedString*)htmlToAttr {
    NSData *data = [self dataUsingEncoding:NSUnicodeStringEncoding];
    NSDictionary *options = @{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType
    };
    
    NSAttributedString *attr = [[NSAttributedString alloc] initWithData:data
                                                                options:options
                                                     documentAttributes:NULL
                                                                  error:nil];
    return attr;
}


- (NSString*)addImgStyle:(CGFloat)width {
    NSString *html = [NSString stringWithFormat:@"<head><style>body%@img{width:%f !important;height:auto}</head></style>%@",@"{font-size:16px;}",width,self];
    return html;
}

- (void)asyncHtmlToAttr:(void(^)( NSAttributedString * _Nullable attr,  NSArray * _Nullable imgUrls, BOOL finish))block {
    
    NSString *pattern = @"<\\s*img\\s+[^>]*?src\\s*=\\s*[\'\"](.*?)[\'\"]\\s*(alt=[\'\"](.*?)[\'\"])?[^>]*?\\/?\\s*>";
    NSRegularExpression *regexImg = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regexImg matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    if (matches.count==0) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSAttributedString *att = [self htmlToAttr];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(att, nil, YES);
                }
            });
        });
        return;
    }
    
    NSMutableArray *imgs = [NSMutableArray array];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *imageUrl = [self substringWithRange:matchRange];
        [imgs addObject:imageUrl];
    }
    
    
    dispatch_group_t group = dispatch_group_create();

    NSString *key = [imgs.firstObject storeKeyForUrl];
    if(imgs.firstObject && ![[SDImageCache sharedImageCache].diskCache containsDataForKey:key]) {
        
        dispatch_group_enter(group);

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            直接删除img标签
//            NSString *pattern = @"<img[^>]*>";
//            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
//            NSString *resultString = [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@""];

            
            // 使用占位图
            NSString *fileUrl = [[NSBundle mainBundle] URLForResource:@"default_cover" withExtension:@"png"].absoluteString;
            
            NSString *replacement =[NSString stringWithFormat:@"<img src=\"%@\">", fileUrl];

            NSString *resultString = [regexImg stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:replacement];
            
            NSAttributedString *att = [resultString htmlToAttr];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(att, nil, NO);
                }
                dispatch_group_leave(group);
            });
        });
    }
    
    __block NSString *html = self;
    for (NSInteger i=0; i<imgs.count; i++) {
        NSString *imageUrl = imgs[i];
        //        让base64图片直接加载
        //        BOOL isBase64Url = [imageUrl hasPrefix:@"data:image/"];
        //        if (isBase64Url) continue;
        
        dispatch_group_enter(group);
        [imageUrl downloadImageIfNeeded:^(NSURL *URL) {
            if (URL) {
                NSArray *matches = [regexImg matchesInString:html options:0 range:NSMakeRange(0, html.length)];
                NSRange matchRange = [matches[i] rangeAtIndex:1];
                html = [html stringByReplacingOccurrencesOfString:imageUrl withString:URL.absoluteString options:NSCaseInsensitiveSearch range:matchRange];
            }
            dispatch_group_leave(group);
        }];
    }
    
    
    dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
        NSAttributedString *att = [html htmlToAttr];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(att, imgs, YES);
            }
        });
    });
}

- (BOOL)isBase64Url {
    return [self hasPrefix:@"data:image/"];
}

// 中间转一道，不直接使用url作为 sdwebimage的key
- (NSString*)storeKeyForUrl {
    // 重新命名图片url,不带后缀
    NSString *key = kTempFileNameForKey(self);
    
    // 随便加个后缀，对图片格式无影响。无后缀 <img src="file:///xxxx"> 加载不出图片。
    key = [key stringByAppendingString:@".png"];
    return key;
}

- (void)downloadImageIfNeeded:(void(^)(NSURL *fileURL))block {
    
    NSString *key = [self storeKeyForUrl];
   
    NSURL *fileURL = [key fileURLForImageKey];
    if (fileURL) {
        if (block) {
            block(fileURL);
        }
        return;
    }
    
    BOOL isBase64Url = [self isBase64Url];
    if (isBase64Url) {
        NSString *base64 = [self componentsSeparatedByString:@"base64,"].lastObject;
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (data) {
            [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:key];
        }
        
        NSURL *URL = [key fileURLForImageKey];
        if (block) {
            block(URL);
        }
        
    } else if ([self hasPrefix:@"http"]) {
        
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:self] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            if (data) {
                [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:key];
            }
            NSURL *URL = [key fileURLForImageKey];
            if (block) {
                block(URL);
            }
        }];
    } else {
        if (block) {
            block(nil);
        }
    }
}

- (NSURL*)fileURLForImageKey {
    if([[SDImageCache sharedImageCache].diskCache containsDataForKey:self]) {
        NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:self];
        return [NSURL fileURLWithPath:path];
    }
    return nil;
}

@end
