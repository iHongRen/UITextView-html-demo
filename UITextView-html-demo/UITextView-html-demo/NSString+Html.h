//
//  NSString+Html.h
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Html)

- (NSAttributedString*)toHtmlAttr;

- (void)htmlContentWidth:(CGFloat)width block:(void(^)(NSDictionary *obj, BOOL finish))block;

- (void)htmlContentWidth:(CGFloat)width bodyCSS:(NSString*)bodyCSS block:(void(^)(NSDictionary *obj, BOOL finish))block;

- (void)htmlFont16ContentWidth:(CGFloat)width block:(void(^)(NSDictionary *obj, BOOL finish))block;
@end

NS_ASSUME_NONNULL_END
