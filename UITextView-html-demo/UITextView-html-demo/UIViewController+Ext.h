//
//  UIViewController+Ext.h
//  UITextView-html-demo
//
//  Created by cxy on 2024/4/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Ext)

- (NSString*)htmlFormJson;

- (void)setupRight:(CGFloat)time;

- (void)showToast:(NSString*)text;
@end

NS_ASSUME_NONNULL_END
