//
//  Swizzle.h
//  SwizzleDemo
//
//  Created by Chaosky on 2016/10/26.
//  Copyright © 2016年 1000phone. All rights reserved.
//

#ifndef Swizzle_h
#define Swizzle_h

#import <objc/runtime.h>

/**
 *  交换一个类中两个实例方法的实现。危险，请小心。
 *
 *  @param theClass         类对象
 *  @param originalSelector Selector 1
 *  @param swizzledSelector Selector 2
 *
 *  @return 如果swizzling成功返回YES，否则返回NO
 */
static inline BOOL swizzleInstanceMethod(Class theClass, SEL originalSelector, SEL swizzledSelector) {
    // 类中Selector的实例方法
    Method originalMethod = class_getInstanceMethod(theClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(theClass, swizzledSelector);
    
    if (!originalMethod || !swizzledMethod) return NO;
    
    // 添加方法的实现
    class_addMethod(theClass,
                    originalSelector,
                    class_getMethodImplementation(theClass, originalSelector),
                    method_getTypeEncoding(originalMethod));
    class_addMethod(theClass,
                    swizzledSelector,
                    class_getMethodImplementation(theClass, swizzledSelector),
                    method_getTypeEncoding(swizzledMethod));
    
    // 交换两个方法的实现
    method_exchangeImplementations(class_getInstanceMethod(theClass, originalSelector),
                                   class_getInstanceMethod(theClass, swizzledSelector));
    return YES;
}

/**
 *  交换一个类中两个类方法的实现。危险，请小心。
 *
 *  @param theClass         类对象
 *  @param originalSelector Selector 1
 *  @param swizzledSelector Selector 2
 *
 *  @return 如果swizzling成功返回YES，否则返回NO
 */
static inline BOOL swizzleClassMethod(Class theClass, SEL originalSelector, SEL swizzledSelector) {
    // 获取类对象的Class（也就是Class的MetaClass）
    Class class = object_getClass(theClass);
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (!originalMethod || !swizzledMethod) return NO;
    method_exchangeImplementations(originalMethod, swizzledMethod);
    return YES;
}

static inline BOOL addMethod(Class theClass, SEL selector, Method method) {
    return class_addMethod(theClass, selector, method_getImplementation(method), method_getTypeEncoding(method));
}

#endif /* Swizzle_h */
