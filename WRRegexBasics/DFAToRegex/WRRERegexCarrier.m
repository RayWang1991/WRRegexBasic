/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRERegexCarrier.h"

@implementation WRRERegexCarrier
// factory
+ (instancetype)noWayCarrier{
  return [[WRRERegexCarrierNoWay alloc]init];
}
+ (instancetype)EpsilonCarrier{
  return [[WRRERegexCarrierEpsilon alloc]init];
}
+ (instancetype)SingleCarrierWithCharRange:(WRCharRange *)charRange{
  return [[WRRERegexCarrierSingle alloc] initWithCharRange:charRange];
}
+ (instancetype)orCarrier{
  return [[WRRERegexCarrierOr alloc]init];
}
+ (instancetype)orCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children{
  return [[WRRERegexCarrierOr alloc] initWithChildren:children];
}
+ (instancetype)concatenateCarrier{
  return [[WRRERegexCarrierConcatenate alloc]init];
}
+ (instancetype)concatenateCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children{
  return [[WRRERegexCarrierConcatenate alloc] initWithChildren:children];
}
+ (instancetype)closureCarrier{
  return [[WRRERegexCarrierClosure alloc]init];
}
+ (instancetype)closureCarrierWithChild:(WRRERegexCarrier *)child{
  return [[WRRERegexCarrierClosure alloc] initWithChild:child];
}

// operator
- (instancetype)orWith:(WRRERegexCarrier *)other {
  assert(NO);
  return nil;
}
- (instancetype)concatenateWith:(WRRERegexCarrier *)other {
  assert(NO);
  return nil;
}
- (instancetype)closure {
  assert(NO);
  return nil;
}

@end

@implementation WRRERegexCarrierNoWay
- (instancetype)init {
  if (self = [super init]) {
    self.type = WRRERegexCarrierTypeNoWay;
  }
  return self;
}

// operator
- (WRRERegexCarrier *)orWith:(WRRERegexCarrier *)other {
  return other;
}
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  return self;
}
- (WRRERegexCarrier *)closure {
  return self;
}

@end

@implementation WRRERegexCarrierEpsilon
- (instancetype)init {
  if (self = [super init]) {
    self.type = WRRERegexCarrierTypeEpsilon;
  }
  return self;
}

// operator
- (WRRERegexCarrier *)orWith:(WRRERegexCarrier *)other {
  return other;
}
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  return other;
}
- (WRRERegexCarrier *)closure {
  return self;
}

@end

@implementation WRRERegexCarrierSingle
- (instancetype)init {
  if (self = [super init]) {
    self.type = WRRERegexCarrierTypeSingle;
  }
  return self;
}
- (instancetype)initWithCharRange:(WRCharRange *)charRange {
  if (self = [self init]) {
    _charRange = charRange;
  }
  return self;
}

// operator
- (WRRERegexCarrier *)orWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeOr) {
    WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
    [or.children addObject:self];
    return or;
  } else {
    WRRERegexCarrierOr *or = [[WRRERegexCarrierOr alloc] initWithChildren:@[self, other]];
    return or;
  }
}
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeConcatenate) {
    WRRERegexCarrierConcatenate *cat = (WRRERegexCarrierConcatenate *) other;
    [cat.children addObject:self];
    return cat;
  } else {
    WRRERegexCarrierConcatenate *cat = [[WRRERegexCarrierConcatenate alloc] initWithChildren:@[self, other]];
    return cat;
  }
}
- (WRRERegexCarrier *)closure {
  return [[WRRERegexCarrierClosure alloc] initWithChild:self];
}

@end

@implementation WRRERegexCarrierOr
- (instancetype)init {
  if (self = [super init]) {
    self.type = WRRERegexCarrierTypeOr;
    _children = [NSMutableArray array];
  }
  return self;
}
- (instancetype)initWithChildren:(NSArray <WRRERegexCarrier *> *)children {
  if (self = [self init]) {
    [self.children addObjectsFromArray:children];
  }
  return self;
}

// operator
- (WRRERegexCarrier *)orWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeOr) {
    [self.children addObjectsFromArray:[(WRRERegexCarrierOr *) other children]];
  } else {
    [self.children addObject:other];
  }
  return self;
}
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeConcatenate) {
    WRRERegexCarrierConcatenate *cat = (WRRERegexCarrierConcatenate *) other;
    [cat.children addObject:self];
    return cat;
  } else {
    WRRERegexCarrierConcatenate *cat = [[WRRERegexCarrierConcatenate alloc] initWithChildren:@[self, other]];
    return cat;
  }
}
- (WRRERegexCarrier *)closure {
  return [[WRRERegexCarrierClosure alloc] initWithChild:self];
}

@end

@implementation WRRERegexCarrierConcatenate
- (instancetype)init {
  if (self = [super init]) {
    self.type = WRRERegexCarrierTypeConcatenate;
    _children = [NSMutableArray array];
  }
  return self;
}
- (instancetype)initWithChildren:(NSArray <WRRERegexCarrier *> *)children {
  if (self = [self init]) {
    [self.children addObjectsFromArray:children];
  }
  return self;
}

// operator
- (WRRERegexCarrier *)orWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeOr) {
    WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
    [or.children addObject:self];
    return or;
  } else {
    WRRERegexCarrierOr *or = [[WRRERegexCarrierOr alloc] initWithChildren:@[self, other]];
    return or;
  }
}
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeConcatenate) {
    WRRERegexCarrierConcatenate *cat = (WRRERegexCarrierConcatenate *) other;
    [self.children addObjectsFromArray:cat.children];;
  } else {
    [self.children addObject:other];
  }
  return self;
}
- (WRRERegexCarrier *)closure {
  return [[WRRERegexCarrierClosure alloc] initWithChild:self];
}
@end

@implementation WRRERegexCarrierClosure
- (instancetype)init {
  if (self = [super init]) {
    self.type = WRRERegexCarrierTypeClosure;
  }
  return self;
}

- (instancetype)initWithChild:(WRRERegexCarrier *)child {
  if (self = [self init]) {
    _child = child;
  }
  return self;
}

// operator
- (WRRERegexCarrier *)orWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeOr) {
    WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
    [or.children addObject:self];
    return or;
  } else {
    WRRERegexCarrierOr *or = [[WRRERegexCarrierOr alloc] initWithChildren:@[self, other]];
    return or;
  }
}

- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  if (other.type == WRRERegexCarrierTypeConcatenate) {
    WRRERegexCarrierConcatenate *cat = (WRRERegexCarrierConcatenate *) other;
    [cat.children addObject:self];
    return cat;
  } else {
    WRRERegexCarrierConcatenate *cat = [[WRRERegexCarrierConcatenate alloc] initWithChildren:@[self, other]];
    return cat;
  }
}

- (WRRERegexCarrier *)closure {
  return self;
}

@end