/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRREFABuilder.h"
#import "WRRETransition.h"
#import "WRREState.h"
#import "WRRegexScanner.h"
#import "WRRegexLanguage.h"
#import "WRREDFAState.h"

@implementation WRExpression

- (instancetype)initWithStart:(WRREState *)start
                       andEnd:(WRREState *)end {
  if (self = [super init]) {
    _start = start;
    _end = end;
  }
  return self;
}

- (NSString *)debugDescription {
  return [NSString stringWithFormat:@"%@ : %@",
                                    self.start,
                                    self.end];
}

@end

@interface WRREFABuilder ()

@property (nonatomic, strong, readwrite) NSMutableArray<WRExpression *> *stack;
@property (nonatomic, strong, readwrite) WRCharRangeNormalizeMapper *mapper;
@property (nonatomic, assign, readwrite) NSInteger stateId;
@property (nonatomic, strong, readwrite) NSMutableArray <WRREState *> *allStates;
@property (nonatomic, strong, readwrite) NSMutableArray <WRREDFAState *> *allDFAStates;
@property (nonatomic, strong, readwrite) WRREState *epsilonNFAStart;
@property (nonatomic, strong, readwrite) WRREState *NFAStart; // without epsilon transitions
@property (nonatomic, strong, readwrite) WRREDFAState *DFAStart; // without epsilon transitions

@end

@implementation WRREFABuilder

- (instancetype)initWithCharRangeMapper:(WRCharRangeNormalizeMapper *)mapper
                                    ast:(WRAST *)ast {
  if (self = [super init]) {
    _stack = [NSMutableArray array];
    _allStates = [NSMutableArray array];
    _mapper = mapper;
    _stateId = 0;
    [ast accept:self];
  }
  return self;
}

- (WRREState *)epsilonNFAStart {
  if (!_epsilonNFAStart) {
    assert(self.stack.count == 1);
    _epsilonNFAStart = self.stack.firstObject.start;
    self.stack.firstObject.end.finalId = 1;
  }
  return _epsilonNFAStart;
}

- (WRREState *)NFAStart {
  if (!_NFAStart) {
    [self epsilonNFA2NFA];
    _NFAStart = self.epsilonNFAStart;
  }
  return _NFAStart;
}

- (WRREDFAState *)DFAStart {
  if (!_DFAStart) {
    [self NFA2DFA];
  }
  return _DFAStart;
}

- (WRREState *)newState {
  WRREState *state = [[WRREState alloc] initWithStateId:_stateId++];
  [self.allStates addObject:state];
  return state;
}

WRRETransition *(^newTransition)(WRRETransitionType type, int index, WRREState *from, WRREState *to) =
^(WRRETransitionType type, int index, WRREState *from, WRREState *to) {
  return [[WRRETransition alloc] initWithType:type
                                        index:index
                                       source:from
                                       target:to];
};

WRExpression *(^newExpression)(WRREState *start, WRREState *end) =
^(WRREState *start, WRREState *end) {
  return [[WRExpression alloc] initWithStart:start
                                      andEnd:end];
};

# define pop() self.stack.lastObject; [self.stack removeLastObject];
# define push(x) [self.stack addObject: x ];

- (void)visit:(WRAST *)ast
 withChildren:(NSArray<WRAST *> *)children {
  WRTerminal *terminal = ast.terminal;

  switch (terminal.terminalType) {
    case tokenTypeOr: {
      // or
      [children[0] accept:self];
      [children[1] accept:self];
      WRExpression *expression1 = pop();
      WRExpression *expression2 = pop();
      WRExpression *expression = newExpression(self.newState, self.newState);
      newTransition(WRRETransitionTypeEpsilon, -1, expression.start, expression1.start);
      newTransition(WRRETransitionTypeEpsilon, -1, expression.start, expression2.start);
      newTransition(WRRETransitionTypeEpsilon, -1, expression1.end, expression.end);
      newTransition(WRRETransitionTypeEpsilon, -1, expression2.end, expression.end);
      push(expression);
      break;
    }
    case tokenTypeChar:
    case tokenTypeCharList: {
      // char
      WRCharTerminal *charTerminal = (WRCharTerminal *) terminal;
      WRREState *state1 = self.newState;
      WRREState *state2 = self.newState;
      for (NSNumber *index in charTerminal.rangeIndexes) {
        newTransition(WRRETransitionTypeNormal, index.intValue, state1, state2);
      }
      [self.stack addObject:newExpression(state1, state2)];
      break;
    }
    case tokenTypePlus: {
      // +
      [children[0] accept:self];
      WRExpression *expression1 = self.stack.lastObject;
      newTransition(WRRETransitionTypeEpsilon, -1, expression1.end, expression1.start);
      break;
    }
    case tokenTypeAsterisk: {
      // *
      [children[0] accept:self];
      WRREState *state1 = self.newState;
      WRREState *state2 = self.newState;
      WRExpression *expression1 = pop();
      newTransition(WRRETransitionTypeEpsilon, -1, state1, state2);
      newTransition(WRRETransitionTypeEpsilon, -1, state2, expression1.start);
      newTransition(WRRETransitionTypeEpsilon, -1, expression1.end, state1);
      [self.stack addObject:newExpression(state1, state2)];
      break;
    }
    case tokenTypeQues: {
      // ?
      [children[0] accept:self];
      WRREState *state1 = self.newState;
      WRREState *state2 = self.newState;
      WRExpression *expression1 = pop();
      newTransition(WRRETransitionTypeEpsilon, -1, state1, state2);
      newTransition(WRRETransitionTypeEpsilon, -1, state1, expression1.start);
      newTransition(WRRETransitionTypeEpsilon, -1, expression1.end, state2);
      [self.stack addObject:newExpression(state1, state2)];
      break;
    }
    case tokenTypeCancatenate: {
      // cat
      [children[0] accept:self];
      [children[1] accept:self];
      // notice expression 1 is the latter one
      WRExpression *expression1 = pop();
      WRExpression *expression2 = pop();
      newTransition(WRRETransitionTypeEpsilon, -1, expression2.end, expression1.start);
      [self.stack addObject:newExpression(expression2.start, expression1.end)];
      break;
    }
    default:assert(NO);
      break;
  }
}

- (void)epsilonNFA2NFA {
  _stateId = 0;
  // find all valid states
  NSInteger startStateId = self.epsilonNFAStart.stateId;
  NSMutableArray <WRREState *> *availableStates = [NSMutableArray arrayWithObject:self.epsilonNFAStart];
  for (WRREState *state in self.allStates) {
    if (state.stateId != startStateId) {
      // at least one of the from transition is non-epsilon
      for (WRRETransition *transition in state.fromTransitionList) {
        if (transition.type != WRRETransitionTypeEpsilon) {
          [availableStates addObject:state];
          break;
        }
      }
    }
  }

  // move the valid transitions from the epsilon closure to the valid state of which
  NSMutableArray <WRRETransition *> *availableTransitions = [NSMutableArray array];
  NSMutableArray <WRREState *> *todoStates = [NSMutableArray array];
  NSMutableSet <WRREState *> *epsilonSet = [NSMutableSet set];
  WRREState *currentState = nil;
  for (WRREState *state in availableStates) {
    // find epsilon closure and label the transition to the valid state
    NSUInteger finialId = state.finalId;
    [todoStates removeAllObjects];
    [todoStates addObject:state];
    while (todoStates.count) {
      currentState = todoStates.lastObject;
      [todoStates removeLastObject];
      for (WRRETransition *transition in currentState.toTransitionList) {
        switch (transition.type) {
          case WRRETransitionTypeEpsilon: {
            WRREState *targetState = transition.target;
            if (![epsilonSet containsObject:targetState]) {
              if (targetState.finalId) {
                finialId = targetState.finalId;
              }
              [epsilonSet addObject:targetState];
              [todoStates addObject:targetState];
            }
            break;
          }
          case WRRETransitionTypeNormal: {
            [availableTransitions addObject:transition];
            break;
          }
          default:break;
        }
      }
    }

    // ########
    state.finalId = finialId; // should be evaluated
    // ########

    // add available transitions to the valid state
    [state.toTransitionList removeAllObjects];
    for (WRRETransition *transition in availableTransitions) {
      transition.source = state;
      [state.toTransitionList addObject:transition];
    }
    [availableTransitions removeAllObjects];
    [epsilonSet removeAllObjects];
  }
  NSMutableArray *allEpsilonNFAStates = self.allStates;
  [allEpsilonNFAStates removeAllObjects];
  self.allStates = availableStates;
}

- (void)NFA2DFA {
//  _stateId = 0;
  _allDFAStates = [NSMutableArray array];
  NSMutableSet <WRREDFAState *> *recordSet = [NSMutableSet set];
  NSMutableSet <WRREState *> *NFASet = [NSMutableSet set];
  NSMutableArray <WRREDFAState *> *workList = [NSMutableArray array];
  NSMutableDictionary <NSNumber *, NSMutableArray <WRREState *> *> *transitionDict = [NSMutableDictionary dictionary];

  _DFAStart = [[WRREDFAState alloc] initWithSortedStates:@[_NFAStart]];
  [_allDFAStates addObject:_DFAStart];
  [recordSet addObject:_DFAStart];
  [workList addObject:_DFAStart];

  while (workList.count) {
    WRREDFAState *todoState = workList.lastObject;
    [workList removeLastObject];
    [transitionDict removeAllObjects];
    for (WRREState *nfaState in todoState.sortedStates) {
      // reset
      [NFASet removeAllObjects];
      // dispose final id
      if (nfaState.finalId) {
        todoState.finalId = nfaState.finalId;
      }
      // construct transition table dict
      for (WRRETransition *transition in nfaState.toTransitionList) {
        // TODO currently testing normal is redundant
        if (transition.type == WRLR0NFATransitionTypeNormal) {
          NSMutableArray *array = transitionDict[@(transition.index)];
          if (nil == array) {
            array = [NSMutableArray arrayWithObject:transition.target];
            [transitionDict setObject:array
                               forKey:@(transition.index)];
          } else {
            if (![NFASet containsObject:transition.target]) {
              [array addObject:transition.target];
              [NFASet addObject:transition.target];
            }
          }
        }
      }
    }
    for (NSNumber *index in transitionDict.allKeys) {
      // notice that the char range is not copied here
      NSMutableArray *array = transitionDict[index];
      [array sortUsingComparator:^NSComparisonResult(WRREState *state1, WRREState *state2) {
        return state1.stateId - state2.stateId;
      }];
      WRREDFAState *state = [[WRREDFAState alloc] initWithSortedStates:array];
      WRREDFAState *recordState = [recordSet member:state];
      if (nil == recordState) {
        recordState = state;
        [recordSet addObject:recordState];
        [_allDFAStates addObject:recordState];
        [workList addObject:recordState];
      }
      newTransition(WRRETransitionTypeNormal, index.unsignedCharValue, todoState, recordState);
    }
  }

  // post dispose
  // malloc two-dim array
  // TODO

  NSUInteger n = self.allDFAStates.count;
  NSUInteger m = self.mapper.normalizedRanges.count;

  self->dfaTable = (int **) malloc(sizeof(int *) * n);
  for (NSUInteger i = 0; i < n; i++) {
    self->dfaTable[i] = (int *) malloc(sizeof(int) * m);
    memset(self->dfaTable[i], -1, sizeof(int) * m);
  }

  _stateId = 0;
  for (WRREDFAState *state in self.allDFAStates) {
    [state trimWithStateId:_stateId++];
  }
  NSUInteger i = 0;
  for (WRREDFAState *state in self.allDFAStates) {
    for (WRRETransition *transition in state.toTransitionList) {
      assert(transition.index < m);
      // i < n
      self->dfaTable[i][transition.index] = (int) transition.target.stateId;
    }
    i++;
  }
}

- (void)dealloc {
  if (self.allDFAStates.count) {
    // free dfa table
    for (NSUInteger i = 0; i < self.allDFAStates.count; i++) {
      free(self->dfaTable[i]);
    }
    free(self->dfaTable);
  }
}

- (void)DFACompress {

}

#pragma mark -print
- (void)printNFA {

}

- (void)printDFA {
  // print all states and transitions
  for (WRREDFAState *state in self.allDFAStates) {
    printf("DFASTATE:%d\n", (int) state.stateId);
    for (WRRETransition *transition in state.toTransitionList) {
      NSString *content =
        [NSString stringWithFormat:@"  --%d,%@--> %d\n",
                                   transition.index,
                                   self.mapper.normalizedRanges[transition.index],
                                   (int) transition.target.stateId];
      printf("%s", content.UTF8String);
    }
  }
  printf("\n");

  // transition table
  NSUInteger n = self.allDFAStates.count;
  NSUInteger m = self.mapper.normalizedRanges.count;

  // header for normalized range indexex
  printf("%4s", " ");
  for (NSUInteger i = 0; i < m; i++) {
    printf("%4ld", (unsigned long) i);
  }
  printf("\n");

  for (NSUInteger i = 0; i < n; i++) {
    printf("%4ld", (unsigned long) i);
    for (NSUInteger j = 0; j < m; j++) {
      printf("%4ld", (long) self->dfaTable[i][j]);
    }
    printf("\n");
  }
}
@end
