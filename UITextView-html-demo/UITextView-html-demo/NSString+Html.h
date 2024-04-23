//
//  NSString+Html.h
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Html)

- (NSAttributedString*)htmlToAttr;

- (NSString*)addImgStyle:(CGFloat)width;

- (NSString*)storeKeyForUrl;

- (BOOL)isBase64Url;

- (void)asyncHtmlToAttr:(void(^)( NSAttributedString * _Nullable attr,  NSArray * _Nullable imgUrls, BOOL finish))block;
@end

NS_ASSUME_NONNULL_END
