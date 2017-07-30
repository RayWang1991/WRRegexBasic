/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRREDFAState.h"
#import "WRRENFAState.h"

@implementation WRREDFAState

- (instancetype)initWithNFAStateArray:(NSArray <WRRENFAState *> *)NFAStateArray {
  if (self = [super init]) {
    _NFAStates = NFAStateArray;
    _stateId = 0;
  }
  return self;
}

- (instancetype)initWithNFAStateSet:(NSSet <WRRENFAState *> *)NFAStateSet {
  return [self initWithNFAStateArray:[WRREDFAState NFAStateArrayWithSet:NFAStateSet]];
}

+ (NSArray <WRRENFAState *> *)NFAStateArrayWithSet:(NSSet <WRRENFAState *> *)NFAStateSet {
  NSArray *array = [NFAStateSet.allObjects sortedArrayUsingComparator:
    ^NSComparisonResult(WRRENFAState *obj1, WRRENFAState *obj2) {
      NSUInteger id1 = obj1.stateId;
      NSUInteger id2 = obj2.stateId;
      return id1 == id2 ? NSOrderedSame :
        (id1 > id2 ? NSOrderedAscending : NSOrderedDescending);
    }];
  return array;
}

- (void)trimWithStateId:(NSUInteger)stateId {
  self.NFAStates = nil;
  _stateId = stateId;
}

#pragma mark - NSObject hash
- (NSUInteger)hash {
  if (_stateId) {
    return _stateId;
  } else {
    return self.BKDRHash;
  }
}

// BKDR hash
- (NSUInteger)BKDRHash {
  NSUInteger seed = 131;
  NSUInteger hash = 0;
  for (WRRENFAState *state in self.NFAStates) {
    hash = (hash * seed) + state.stateId;
  }
  return hash;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[WRREDFAState class]]) {
    return NO;
  } else {
    WRREDFAState *other = (WRREDFAState *) object;
    if (other.stateId && self.stateId) {
      return other.stateId == self.stateId;
    } else {
      if (self.NFAStates.count != other.NFAStates.count) {
        return NO;
      } else {
        __block BOOL res = YES;
        [self.NFAStates enumerateObjectsUsingBlock:
          ^(WRRENFAState *obj, NSUInteger idx, BOOL *stop) {
            res = obj.stateId != other.NFAStates[idx].stateId;
            *stop = res;
          }];
        return res;
      }
    }
  }
}
@end