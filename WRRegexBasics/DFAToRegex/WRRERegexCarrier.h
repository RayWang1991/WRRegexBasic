/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
@class WRCharRange;
@class WRRERegexCarrierClosure;
@class WRRERegexCarrierConcatenate;
@class WRRERegexCarrierOr;
@class WRRERegexCarrierSingle;
@class WRRERegexCarrierEpsilon;
@class WRRERegexCarrierNoWay;

typedef NS_ENUM(NSInteger, WRRERegexCarrierType) {
  WRRERegexCarrierTypeNoWay = 0,
  WRRERegexCarrierTypeEpsilon,
  WRRERegexCarrierTypeSingle,
  WRRERegexCarrierTypeOr,
  WRRERegexCarrierTypeConcatenate,
  WRRERegexCarrierTypeClosure,
};
@interface WRRERegexCarrier : NSObject<WRVisiteeProtocol>
@property (nonatomic, assign, readwrite) WRRERegexCarrierType type;
// factory
+ (WRRERegexCarrierNoWay *)noWayCarrier;
+ (WRRERegexCarrierEpsilon *)epsilonCarrier;
+ (WRRERegexCarrierSingle *)singleCarrierWithCharRange:(WRCharRange *)charRange;
+ (WRRERegexCarrierOr *)orCarrier;
+ (WRRERegexCarrierOr *)orCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children;
+ (WRRERegexCarrierConcatenate *)concatenateCarrier;
+ (WRRERegexCarrierConcatenate *)concatenateCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children;
+ (WRRERegexCarrierClosure *)closureCarrier;
+ (WRRERegexCarrierClosure *)closureCarrierWithChild:(WRRERegexCarrier *)child;

// operator
- (WRRERegexCarrier *)orWith:(WRRERegexCarrier *)other;
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other;
- (WRRERegexCarrier *)closure;

// function
- (instancetype)copy;
- (void)print;

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

/**
 * The epsilon child should be always the last child for find efficiency !
 */
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
