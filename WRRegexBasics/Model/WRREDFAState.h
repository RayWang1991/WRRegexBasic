/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>

@class WRRENFAState;

@interface WRREDFAState : NSObject
@property (nonatomic, assign, readwrite) NSUInteger stateId;
@property (nonatomic, strong, readwrite) NSArray <WRRENFAState *> *NFAStates;

- (instancetype)initWithNFAStateArray:(NSArray <WRRENFAState *> *)NFAStateArray;
+ (NSArray <WRRENFAState *> *)NFAStateArrayWithSet:(NSSet <WRRENFAState *> *)NFAStateSet;
- (instancetype)initWithNFAStateSet:(NSSet <WRRENFAState *> *)NFAStateSet;

- (void)trimWithStateId:(NSUInteger)stateId;
@end
