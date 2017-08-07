/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
@class WRREState;
@class WRCharRange;

// in regex automa, state is trivial, while the transition is the boss

typedef NS_ENUM(NSInteger, WRRETransitionType) {
  WRRETransitionTypeEpsilon,
  WRRETransitionTypeNormal,
};
@interface WRRETransition : NSObject

@property (nonatomic, unsafe_unretained, readwrite) WRREState *source;
@property (nonatomic, unsafe_unretained, readwrite) WRREState *target;
@property (nonatomic, strong, readwrite) WRCharRange *charRange;
@property (nonatomic, assign, readwrite) int index;
@property (nonatomic, assign, readwrite) WRRETransitionType type;

- (instancetype)initWithType:(WRRETransitionType)type
                       index:(int)index
                      source:(WRREState *)source
                      target:(WRREState *)target;

@end