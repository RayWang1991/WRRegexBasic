/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRCharRange.h"

@implementation WRCharRange

- (instancetype)initWithStart:(unsigned char)start
                       andEnd:(unsigned char)end {
  if (self = [super init]) {
    unsigned char less = start < end ? start : end;
    unsigned char great = start < end ? end : start;
    _start = less;
    _end = great;
  }
  return self;
}

- (instancetype)initWithChar:(unsigned char)singleChar {
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

- (NSString *)description{
  return [NSString stringWithFormat:@"[%u,%u]",self.start,self.end];
}

#pragma mark -function

@end
