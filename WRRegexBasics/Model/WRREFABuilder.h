/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WRCharRangeNormalizeMapper.h"

@class WRREState;
@class WRREDFAState;
@interface WRREFABuilder : WRTreeVisitor {
 @public
  int **dfaTable;
}

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeMapper *)mapper
                                    ast:(WRAST *)ast;
- (void)visit:(WRAST *)ast
 withChildren:(NSArray<WRAST *> *)children;

- (WRREState *)epsilonNFAStart;

- (void)epsilonNFA2NFA;

- (WRREState *)NFAStart;

- (void)NFA2DFA;

- (void)printNFA; // TODO

- (WRREDFAState *)DFAStart;

- (BOOL)matchWithString:(NSString *)input;

- (void)printDFA;

- (void)DFA2Regex;

// operation
- (WRREFABuilder *)negation;

- (WRREFABuilder *)unionWith:(WRREFABuilder *)other;

- (WRREFABuilder *)intersectWith:(WRREFABuilder *)other;
@end

@interface WRExpression : NSObject
@property (nonatomic, strong, readwrite) WRREState *start;
@property (nonatomic, strong, readwrite) WRREState *end;
- (instancetype)initWithStart:(WRREState *)start
                       andEnd:(WRREState *)end;
@end
