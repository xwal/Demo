//
//  UIButton+Swizzle.m
//  SwizzleDemo
//
//  Created by Chaosky on 2016/10/26.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#import "UIButton+Swizzle.h"

static NSInteger count = 0;

@implementation UIButton (Swizzle)

+ (NSInteger)tapCount {
    return count;
}

- (void)swizzleSendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    count += 1;
    NSLog(@"按钮点击了 %ld 次", count);
    [self swizzleSendAction:action to:target forEvent:event];
}


@end
