/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
@class WRREDFAState;
@class WRCharRange;

// in regex automa, state is trivial, while the transition is the boss

typedef NS_ENUM(NSInteger,WRRETransitionType){
  WRRETransitionTypeEpsilon,
  WRRETransitionTypeNormal,
};
@interface WRRETransition : NSObject

@property (nonatomic, unsafe_unretained, readwrite) WRREDFAState *source;
@property (nonatomic, strong, readwrite) WRREDFAState *target;
@property (nonatomic, strong, readwrite) WRCharRange *charRanges;
@property (nonatomic, assign, readwrite) int index;
@property (nonatomic, assign, readwrite) WRRETransitionType type;

@end