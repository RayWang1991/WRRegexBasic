/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WRREState.h"
#import "WRCharRangeNormalizeMapper.h"

@interface WRREFABuilder : WRTreeVisitor

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeMapper *)mapper
                                    ast:(WRAST *)ast;

- (WRREState *)epsilonNFAStart;

- (void)epsilonNFA2NFA;

- (WRREState *)NFAStart;

- (void)visit:(WRAST *)ast
 withChildren:(NSArray<WRAST *> *)children;

@end

@interface WRExpression : NSObject
@property (nonatomic, strong, readwrite) WRREState *start;
@property (nonatomic, strong, readwrite) WRREState *end;
- (instancetype)initWithStart:(WRREState *)start
                       andEnd:(WRREState *)end;
@end
