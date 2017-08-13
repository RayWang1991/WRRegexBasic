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

#import "WRRERegexCarrier.h"
#import "WRRegexWriter.h"

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
          [state.fromTransitionList removeAllObjects];
          // remove the from-list of all available states, in order to remap them later
          // this will not dealloc the corresponding transitions due to they are held by the to-lists
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
    state.finalId = finialId; // should be evaluated, attention !!!
    // ########

    // add available transitions to the valid state
    [state.toTransitionList removeAllObjects];
    for (WRRETransition *transition in availableTransitions) {
      newTransition(WRRETransitionTypeNormal, transition.index, state, transition.target);
    }
    [availableTransitions removeAllObjects];
    [epsilonSet removeAllObjects];
  }
  NSMutableArray *allEpsilonNFAStates = self.allStates;
  [allEpsilonNFAStates removeAllObjects];
  self.allStates = availableStates;

  _NFAStart = self.epsilonNFAStart;
}

#pragma mark NFA to DFA

- (void)NFA2DFA {
  [self NFA2DFA_no_compress];
//  [self NFA2DFA_compress];
}

- (void)NFA2DFA_no_compress {
  // Do not compress the DFA states
  _allDFAStates = [NSMutableArray array];
  NSMutableSet <WRREDFAState *> *recordSet = [NSMutableSet set];
  NSMutableArray <WRREDFAState *> *workList = [NSMutableArray array];
  NSMutableDictionary <NSNumber *, NSMutableSet <WRREState *> *> *transitionDict = [NSMutableDictionary dictionary];

  _DFAStart = [[WRREDFAState alloc] initWithSortedStates:@[self.NFAStart]];
  [_allDFAStates addObject:_DFAStart];
  [recordSet addObject:_DFAStart];
  [workList addObject:_DFAStart];

  while (workList.count) {
    WRREDFAState *todoState = workList.lastObject;
    [workList removeLastObject];
    [transitionDict removeAllObjects];
    for (WRREState *nfaState in todoState.sortedStates) {
      // dispose final id
      if (nfaState.finalId) {
        todoState.finalId = nfaState.finalId;
      }
      // construct transition table dict
      for (WRRETransition *transition in nfaState.toTransitionList) {
        // TODO currently testing normal is redundant
        if (transition.type == WRLR0NFATransitionTypeNormal) {
          NSMutableSet *set = transitionDict[@(transition.index)];
          if (nil == set) {
            set = [NSMutableSet setWithObject:transition.target];
            [transitionDict setObject:set
                               forKey:@(transition.index)];
          } else {
            if (![set containsObject:transition.target]) {
              [set addObject:transition.target];
            }
          }
        }
      }
    }
    for (NSNumber *index in transitionDict.allKeys) {
      // notice that the char range is not copied here
      NSMutableSet *set = transitionDict[index];
      NSArray *array =
        [set.allObjects sortedArrayUsingComparator:[WRREFABuilder stateComparator]];

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

  [self clearDFATalbe];

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

//TODO
// failed due to from list is not the right one
- (void)NFA2DFA_compress {
  // reachable( subset( reverse( reachable( subset( reverse( nfa)))))
  // Brzozowski's Algorithm

  _allDFAStates = [NSMutableArray array];
  NSMutableSet <WRREDFAState *> *recordSet = [NSMutableSet set];
  NSMutableArray <WRREDFAState *> *workList = [NSMutableArray array];
  NSMutableDictionary <NSNumber *, NSMutableSet <WRREState *> *> *transitionDict = [NSMutableDictionary dictionary];

  NSMutableArray <WRREDFAState *> *reverseDFAStates = [NSMutableArray array];

  // run subset in reverse order
  // here we use final states as the start
  NSMutableArray *startArray = [NSMutableArray array];
  NSUInteger fa = 0;
  for (WRREState *state in self.allStates) {
    if (state.finalId) {
      [startArray addObject:state];
      fa = state.finalId;
    }
  }

  [startArray sortUsingComparator:[WRREFABuilder stateComparator]];
  WRREDFAState *reverseStart = [[WRREDFAState alloc] initWithSortedStates:startArray];
  reverseStart.finalId = fa;
  [reverseDFAStates addObject:reverseStart];
  [recordSet addObject:reverseStart];
  [workList addObject:reverseStart];

  // the real start state must be itself
  while (workList.count) {
    WRREDFAState *todoState = workList.lastObject;
    [workList removeLastObject];
    [transitionDict removeAllObjects];
    for (WRREState *nfaState in todoState.sortedStates) {
      // dispose final id
      for (WRRETransition *transition in nfaState.fromTransitionList) {
        if (transition.type == WRLR0NFATransitionTypeNormal) {
          NSMutableSet *set = transitionDict[@(transition.index)];
          if (nil == set) {
            set = [NSMutableSet setWithObject:transition.source];
            [transitionDict setObject:set
                               forKey:@(transition.index)];
          } else {
            if (![set containsObject:transition.source]) {
              [set addObject:transition.source];
            }
          }
        }
      }
    }

    for (NSNumber *index in transitionDict.allKeys) {
      // notice that the char range is not copied here
      NSMutableSet *set = transitionDict[index];
      NSArray *array =
        [set.allObjects sortedArrayUsingComparator:[WRREFABuilder stateComparator]];

      WRREDFAState *state = [[WRREDFAState alloc] initWithSortedStates:array];
      WRREDFAState *recordState = [recordSet member:state];
      if (nil == recordState) {
        recordState = state;
        [recordSet addObject:recordState];
        [reverseDFAStates addObject:recordState];
        [workList addObject:recordState];
      }
      newTransition(WRRETransitionTypeNormal, index.unsignedCharValue, recordState, todoState);
    }
  }

  // find the DFA start first, then trim
  WRREDFAState *dfaStart = [[WRREDFAState alloc] initWithSortedStates:@[self.NFAStart]];
  dfaStart = [recordSet member:dfaStart];
  assert(dfaStart);

  NSUInteger reverseId = 0;
  for (WRREDFAState *state in reverseDFAStates) {
    [state trimWithStateId:reverseId++];
  }

  reverseDFAStates = nil;

  // run subset in normal order
  [recordSet removeAllObjects];
  [workList removeAllObjects];

  _DFAStart = [[WRREDFAState alloc] initWithSortedStates:@[dfaStart]];
  [_allDFAStates addObject:_DFAStart];
  [recordSet addObject:_DFAStart];
  [workList addObject:_DFAStart];

  while (workList.count) {
    WRREDFAState *todoState = workList.lastObject;
    [workList removeLastObject];
    [transitionDict removeAllObjects];
    for (WRREState *nfaState in todoState.sortedStates) {
      // construct transition table dict
      for (WRRETransition *transition in nfaState.toTransitionList) {
        // TODO currently testing normal is redundant
        if (transition.type == WRLR0NFATransitionTypeNormal) {
          NSMutableSet *set = transitionDict[@(transition.index)];
          if (nil == set) {
            set = [NSMutableSet setWithObject:transition.target];
            [transitionDict setObject:set
                               forKey:@(transition.index)];
          } else {
            if (![set containsObject:transition.target]) {
              [set addObject:transition.target];
            }
          }
        }
      }
    }
    for (NSNumber *index in transitionDict.allKeys) {
      // notice that the char range is not copied here
      NSMutableSet *set = transitionDict[index];
      NSArray *array =
        [set.allObjects sortedArrayUsingComparator:[WRREFABuilder stateComparator]];

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

  // label the final state
  WRREDFAState *finalState = [[WRREDFAState alloc] initWithSortedStates:@[reverseStart]];
  finalState = [recordSet member:finalState];
  assert(finalState);
  finalState.finalId = reverseStart.finalId;

  // post dispose
  NSUInteger n = self.allDFAStates.count;
  NSUInteger m = self.mapper.normalizedRanges.count;

  [self clearDFATalbe];

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

+ (NSComparator)stateComparator {
  return ^NSComparisonResult(WRREState *state1, WRREState *state2) {
    return state1.stateId - state2.stateId;
  };
}

- (void)clearDFATalbe {
  if (self.allDFAStates.count && self->dfaTable) {
    // free dfa table
    for (NSUInteger i = 0; i < self.allDFAStates.count; i++) {
      free(self->dfaTable[i]);
    }
    free(self->dfaTable);
  }
}

- (void)dealloc {
  [self clearDFATalbe];
}

- (void)DFACompress {

}

- (void)DFA2Regex {

  // 2 dim array
  NSUInteger n = self.allDFAStates.count;
  NSUInteger m = self.mapper.normalizedRanges.count;
  NSMutableArray *finalStates = [NSMutableArray array];
  NSMutableArray *finalStateIds = [NSMutableArray array];
  for (WRREDFAState *state in self.allDFAStates) {
    if (state.finalId > 0) {
      [finalStates addObject:state];
      [finalStateIds addObject:@(state.stateId)];
    }
  }

  // array init
  NSMutableArray <NSMutableArray <WRRERegexCarrier *> *> *dp1 = [NSMutableArray arrayWithCapacity:n];
  NSMutableArray <NSMutableArray <WRRERegexCarrier *> *> *dp2 = [NSMutableArray arrayWithCapacity:n];
  NSArray *dpArray = @[dp1, dp2];

  // -1
  for (NSUInteger i = 0; i < n; i++) {
    [dp1 addObject:[NSMutableArray arrayWithCapacity:n]];
    [dp2 addObject:[NSMutableArray arrayWithCapacity:n]];
    for (NSUInteger j = 0; j < n; j++) {
      WRRERegexCarrier *carrier = [WRRERegexCarrier noWayCarrier];
      for (WRRETransition *transition in self.allDFAStates[i].toTransitionList) {
        if (transition.target.stateId == j) {
          WRRERegexCarrier *single =
            [WRRERegexCarrier singleCarrierWithCharRange:self.mapper.normalizedRanges[transition.index]];
          carrier = [carrier orWith:single];;
        }
      }
      if (i == j) {
        carrier = [carrier orWith:[WRRERegexCarrier epsilonCarrier]];
      }
      [dp1.lastObject addObject:carrier];
      [dp2.lastObject addObject:[NSNull null]]; // TODO
    }
  }

  NSMutableArray <NSMutableArray <WRRERegexCarrier *> *> *last = dp2, *current = dp1, *temp;
  // 0 - (n-2) //

  for (NSUInteger k = 0; k < n - 1; k++) {
    temp = last;
    last = current;
    current = temp;
    WRRERegexCarrier *Rkk_Star = [last[k][k] closure];
    for (NSUInteger i = 0; i < n; i++) {
      WRRERegexCarrier *Rik_kk_Star = [last[i][k] concatenateWith:Rkk_Star];
      for (NSUInteger j = 0; j < n; j++) {
        WRRERegexCarrier *Rik_kk_Star_kj = [Rik_kk_Star concatenateWith:last[k][j]];
        current[i][j] = [last[i][j] orWith:Rik_kk_Star_kj];
      }
    }
  }

  // n -1
  WRRERegexCarrier *result = nil;

  temp = last;
  last = current;
  current = temp;
  NSUInteger k = n - 1, i = self.DFAStart.stateId;
  WRRERegexCarrier *Rkk_Star = [last[k][k] closure];
  WRRERegexCarrier *Rik_kk_Star = [last[i][k] concatenateWith:Rkk_Star];
  for (NSNumber *number in finalStateIds) {
    NSUInteger j = number.unsignedIntegerValue;
    WRRERegexCarrier *Rik_kk_Star_kj = [Rik_kk_Star concatenateWith:last[k][j]];
    current[i][j] = [last[i][j] orWith:Rik_kk_Star_kj];
    if (result) {
      result = [result orWith:current[i][j]];
    } else {
      result = current[i][j];
    }
  }

  // show result
  [self printCarrier:result];
  // carrier to regex string
  ;
}

- (void)printCarrier:(WRRERegexCarrier *)carrier {
  WRRegexWriter *writer = [[WRRegexWriter alloc] init];
  [carrier accept:writer];
  [writer print];
}

- (void)printR:(NSArray <NSArray <WRRERegexCarrier *> *> *)rArray {
  NSUInteger i = 0, j = 0;
  for (NSArray *array in rArray) {
    printf("%lu:", i);
    j = 0;
    for (WRRERegexCarrier *carrier in array) {
      printf("%lu.", j);
      [self printCarrier:carrier];
      j++;
    }
    printf("\n");
    i++;
  }
}

#pragma mark - run automa

- (BOOL)matchWithString:(NSString *)input {
  NSInteger state = self.DFAStart.stateId;
  NSUInteger n = self.allDFAStates.count;
  for (NSUInteger i = 0; i < input.length; i++) {
    WRChar c = (WRChar) [input characterAtIndex:i];
    NSInteger cIndex = self.mapper->table[c];
    if (cIndex < 0) {
      // not in char ranges
      return NO;
    }
    NSInteger next = self->dfaTable[state][cIndex];
    if (next >= 0 && next < n) {
      state = next;
    } else {
      // not in states
      return NO;
    }
  }
  return self.allDFAStates[state].finalId > 0;
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
