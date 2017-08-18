/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRETransition.h"
#import "WRREState.h"

@implementation WRRETransition
- (instancetype)initWithType:(WRRETransitionType)type
                       index:(int)index
                      source:(WRREState *)source
                      target:(WRREState *)target {
  if (self = [super init]) {
    _type = type;
    _index = index;
    _source = source;
    _target = target;
    [_source.toTransitionList addObject:self];
    [_target.fromTransitionList addObject:self];
  }
  return self;
}

- (NSUInteger)hash{
  return self.index;
}
@end
