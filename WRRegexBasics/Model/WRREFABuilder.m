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
@property (nonatomic, assign, readwrite) NSInteger stateId;
@end
@implementation WRRENFABuilder

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeManager *)mapper
                                    ast:(WRAST *)ast{
  if (self = [super init]) {
    _stack = [NSMutableArray array];
    _mapper = mapper;
    _stateId = 0;
    [ast accept:self];
  }
  return self;
}

- (WRREState *)nfa {
  assert(self.stack.count == 1);
  return nil;
}

- (WRREState *)newState{
  return [[WRREState alloc] initWithStateId:_stateId ++];
}

WRRETransition *(^newTransition)(WRRETransitionType type, int index , WRREState *from, WRREState *to)  =
^(WRRETransitionType type, int index , WRREState *from, WRREState *to){
  return [[WRRETransition alloc] initWithType:type
                                        index:index
                                       source:from
                                       target:to];
};

WRExpression *(^newExpression)(WRREState *start, WRREState *end)  =
^(WRREState *start, WRREState *end){
  return [[WRExpression alloc] initWithStart:start
                                      andEnd:end];
};


# define pop() self.stack.lastObject; [self.stack removeLastObject];
# define push(x) [self.stack addObject: x ];

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
      WRExpression *expression1 = pop();
      WRExpression *expression2 = pop();
      WRExpression *expression = newExpression(self.newState,self.newState);
      WRRETransition *transition1 = newTransition(WRRETransitionTypeEpsilon,-1,expression.start,expression1.start);
      WRRETransition *transition2 = newTransition(WRRETransitionTypeEpsilon,-1,expression.start,expression2.start);
      WRRETransition *transition3 = newTransition(WRRETransitionTypeEpsilon,-1,expression1.end,expression.end);
      WRRETransition *transition4 = newTransition(WRRETransitionTypeEpsilon,-1,expression2.end,expression.end);
      push(expression);
      break;
    }
    case 1: {
      // char
      WRREState *state1 = self.newState;
      WRREState *state2 = self.newState;
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
