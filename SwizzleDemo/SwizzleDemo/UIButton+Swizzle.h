//
//  UIButton+Swizzle.h
//  SwizzleDemo
//
//  Created by Chaosky on 2016/10/26.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (Swizzle)

+ (NSInteger)tapCount;

- (void)swizzleSendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event;

@end
