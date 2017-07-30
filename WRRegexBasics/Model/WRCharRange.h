/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>

@interface WRCharRange : NSObject
@property (nonatomic, assign, readwrite) unsigned char start;
@property (nonatomic, assign, readwrite) unsigned char end;
- (instancetype)initWithStart:(unsigned char)start
                       andEnd:(unsigned char)end;
- (instancetype)initWithChar:(unsigned char)singleChar;
@end
