/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"

@class WRRERegexCarrier;
@interface WRRegexWriter : WRTreeVisitor
- (void)visit:(WRRERegexCarrier *)carrier
 withChildren:(NSArray<WRRERegexCarrier *> *)children;
@end