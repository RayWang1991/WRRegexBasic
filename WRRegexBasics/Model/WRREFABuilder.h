/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WRREState.h"
#import "WRCharRangeNormalizeManager.h"

@interface WRRENFABuilder : WRTreeVisitor

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeManager *)mapper
                                    ast:(WRAST *)ast;

- (WRREState *)nfa;

- (void)visit:(WRAST *)ast
 withChildren:(NSArray<WRAST *> *)children;

@end

@interface WRExpression : NSObject
@property (nonatomic, strong, readwrite) WRREState *start;
@property (nonatomic, strong, readwrite) WRREState *end;
- (instancetype)initWithStart:(WRREState *)start
                       andEnd:(WRREState *)end;
@end
