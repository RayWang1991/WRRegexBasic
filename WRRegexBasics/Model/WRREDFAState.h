/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRREState.h"

@interface WRREDFAState : WRREState
@property (nonatomic, strong, readwrite) NSArray <WRREState *> *sortedStates;

- (instancetype)initWithSortedStates:(NSArray <WRREState *> *)sortedStates;

- (void)trimWithStateId:(NSUInteger)stateId;
@end
