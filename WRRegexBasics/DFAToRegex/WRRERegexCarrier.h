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
+ (instancetype)epsilonCarrier;
+ (instancetype)singleCarrierWithCharRange:(WRCharRange *)charRange;
+ (instancetype)orCarrier;
+ (instancetype)orCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children;
+ (instancetype)concatenateCarrier;
+ (instancetype)concatenateCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children;
+ (instancetype)closureCarrier;
+ (instancetype)closureCarrierWithChild:(WRRERegexCarrier *)child;

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
- (instancetype)initWithCharRange:(WRCharRange *)charRange;
@end

@interface WRRERegexCarrierOr : WRRERegexCarrier
@property (nonatomic, strong, readwrite) NSMutableArray < WRRERegexCarrier *> *children;
@property (nonatomic, strong, readwrite) WRRERegexCarrierEpsilon *epsilonChild;
- (instancetype)initWithChildren:(NSArray <WRRERegexCarrier *> *)children;
@end

@interface WRRERegexCarrierConcatenate : WRRERegexCarrier
@property (nonatomic, strong, readwrite) NSMutableArray < WRRERegexCarrier *> *children;
- (instancetype)initWithChildren:(NSArray <WRRERegexCarrier *> *)children;
@end

@interface WRRERegexCarrierClosure : WRRERegexCarrier
@property (nonatomic, strong, readwrite) WRRERegexCarrier *child;
- (instancetype)initWithChild:(WRRERegexCarrier *)child;
@end
