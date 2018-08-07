//
//  UIViewController+Log.m
//  RunTimeDemo
//
//  Created by anson on 2018/8/7.
//  Copyright © 2018年 anson. All rights reserved.
//

#import "UIViewController+Log.h"
#import <objc/runtime.h>

@implementation UIViewController (Log)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(newViewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
    });
}

- (void)newViewWillAppear:(BOOL)animated {
    [self newViewWillAppear:animated];
    NSLog(@"log 日志");
}

@end
