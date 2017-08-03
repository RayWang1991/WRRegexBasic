/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRRegexUtils.h"

@interface WRCharRange : NSObject
@property (nonatomic, assign, readwrite) WRChar start;
@property (nonatomic, assign, readwrite) WRChar end;
- (instancetype)initWithStart:(WRChar)start
                       andEnd:(WRChar)end;
- (instancetype)initWithChar:(WRChar)singleChar;
@end
