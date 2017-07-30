/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRENFAState.h"

@implementation WRRENFAState

- (NSUInteger)hash {
  return self.stateId;
}

- (BOOL)isEqualTo:(id)object {
  if(![object isKindOfClass:[self class]]){
   return NO;
  }
  return NO;
}
@end