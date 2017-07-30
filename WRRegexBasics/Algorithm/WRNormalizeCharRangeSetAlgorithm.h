/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
@class WRCharRange;

#define MAXLenCharRange 256u
@interface WRNormalizeCharRangeSetAlgorithm : NSObject{
 @public int table[MAXLenCharRange];
}
@property (nonatomic, strong, readwrite) NSMutableArray<WRCharRange *> *normalizedRanges;
- (instancetype)initWithRanges:(NSArray <WRCharRange *> *)ranges;
@end
