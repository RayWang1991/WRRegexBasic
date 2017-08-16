/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
extern const NSInteger WRREStateFinalIdError;

@class WRRETransition;
@interface WRREState : NSObject
@property (nonatomic, assign, readwrite) NSInteger stateId; // -1 under construction, <= -2 use hash, >= 0 use id
@property (nonatomic, assign, readwrite) NSInteger finalId; // 0 for normal, > 0 for accept, < 0 for error (-1)
@property (nonatomic, strong, readwrite) NSMutableArray <WRRETransition *> *fromTransitionList;
@property (nonatomic, strong, readwrite) NSMutableArray <WRRETransition *> *toTransitionList;
- (instancetype)initWithStateId:(NSInteger)stateId;
@end
