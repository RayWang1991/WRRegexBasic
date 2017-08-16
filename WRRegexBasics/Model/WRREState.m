/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRREState.h"
const NSInteger WRREStateFinalIdError = -1;
@implementation WRREState
- (instancetype)initWithStateId:(NSInteger)stateId {
  if (self = [super init]) {
    _stateId = stateId;
    _finalId = 0;
    _toTransitionList = [NSMutableArray array];
    _fromTransitionList = [NSMutableArray array];
  }
  return self;
}

- (NSUInteger)hash {
  if (self.stateId >= 0) {
    return self.stateId;
  } else {
    assert(NO);
    return 0;
  }
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  } else if (self.stateId >= 0) {
    return [object stateId] == self.stateId;
  } else {
    assert(NO);
    return NO;
  }
}
@end
