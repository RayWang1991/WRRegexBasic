/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRENFABuilder.h"
#import "WRRETransition.h"
#import "WRREState.h"

@implementation WRExpression
- (instancetype)initWithStart:(WRREState *)start
                       andEnd:(WRREState *)end {
  if (self = [super init]) {
    _start = start;
    _end = end;
  }
  return self;
}
@end

@interface WRRENFABuilder ()
@property (nonatomic, strong, readwrite) NSMutableArray<WRExpression *> *stack;
@property (nonatomic, strong, readwrite) WRCharRangeNormalizeManager *mapper;
@end
@implementation WRRENFABuilder

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeManager *)mapper
                                    ast:(WRAST *)ast
and {
  if (self = [super init]) {
    _stack = [NSMutableArray array];
    _mapper = mapper;
    [ast accept:self];
  }
  return self;
}

- (WRREState *)nfa {
  assert(self.stack.count == 1);
  return nil;
}

//@"S -> Frag",
//@"Frag -> Frag or Seq | Seq ",
//@"Seq -> Seq Unit | Unit ",
//@"Unit -> char | char PostOp | ( Frag )",
//@"PostOp -> + | * | ? ",
// cat

- (void)visit:(WRAST *)ast
 withChildren:(NSArray<WRAST *> *)children {
  WRTerminal *terminal = ast.terminal;

  switch (terminal.terminalType) {
    case 0: {
      // or
      [children[0] accept:self];
      [children[1] accept:self];
      WRExpression *expression1 = self.stack.lastObject;
      [self.stack removeLastObject];
      WRExpression *expression2 = self.stack.lastObject;
      [self.stack removeLastObject];
      WRExpression *expression = [[WRExpression alloc] initWithStart:expression1
                                                              andEnd:expression2];
      break;
    }
    case 1: {
      // char
      WRREState *state1 = [[WRREState alloc] initWithStateId:-1];
      WRREState *state2 = [[WRREState alloc] initWithStateId:-1];
      int index = self.mapper->table['c'];
      WRRETransition *transition = [[WRRETransition alloc] initWithType:WRRETransitionTypeEpsilon
                                                                  index:index
                                                                 source:state1
                                                                 target:state2];
      WRExpression *expression = [[WRExpression alloc] initWithStart:state1
                                                              andEnd:state2];
      [self.stack addObject:expression];
      break;
    }
    case 2: {
      // (
    }
    case 3: {
      // )
      assert(NO);
    }
    case 4: {
      // +
      break;
    }
    case 5: {
      // *
      break;
    }
    case 6: {
      // ?
      break;
    }
    case 7: {
      // cat
      [children[0] accept:self];
      [children[1] accept:self];
      WRExpression *expression1 = self.stack.lastObject;
      [self.stack removeLastObject];
      WRExpression *expression2 = self.stack.lastObject;
      [self.stack removeLastObject];

      WRRETransition *transition = [[WRRETransition alloc] initWithType:WRRETransitionTypeEpsilon
                                                                  index:-1
                                                                 source:expression1.end
                                                                 target:expression2.start];
      [expression1.end.toTransitionList addObject:transition];
      [expression2.start.fromTransitionList addObject:transition];
      WRExpression *expression = [[WRExpression alloc] initWithStart:expression1.start
                                                              andEnd:expression2.end];
      [self.stack addObject:expression];
      break;
    }
    default:assert(NO);
      break;
  }
}
@end