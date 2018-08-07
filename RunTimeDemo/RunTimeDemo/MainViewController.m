//
//  ViewController.m
//  RunTimeDemo
//
//  Created by anson on 2018/8/6.
//  Copyright © 2018年 anson. All rights reserved.
//

#import "MainViewController.h"
#import <objc/runtime.h>
#import "RTFirstDemo.h"
#import "RTMethodDemo.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)testRunTimeDemo {
    // 创建一个实例对象
    RTFirstDemo *demoInstance = [[RTFirstDemo alloc] init];
    // 获取 demoinstance 的类
    Class demoClass = [demoInstance class];
    
    //类名
    NSLog(@"类名：%s", class_getName(demoClass));
    //获取父类
    NSLog(@"父类：%s", class_getName(class_getSuperclass(demoClass)));
    // 当前类是否是元类
    NSLog(@"是否是元类：%@", (class_isMetaClass(demoClass)?@"是":@"否"));
    
    //类初始化后的实例变量大小
    NSLog(@"实例大小：%ld", class_getInstanceSize(demoClass));
    
    //操作一下成员变量
    unsigned int outCount = 0;   //用于记录成员变量个数
    Ivar *ivars = class_copyIvarList(demoClass, &outCount);
    for (NSInteger i = 0; i < outCount; ++i) {
        Ivar ivar = ivars[i];
        NSLog(@"当前的实例变量名称为 …%s", ivar_getName(ivar));
    }
    // 操作结束后 free 掉
    free(ivars);
    
    // 根据名称获取一下成员变量
    Ivar strIvar = class_getInstanceVariable(demoClass, "_strInstance");
    if (strIvar) {
        NSLog(@"打印出根据名称获取的成员变量名：%s", ivar_getName(strIvar));
    }
    
    // 操作一下属性
    outCount = 0;
    objc_property_t *properties = class_copyPropertyList(demoClass, &outCount);
    for (NSInteger i = 0; i < outCount; ++i) {
        objc_property_t property = properties[i];
        NSLog(@"当前的属性名称：%s", property_getName(property));
    }
    //操作结束 free 掉数组
    free(properties);
    
    objc_property_t property = class_getProperty(demoClass, "integer");
    if (property) {
        NSLog(@"根据 integer 名称获取到的属性：%s", property_getName(property));
    }
    
    // 操作方法
    outCount = 0;
    Method *methodList = class_copyMethodList(demoClass, &outCount);
    for (NSInteger i = 0; i < outCount; ++i) {
        Method method = methodList[i];
        NSLog(@"对于方法的遍历：%@", NSStringFromSelector(method_getName(method)));
    }
    //同样需要 free 数组
    free(methodList);
    
    Method nameMethod = class_getInstanceMethod(demoClass, @selector(firstMethod));
    if (nameMethod) {
        NSLog(@"firstMethod::: %@", NSStringFromSelector(method_getName(nameMethod)));
    }
    
    //类方法
    Method classMethod = class_getClassMethod(demoClass, @selector(classMethod));
    if (classMethod) {
        NSLog(@"类方法::: %@", NSStringFromSelector(method_getName(classMethod)));
    }
    
    //获取类中的方法并且执行
    IMP method = class_getMethodImplementation(demoClass, @selector(secondMethod));
    method();
    
    //协议
    outCount = 0;
    Protocol *__unsafe_unretained *protocols = class_copyProtocolList(demoClass, &outCount);
    for (NSInteger i = 0; i < outCount; ++i) {
        Protocol *protocol = protocols[i];
        NSLog(@"协议名称： %s", protocol_getName(protocol));
    }
    
    free(protocols);
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self testRunTimeDemo];
    RTMethodDemo *methodDemo = [[RTMethodDemo alloc] init];
    
    //methodDemo 并不能响应 firstMethod.使用 RunTime 的消息转发使它可以响应
    [methodDemo performSelector:@selector(firstMethod)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
