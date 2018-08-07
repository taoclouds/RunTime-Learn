//
//  RTMethodDemo.m
//  RunTimeDemo
//
//  Created by anson on 2018/8/7.
//  Copyright © 2018年 anson. All rights reserved.
//

#import "RTMethodDemo.h"
#import <objc/runtime.h>

@implementation RTMethodDemo

- (instancetype) init {
    if (self = [super init]) {
        _firstDemo = [[RTFirstDemo alloc] init];
    }
    return self;
}

//动态解析

void methodFunction(id self, SEL _cmd) {
    NSLog(@"动态运行时添加的方法");
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSString *selectorString = NSStringFromSelector(sel);
    if ([selectorString isEqualToString:@"firstMethod"]) {
        class_addMethod(self, @selector(firstMethod), (IMP)methodFunction, "@:");
    }
    return [super resolveInstanceMethod:sel];
}


//// 消息转发的接收者
//- (id)forwardingTargetForSelector:(SEL)aSelector {
//    NSString *selectorString = NSStringFromSelector(aSelector);
//    if ([selectorString isEqualToString:@"firstMethod"]) {
//        return self.firstDemo;
//    }
//    return [super forwardingTargetForSelector:aSelector];
//
//}

//// 消息转发的最后一环
//
//- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
//    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
//    if (!signature) {
//        if ([RTFirstDemo instancesRespondToSelector:aSelector]) {
//            signature = [RTFirstDemo instanceMethodSignatureForSelector:aSelector];
//        }
//    }
//    return signature;
//}
//
//- (void)forwardInvocation:(NSInvocation *)anInvocation {
//    if ([RTFirstDemo instancesRespondToSelector:anInvocation.selector]) {
//        [anInvocation invokeWithTarget:self.firstDemo];
//    }
//}

@end
