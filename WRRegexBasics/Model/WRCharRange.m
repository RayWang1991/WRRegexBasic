/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRCharRange.h"
#import "WRRegexUtils.h"

@implementation WRCharRange

- (instancetype)initWithStart:(WRChar)start
                       andEnd:(WRChar)end {
  if (self = [super init]) {
    WRChar less = start < end ? start : end;
    WRChar great = start < end ? end : start;
    _start = less;
    _end = great;
  }
  return self;
}

- (instancetype)initWithChar:(WRChar)singleChar {
  if (self = [super init]) {
    _start = _end = singleChar;
  }
  return self;
}

- (NSUInteger)hash {
  // the seed should be a prime greater than 256,
  return _start * 373u + _end;
}

- (BOOL)isEqual:(id)object {
  return [object isKindOfClass:[WRCharRange class]] && self.hash == [object hash];
}

- (NSString *)description {
  if (self.start == self.end) {
    return [NSString stringWithFormat:@"%c",
                                      self.start];
  } else {
    return [NSString stringWithFormat:@"[%c-%c]",
                                      self.start,
                                      self.end];
  }
}

#pragma mark -function

@end
