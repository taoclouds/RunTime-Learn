//
//  RTFirstDemo.h
//  RunTimeDemo
//
//  Created by anson on 2018/8/7.
//  Copyright © 2018年 anson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface RTFirstDemo : NSObject <NSCopying>

@property (nonatomic, strong)NSArray *array;
@property (nonatomic, strong)NSString *string;

- (void)firstMethod;
- (void)secondMethod;

+ (void)classMethod;

@end

@interface UITableViewCell (Category)

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end
