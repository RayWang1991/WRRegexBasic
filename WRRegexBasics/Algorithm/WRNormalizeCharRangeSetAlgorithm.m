/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRNormalizeCharRangeSetAlgorithm.h"
#import "WRCharRange.h"

@interface WRNormalizeCharRangeSetAlgorithm ()
@end

@implementation WRNormalizeCharRangeSetAlgorithm
- (instancetype)initWithRanges:(NSArray <WRCharRange *> *)ranges {
  if (!ranges.count) {
    return nil;
  }
  if (self = [super init]) {
    [self buildNormalizedCharRangeSetWithRanges:ranges];
    [self buildAlphabetTableWithNormalizedCharRanges:self.normalizedRanges];
  }
  return self;
}

- (void)buildNormalizedCharRangeSetWithRanges:(NSArray<WRCharRange *> *)ranges {
  unsigned int numberAxis[MAXLenCharRange * 2];
  int tail = 0;
  BOOL record[MAXLenCharRange * 2];
  for (unsigned int i = 0; i < MAXLenCharRange * 2; i++) {
    record[i] = false;
  }
  for (WRCharRange *range in ranges) {
    unsigned int left = range.start;
    unsigned int right = range.end + 256 ;
    if (!record[left]) {
      record[left] = true;
      numberAxis[tail++] = left;
    }
    if (!record[right]) {
      numberAxis[tail++] = right;
      record[right] = true;
    }
  }
  [self quickSort3WayForArray:numberAxis
                          low:0
                         high:tail-1];

  _normalizedRanges = [NSMutableArray array];
  for (unsigned int i = 0; i < tail - 1; i++) {
    unsigned int a = numberAxis[i];
    unsigned int b = numberAxis[i + 1];
    
    BOOL aR = a >= 256u;
    BOOL bR = b >= 256u;
    unsigned char aV = a & 0xFF;
    unsigned char bV = b & 0xFF;
    // LL p, q-1
    // LR p, q
    // RL p+1, q-1
    // RR p+1, q
    if (!aR && !bR) {
      [_normalizedRanges addObject:[[WRCharRange alloc] initWithStart:aV
                                                               andEnd:bV - (unsigned char) 1u]];
    } else if (!aR && bR) {
      [_normalizedRanges addObject:[[WRCharRange alloc] initWithStart:aV
                                                               andEnd:bV]];
    } else if (aR && !bR) {
      if (aR + (unsigned char) 1u > aR + (unsigned char) 1u) {
        [_normalizedRanges addObject:[[WRCharRange alloc] initWithStart:aV + (unsigned char) 1u
                                                                 andEnd:bV - (unsigned char) 1u]];
      }
    } else {
      [_normalizedRanges addObject:[[WRCharRange alloc] initWithStart:aV + (unsigned char) 1u
                                                               andEnd:bV]];
    }
  }
}

- (void)quickSort3WayForArray:(unsigned int *)array
                          low:(int)low
                         high:(int)high {
  if (low >= high) {
    return;
  }
  // [low, lt-1] a[i] < v
  // [lt, i-1] a[i] = v
  // [i, gt] unprocessed
  // [gt+1, hi] a[i] > v
  unsigned int v = array[low];
  int lt = low , gt = high, i = low + 1;
  while (i <= gt) {
    switch ([self compare:array[i]
                     with:v]) {
      case NSOrderedAscending:
        [self swap:array
                 a:lt++
                 b:i++];
        break;
      case NSOrderedSame:i++;
      case NSOrderedDescending:
        [self swap:array
                 a:gt--
                 b:i];
    }
  }
  [self quickSort3WayForArray:array
                          low:low
                         high:lt - 1];
  [self quickSort3WayForArray:array
                          low:gt + 1
                         high:high];
}

- (NSComparisonResult)compare:(unsigned int)a
                         with:(unsigned int)b {
  BOOL isARight = a >= 256u;
  BOOL isBRight = b >= 256u;
  unsigned int aV = a & 0xFF;
  unsigned int bV = b & 0xFF;
  
  return aV < bV ? NSOrderedAscending :
            aV > bV ? NSOrderedDescending :
               isARight == isBRight ? NSOrderedSame :
                  isBRight ? NSOrderedAscending : NSOrderedDescending;
}

- (void)swap:(unsigned int *)array
           a:(unsigned int)a
           b:(unsigned int)b {
  unsigned int temp = array[a];
  array[a] = array[b];
  array[b] = temp;
}

- (void)buildAlphabetTableWithNormalizedCharRanges:(NSArray <WRCharRange *> *)ranges {
  WRCharRange *first = ranges.firstObject;
  WRCharRange *last = ranges.lastObject;
  for (unsigned int i = 0; i < first.start; i++) {
    self->table[i] = -1;
  }
  int index = 0;
  unsigned int current = first.start;
  for (WRCharRange *range in ranges) {
    for (unsigned int i = range.start; i <= range.end; i++) {
      self->table[i] = index;
    }
    index++;
  }
  for (unsigned int i = last.end + 1; i < MAXLenCharRange; i++) {
    self->table[i] = -2;
  }
}
@end
