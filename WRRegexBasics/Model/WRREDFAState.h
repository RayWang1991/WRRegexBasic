/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRREState.h"

@interface WRREDFAState : WRREState
@property (nonatomic, strong, readwrite) NSArray <WRREState *> *sortedStates;

- (instancetype)initWithNFAStateArray:(NSArray <WRREState *> *)NFAStateArray;
+ (NSArray <WRREState *> *)NFAStateArrayWithSet:(NSSet <WRREState *> *)NFAStateSet;
- (instancetype)initWithNFAStateSet:(NSSet <WRREState *> *)NFAStateSet;

- (void)trimWithStateId:(NSUInteger)stateId;
@end
