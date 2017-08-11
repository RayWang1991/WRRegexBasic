/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRERegexCarrier.h"

#pragma mark - superClass
@implementation WRRERegexCarrier
// factory
+ (instancetype)noWayCarrier {
  return [[WRRERegexCarrierNoWay alloc] init];
}
+ (instancetype)epsilonCarrier {
  return [[WRRERegexCarrierEpsilon alloc] init];
}
+ (instancetype)singleCarrierWithCharRange:(WRCharRange *)charRange {
  return [[WRRERegexCarrierSingle alloc] initWithCharRange:charRange];
}
+ (instancetype)orCarrier {
  return [[WRRERegexCarrierOr alloc] init];
}
+ (instancetype)orCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children {
  return [[WRRERegexCarrierOr alloc] initWithChildren:children];
}
+ (instancetype)concatenateCarrier {
  return [[WRRERegexCarrierConcatenate alloc] init];
}
+ (instancetype)concatenateCarrierWithChildren:(NSArray <WRRERegexCarrier *> *)children {
  return [[WRRERegexCarrierConcatenate alloc] initWithChildren:children];
}
+ (instancetype)closureCarrier {
  return [[WRRERegexCarrierClosure alloc] init];
}
+ (instancetype)closureCarrierWithChild:(WRRERegexCarrier *)child {
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

- (void)accept:(WRVisitor *)visitor {
  [visitor visit:self];
}
@end

#pragma mark - subClasses

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

// visitor

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
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay :
    case WRRERegexCarrierTypeEpsilon :return self;
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
      if (!or.epsilonChild) {
        [or.children addObject:self];
        or.epsilonChild = self;
      }
      return or;
    }
    case WRRERegexCarrierTypeClosure:return other;

    default: {
      // single, concatenate, closure
      WRRERegexCarrierOr *or = [[WRRERegexCarrierOr alloc] initWithChildren:@[other, self]];
      or.epsilonChild = self;
      return or;
    }
  }
}
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  return other;
}
- (WRRERegexCarrier *)closure {
  return self;
}

// visitor

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
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay: {
      return self;
    }
    case WRRERegexCarrierTypeEpsilon: {
      WRRERegexCarrierOr *or = [[WRRERegexCarrierOr alloc] initWithChildren:@[other, self]];
      or.epsilonChild = other;
      return or;
    }
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
      [or.children addObject:self];
      return or;
    }
  }
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
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay:return other;
    case WRRERegexCarrierTypeEpsilon:return self;
    case WRRERegexCarrierTypeConcatenate : {
      WRRERegexCarrierConcatenate *cat = (WRRERegexCarrierConcatenate *) other;
      [cat.children insertObject:self
                         atIndex:0];
      return cat;
    }
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
      if (or.epsilonChild) {
        if (or.children.count == 2) {
          // other | epsilon
          WRRERegexCarrier *first = or.children.firstObject;
          if (first.type == WRRERegexCarrierTypeConcatenate) {
            [((WRRERegexCarrierConcatenate *) first).children insertObject:self
                                                                   atIndex:0];
          } else {
            [or.children replaceObjectAtIndex:0
                                   withObject:[WRRERegexCarrier concatenateCarrierWithChildren:@[self, first]]];
          }
          [or.children replaceObjectAtIndex:1
                                 withObject:self];
          or.epsilonChild = nil;
          return or;
        } else {
          // other1 | other2... | epsilon
          [or.children removeLastObject];
          or.epsilonChild = nil;
          WRRERegexCarrier *superOr =
            [WRRERegexCarrier orCarrierWithChildren:
              @[
                [WRRERegexCarrier concatenateCarrierWithChildren:@[self, or]],
                self,
              ]];
          return superOr;
        }
      } else {
        return [WRRERegexCarrier concatenateCarrierWithChildren:@[self, other]];
      }
    }
    default:return [WRRERegexCarrier concatenateCarrierWithChildren:@[self, other]];
  }
}
- (WRRERegexCarrier *)closure {
  return [[WRRERegexCarrierClosure alloc] initWithChild:self];
}

// visitor

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
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay:break;
    case WRRERegexCarrierTypeEpsilon: {
      if (!self.epsilonChild) {
        self.epsilonChild = other;
        [self.children addObject:other];
      }
      break;
    }
    case WRRERegexCarrierTypeOr: {
      [self.children addObjectsFromArray:[(WRRERegexCarrierOr *) other children]];
      break;
    }
    default: {
      [self.children addObject:other];
      break;
    }
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

// visitor
- (void)accept:(WRVisitor *)visitor {
  if ([visitor isKindOfClass:[WRTreeVisitor class]]) {
    WRTreeVisitor *treeVisitor = (WRTreeVisitor *) visitor;
    [treeVisitor visit:self
          withChildren:self.children];
  } else {
    [super accept:visitor];
  }
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
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay:return self;
    case WRRERegexCarrierTypeEpsilon : {
      // single, concatenate, closure
      WRRERegexCarrierOr *or = [[WRRERegexCarrierOr alloc] initWithChildren:@[self, other]];
      or.epsilonChild = other;
      return or;
    }
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
      [or.children addObject:self];
      return or;
    }
    default: {
      WRRERegexCarrierOr *or = [WRRERegexCarrier orCarrierWithChildren:@[self, other]];
      return or;
    }
  }
}
- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay:return other;
    case WRRERegexCarrierTypeEpsilon:return self;
    case WRRERegexCarrierTypeConcatenate : {
      WRRERegexCarrierConcatenate *cat = (WRRERegexCarrierConcatenate *) other;
      [self.children addObjectsFromArray:cat.children];
      return self;
    }
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
      if (or.epsilonChild) {
        if (or.children.count == 2) {
          // other | epsilon
          WRRERegexCarrier *first = or.children.firstObject;
          NSMutableArray *array = self.children.mutableCopy;
          if (first.type == WRRERegexCarrierTypeConcatenate) {
            [array addObjectsFromArray:((WRRERegexCarrierConcatenate *) first).children];
          } else {
            [array addObject:first];
          }
          [or.children replaceObjectAtIndex:0
                                 withObject:[WRRERegexCarrier concatenateCarrierWithChildren:array]];
          [or.children replaceObjectAtIndex:1
                                 withObject:self];
          or.epsilonChild = nil;
          return or;
        } else {
          // other1 | other2... | epsilon
          [or.children removeLastObject];
          or.epsilonChild = nil;
          NSMutableArray *array = self.children.mutableCopy;
          [array addObject:or];

          WRRERegexCarrier *superOr =
            [WRRERegexCarrier orCarrierWithChildren:
              @[
                [WRRERegexCarrier concatenateCarrierWithChildren:array],
                self,
              ]];
          return superOr;
        }
      } else {
        [self.children addObject:other];
        return self;
      }
    }
    default: {
      [self.children addObject:other];
      return self;
    }
  }
}
- (WRRERegexCarrier *)closure {
  return [[WRRERegexCarrierClosure alloc] initWithChild:self];
}

// visitor
- (void)accept:(WRVisitor *)visitor {
  if ([visitor isKindOfClass:[WRTreeVisitor class]]) {
    WRTreeVisitor *treeVisitor = (WRTreeVisitor *) visitor;
    [treeVisitor visit:self
          withChildren:self.children];
  } else {
    [super accept:visitor];
  }
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
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay:
    case WRRERegexCarrierTypeEpsilon : return self;
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
      [or.children addObject:self];
      return or;
    }
    default: {
      WRRERegexCarrierOr *or = [WRRERegexCarrier orCarrierWithChildren:@[self, other]];
      return or;
    }
  }
}

- (WRRERegexCarrier *)concatenateWith:(WRRERegexCarrier *)other {
  // same with single
  switch (other.type) {
    case WRRERegexCarrierTypeNoWay:return other;
    case WRRERegexCarrierTypeEpsilon:return self;
    case WRRERegexCarrierTypeConcatenate : {
      WRRERegexCarrierConcatenate *cat = (WRRERegexCarrierConcatenate *) other;
      [cat.children insertObject:self
                         atIndex:0];
      return cat;
    }
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = (WRRERegexCarrierOr *) other;
      if (or.epsilonChild) {
        if (or.children.count == 2) {
          // other | epsilon
          WRRERegexCarrier *first = or.children.firstObject;
          if (first.type == WRRERegexCarrierTypeConcatenate) {
            [((WRRERegexCarrierConcatenate *) first).children insertObject:self
                                                                   atIndex:0];
          } else {
            [or.children replaceObjectAtIndex:0
                                   withObject:[WRRERegexCarrier concatenateCarrierWithChildren:@[self, first]]];
          }
          [or.children replaceObjectAtIndex:1
                                 withObject:self];
          or.epsilonChild = nil;
          return or;
        } else {
          // other1 | other2... | epsilon
          [or.children removeLastObject];
          or.epsilonChild = nil;
          WRRERegexCarrier *superOr =
            [WRRERegexCarrier orCarrierWithChildren:
              @[
                [WRRERegexCarrier concatenateCarrierWithChildren:@[self, or]],
                self,
              ]];
          return superOr;
        }
      } else {
        return [WRRERegexCarrier concatenateCarrierWithChildren:@[self, other]];
      }
    }
    default:return [WRRERegexCarrier concatenateCarrierWithChildren:@[self, other]];
  }
}

- (WRRERegexCarrier *)closure {
  return self;
}

// visitor
- (void)accept:(WRVisitor *)visitor {
  if ([visitor isKindOfClass:[WRTreeVisitor class]]) {
    WRTreeVisitor *treeVisitor = (WRTreeVisitor *) visitor;
    [treeVisitor visit:self
          withChildren:@[self.child]];
  } else {
    [super accept:visitor];
  }
}
@end