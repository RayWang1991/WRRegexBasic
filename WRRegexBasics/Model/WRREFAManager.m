/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRREFAManager.h"
#import "WRRegexLanguage.h"

@interface WRREFAManager ()
@property (nonatomic, strong, readwrite) WRCharRangeNormalizeMapper *mapper;
@property (nonatomic, strong, readwrite) NSMutableArray *stack;
@end

@implementation WRREFAManager {

}

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeMapper *)mapper
                                    ast:(WRAST *)ast {
  if (self = [super init]) {
    _mapper = mapper;
    _stack = [NSMutableArray array];
    [self buildWholeWithAst:(WRAST *)ast];
  }
  return self;
}

- (void)buildWholeWithAst:(WRAST *)ast{
  [ast accept:self];
  assert(self.stack.count == 1);
  _builder = self.stack.firstObject;
}

# define pop() self.stack.lastObject; [self.stack removeLastObject];
# define push(x) [self.stack addObject: x ];

- (void)visit:(WRAST *)ast
 withChildren:(NSArray<WRAST *> *)children {
  WRTerminal *terminal = ast.terminal;
  switch (terminal.terminalType){
    case tokenTypeExprNot:{
      [children[0] accept:self];
      WRREFABuilder *fa = pop();
      push([fa negation]);
      break;
    }
    case tokenTypeExprAnd:{
      [children[0] accept:self];
      [children[1] accept:self];
      WRREFABuilder *fa2 = pop();
      WRREFABuilder *fa1 = pop();
      push ([fa1 intersectWith:fa2]);
      break;
    }
    case tokenTypeExprOr:{
      [children[0] accept:self];
      [children[1] accept:self];
      WRREFABuilder *fa2 = pop();
      WRREFABuilder *fa1 = pop();
      push ([fa1 unionWith:fa2]);
      break;
    }
    default:{
      WRREFABuilder *builder = [[WRREFABuilder alloc] initWithCharRangeMapper:self.mapper
                                                                          ast:ast];
      push(builder);
    }
  }

}

@end