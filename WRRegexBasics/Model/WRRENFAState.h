/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>

@class WRRENFATransition;

@interface WRRENFAState : NSObject
@property (nonatomic, assign, readwrite) NSUInteger stateId;
@property (nonatomic, strong, readwrite) NSMutableArray<WRRENFATransition *> *transitionList;
@end