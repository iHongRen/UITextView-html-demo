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
static inline NSString * _Nonnull kBase64UrlForKey(NSString * _Nullable key) {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSURL *keyURL = [NSURL URLWithString:key];
    NSString *ext = keyURL ? keyURL.pathExtension : key.pathExtension;
    // File system has file name length limit, we need to check if ext is too long, we don't add it to the filename
    if (ext.length > TEST_MAX_FILE_EXTENSION_LENGTH) {
        ext = nil;
    }
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], ext.length == 0 ? @"" : [NSString stringWithFormat:@".%@", ext]];
    return filename;
}
#pragma clang diagnostic pop



@implementation NSString (Html)

- (NSAttributedString*)toHtmlAttr {
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


- (void)htmlFont16ContentWidth:(CGFloat)width block:(void(^)(NSDictionary *obj, BOOL finish))block {
    [self htmlContentWidth:width bodyCSS:@"{font-size:16px;}" block:block];
}

- (void)htmlContentWidth:(CGFloat)width bodyCSS:(NSString*)bodyCSS block:(void(^)(NSDictionary *obj, BOOL finish))block {
    
    NSString *html = [NSString stringWithFormat:@"<head><style>body%@img{width:%f !important;height:auto}</head></style>%@",bodyCSS?:@"{}",width,self];
    
    [html htmlContentWidth:width block:block];
}

- (void)htmlContentWidth:(CGFloat)width block:(void(^)(NSDictionary *obj, BOOL finish))block {
    
    if (self.length==0) {
        if (block) {
            block(nil, YES);
        }
        return;
    }
    
    
    NSString *pattern = @"<\\s*img\\s+[^>]*?src\\s*=\\s*[\'\"](.*?)[\'\"]\\s*(alt=[\'\"](.*?)[\'\"])?[^>]*?\\/?\\s*>";
    NSRegularExpression *regexImg = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regexImg matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    
    if (matches.count==0) {
        [self handleHtml:self imgs:@[] block:block];
        return;
    }
    
    NSMutableArray *imgs = [NSMutableArray array];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        NSString *imageUrl = [self substringWithRange:matchRange];
        [imgs addObject:imageUrl];
    }
    
    
    dispatch_group_t group = dispatch_group_create();

    NSString *key = [self storeKeyForUrl:imgs.firstObject];
    if(imgs.firstObject && ![[SDImageCache sharedImageCache].diskCache containsDataForKey:key]) {
        
        dispatch_group_enter(group);

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
//            NSString *pattern = @"<img[^>]*>";
//            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
            
            NSString *fileUrl = [[NSBundle mainBundle] URLForResource:@"default_cover" withExtension:@"png"].absoluteString;
            
            NSString *replacement =[NSString stringWithFormat:@"<img src=\"%@\">", fileUrl];

            NSString *resultString = [regexImg stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:replacement];
            
            NSAttributedString *att = [resultString toHtmlAttr];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    NSMutableDictionary *dict = @{}.mutableCopy;
                    dict[@"imgUrls"] = imgs;
                    dict[@"att"] = att;
                    block(dict, NO);
                }
                dispatch_group_leave(group);
            });
        });
    }
    
    __block NSString *html = self;
    for (NSInteger i=0; i<imgs.count; i++) {
        NSString *imageUrl = imgs[i];
        //        BOOL isBase64Url = [imageUrl hasPrefix:@"data:image/"];
        //        if (isBase64Url) continue;
        
        dispatch_group_enter(group);
        [self downloadImageIfNeed:imageUrl block:^(NSURL *URL) {
            if (URL) {
                NSArray *matches = [regexImg matchesInString:html options:0 range:NSMakeRange(0, html.length)];
                NSRange matchRange = [matches[i] rangeAtIndex:1];
                html = [html stringByReplacingOccurrencesOfString:imageUrl withString:URL.absoluteString options:NSCaseInsensitiveSearch range:matchRange];
            }
            dispatch_group_leave(group);
        }];
    }
    
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self handleHtml:html imgs:imgs block:block];
    });
    
}

- (BOOL)isBase64Url:(NSString*)url {
    return [url hasPrefix:@"data:image/"];
}

- (NSString*)storeKeyForUrl:(NSString*)url {
    BOOL isBase64Url = [self isBase64Url:url];
    NSString *key = isBase64Url ? kBase64UrlForKey(url) : url;
    // 没有后缀，自动加个后缀。否则 <img src="file:///xxxx"> 加载不出图片
    key = [key stringByAppendingString:@".png"];
    return key;
}

- (void)downloadImageIfNeed:(NSString*)url block:(void(^)(NSURL *fileURL))block {
    
    NSString *key = [self storeKeyForUrl:url];
   
    NSURL *fileURL = [self fileURLForImageKey:key];
    if (fileURL) {
        if (block) {
            block(fileURL);
        }
        return;
    }
    
    BOOL isBase64Url = [self isBase64Url:url];
    if (isBase64Url) {
        NSString *base64 = [url componentsSeparatedByString:@"base64,"].lastObject;
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (data) {
            [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:key];
        }
        
        NSURL *URL = [self fileURLForImageKey:key];
        if (block) {
            block(URL);
        }
        
    } else if ([url hasPrefix:@"http"]) {
        
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:url] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
            if (data) {
                [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:key];
            }
            NSURL *URL = [self fileURLForImageKey:key];
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

- (NSURL*)fileURLForImageKey:(NSString*)key {
    if([[SDImageCache sharedImageCache].diskCache containsDataForKey:key]) {
        NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:key];
        return [NSURL fileURLWithPath:path];
    }
    return nil;
}

- (void)handleHtml:(NSString*)html imgs:(NSArray*)imgs block:(void(^)(NSDictionary *obj, BOOL finish))block {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSAttributedString *att = [html toHtmlAttr];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                NSMutableDictionary *dict = @{}.mutableCopy;
                dict[@"imgUrls"] = imgs;
                dict[@"att"] = att;
                block(dict, NO);
            }
        });
    });
}

@end
