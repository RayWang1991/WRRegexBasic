/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
@class WRCharRange;

typedef NS_ENUM(NSInteger, WRRERegexCarrierType) {
  WRRERegexCarrierTypeNoWay,
  WRRERegexCarrierTypeEpsilon,
  WRRERegexCarrierTypeSingle,
  WRRERegexCarrierTypeOr,
  WRRERegexCarrierTypeConcatenate,
  WRRERegexCarrierTypeClosure,
};
@interface WRRERegexCarrier : NSObject<WRVisiteeProtocol>
@property (nonatomic, assign, readwrite) WRRERegexCarrierType type;
// factory
+ (instancetype)noWayCarrier;
+ (instancetype)EpsilonCarrier;
+ (instancetype)SingleCarrier:(WRCharRange *)charRange;
+ (instancetype)orCarrier;
+ (instancetype)concatenateCarrier;
+ (instancetype)closureCarrier;

// operator
- (instancetype)orWith:(WRRERegexCarrier *)other;
- (instancetype)concatenateWith:(WRRERegexCarrier *)other;
- (instancetype)closure;

// visitor
- (void)accept:(WRVisitor *)visitor;
@end

@interface WRRERegexCarrierNoWay : WRRERegexCarrier
@end

@interface WRRERegexCarrierEpsilon : WRRERegexCarrier
@end

@interface WRRERegexCarrierSingle : WRRERegexCarrier
@property (nonatomic, strong, readwrite) WRCharRange *charRange;
@end

@interface WRRERegexCarrierOr : WRRERegexCarrier
@property (nonatomic, strong, readwrite) NSMutableArray < WRRERegexCarrier *> *children;
@end

@interface WRRERegexCarrierConcatenate : WRRERegexCarrier
@property (nonatomic, strong, readwrite) NSMutableArray < WRRERegexCarrier *> *children;
@end

@interface WRRERegexCarrierClosure : WRRERegexCarrier
@property (nonatomic, strong, readwrite) WRRERegexCarrier *child;
@end

