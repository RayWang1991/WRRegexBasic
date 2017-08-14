/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRRegexUtils.h"
@class WRCharRange;

@interface WRCharRangeNormalizeMapper : NSObject {
 @public
  int table[MAXLenCharRange];
}
@property (nonatomic, strong, readwrite) NSMutableArray<WRCharRange *> *normalizedRanges;

- (instancetype)initWithRanges:(NSArray <WRCharRange *> *)ranges;
- (NSArray <NSNumber *> *)decomposeRange:(WRCharRange *)range;
- (NSArray <NSNumber *> *)decomposeRangeList:(NSArray <WRCharRange *> *)rangeList;

@end
