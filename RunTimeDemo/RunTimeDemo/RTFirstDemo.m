//
//  RTFirstDemo.m
//  RunTimeDemo
//
//  Created by anson on 2018/8/7.
//  Copyright © 2018年 anson. All rights reserved.
//

#import "RTFirstDemo.h"
#import <objc/runtime.h>

@interface RTFirstDemo () {
    //实例变量
    NSInteger   _firstInstance;
    NSString    *_strInstance;
}

@property (nonatomic, assign)NSUInteger integer;

- (void)methodWithArg:(NSInteger)arg1 Name:(NSString *)str;

@end

@implementation RTFirstDemo

- (void)firstMethod {
    NSLog(@"该方法为：firstMethod");
}

- (void)secondMethod {
    NSLog(@"该方法为：secondMethod");
}

+ (void)classMethod {
    NSLog(@"该类方法为：classMethod");
}

- (void)methodWithArg:(NSInteger)arg1 Name:(NSString *)str {
    NSLog(@"该方法为带参数的方法：%ld, %@", arg1, str);
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

@end

@implementation UITableViewCell (Category)
@dynamic currentIndexPath;

- (NSIndexPath *)currentIndexPath {
    NSIndexPath *indexPath = objc_getAssociatedObject(self, @selector(currentIndexPath));
    return indexPath;
}

- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath {
    objc_setAssociatedObject(self, @selector(currentIndexPath), currentIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end

