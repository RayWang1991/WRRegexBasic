/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRREFABuilder.h"
#import "WRParsingBasicLib.h"

@interface WRREFAManager : WRTreeVisitor
@property (nonatomic, strong, readwrite) WRREFABuilder *builder;

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeMapper *)mapper
                                    ast:(WRAST *)ast;
- (void)visit:(WRAST *)ast
 withChildren:(NSArray<WRAST *> *)children;

@end