/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>

@class WRRENFAState;
@class WRRENFATransition;
@class WRREDFAState;
@class WRREState;
@class WRCharRange;
@class WRCharRangeNormalizeMapper;

@interface WRREAutoma : NSObject
- (instancetype)initWithStartState:(WRREState *)state;
@end