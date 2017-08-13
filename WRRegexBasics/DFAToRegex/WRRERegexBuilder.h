/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRREFABuilder.h"
#import "WRRERegexCarrier.h"
#import "WRREDFAState.h"
#import "WRREState.h"
#import "WRRETransition.h"
#import "WRCharRange.h"
#import "WRCharRangeNormalizeMapper.h"

@interface WRRERegexBuilder : NSObject

//- (instancetype)initWithDFAStart:(WRREDFAState *)start
//                    allDFAStates:(NSArray<WRREDFAState *> *)allStates
//                          mapper:(WRCharRangeNormalizeMapper *)mapper
//                           table:(int **)table;
@end