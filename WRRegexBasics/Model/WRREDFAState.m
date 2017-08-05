/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRREDFAState.h"

@implementation WRREDFAState

- (instancetype)initWithSortedStates:(NSArray <WRREState *> *)sortedStates {
  if (self = [super initWithStateId:-2]) {
    _sortedStates = sortedStates;
  }
  return self;
}

- (void)trimWithStateId:(NSUInteger)stateId {
  self.sortedStates = nil;
  self.stateId = stateId;
}

#pragma mark - NSObject hash
// -1 under construction, <= -2 use hash, >= 0 use id

- (NSUInteger)hash {
  if (self.stateId >= 0) {
    return self.stateId;
  } else if (self.stateId == -1) {
    assert(NO);
    return 0;
  } else {
    NSUInteger res = self.BKDRHash;
    return self.BKDRHash;
  }
}

- (NSUInteger)BKDRHash {
  NSUInteger seed = 131;
  NSUInteger hash = 0;
  for (WRREState *state in self.sortedStates) {
    hash = (hash * seed) + state.stateId;
  }
  return hash;
}

- (NSUInteger)DJBHash {
  NSUInteger hash = 5381;
  for (WRREState *state in self.sortedStates) {
    hash += (hash << 5) + state.stateId;
  }
  return hash;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  } else if (self.stateId >= 0) {
    return [object stateId] == self.stateId;
  } else if (self.stateId == -1) {
    return NO;
  } else {
    return [object BKDRHash] == [self BKDRHash] && [object DJBHash] == [self DJBHash];
  }
}

@end
