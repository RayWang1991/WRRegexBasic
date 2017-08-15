/**
 * Copyright (c) 2017, Ray Wang
 * All rights reserved
 * Author: RayWang
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WRRegexLib.h"
#import "WRREState.h"

void testParsingBasicLib();

void testFileManager();

void testState();

void testLanguage();

void testScanner();
void examToken(WRTerminal *terminal, WRRegexTokenType type, NSArray <WRCharRange *> *rangeList);

void testMapper();

void testCharRange();
void examRangeContent(WRCharRange *range, WRChar start, WRChar end);

void testCharRangeSetAlgorithm();

void testFABuilder();
void examDFAMatch(NSString *regex, NSString *input, BOOL res, WRRegexScanner *scanner, WRLR1Parser *parser,WRLanguage *language);
void examNegation(NSString *regex, NSString *input, WRRegexScanner *scanner, WRLR1Parser *parser, WRLanguage *language);

void testRegexWriter();

int main(int argc, const char *argv[]) {
  @autoreleasepool {
//    testCharRange();
//    testCharRangeSetAlgorithm();
//    testLanguage();
//    testScanner();
//    testState ();
//    testMapper();
//    testFileManager();
    testFABuilder();
//    testRegexWriter();
  }
  return 0;
}

void testFileManager() {
  NSFileManager *manager = [NSFileManager defaultManager];
  NSFileHandle *handle = [NSFileHandle fileHandleWithStandardInput];
  NSData *data = nil;
  printf("Please write your name:\n");
  while(true){
    if((data = handle.availableData)){
      NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
      if([str characterAtIndex:str.length - 1] == '\n'){
        printf("Hello, %s",[str substringToIndex:str.length - 1].UTF8String);
      }
    }
  }
}

void testState() {
  WRREState *state1 = [[WRREState alloc] initWithStateId:0];
  WRREState *state2 = [[WRREState alloc] initWithStateId:0];
  NSMutableSet <WRREState *>* set = [NSMutableSet set];
  [set addObject:state1];
  [set addObject:state2];
  assert(set.count == 1);

  state1.stateId = 0;
  state2.stateId = 131;
  WRREState *state3 = [[WRREState alloc] initWithStateId:1];
  WRREState *state4 = [[WRREState alloc] initWithStateId:0];

  WRREDFAState *dfaState1 = [[WRREDFAState alloc] initWithSortedStates:@[state1,state2]];
  WRREDFAState *dfaState2 = [[WRREDFAState alloc] initWithSortedStates:@[state3,state4]];

  NSMutableSet <WRREDFAState *> *dfaSet = [NSMutableSet set];
  [dfaSet addObject:dfaState1];
  [dfaSet addObject:dfaState2];
  ;
}

void testLanguage() {
  WRLR1Parser *parser = [[WRLR1Parser alloc] init];
  WRWordScanner *scanner = [[WRWordScanner alloc] init];
  WRLanguage *language = [[WRRegexLanguage alloc] init];
  scanner.inputStr = @"char ( char or char * )";
  //  WRLanguage *language = [WRRELanguage CFGrammar7_19];
  //  scanner.inputStr = @"x";
  parser.language = language;
  parser.scanner = scanner;
  [parser prepare];
  [parser startParsing];
  WRTreeHorizontalDashStylePrinter *hdPrinter = [[WRTreeHorizontalDashStylePrinter alloc] init];
  WRTreeLispStylePrinter *lispPrinter = [[WRTreeLispStylePrinter alloc] init];
  [parser.parseTree accept:hdPrinter];
  [parser.parseTree accept:lispPrinter];
  [hdPrinter print];
  [lispPrinter print];
  WRAST *ast = [language astNodeForToken:parser.parseTree];
  [hdPrinter reset];
  [lispPrinter reset];
  [ast accept:hdPrinter];
  [ast accept:lispPrinter];
  [hdPrinter print];
  [lispPrinter print];
}

void testScanner() {
  WRRegexScanner *scanner = [[WRRegexScanner alloc] init];
  // basic
  [scanner setNumOfEof:0];
  scanner.inputStr = @"ab";
  [scanner resetTokenIndex];
  [scanner startScan];
  [scanner scanToEnd];
  assert(scanner.tokens.count == 2);
  examToken(scanner.tokens[0], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:'a']]);
  examToken(scanner.tokens[1], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:'b']]);

  // escape
  [scanner setNumOfEof:0];
  scanner.inputStr = @"\\a\\b\\n\\s\\w\\d\\\\";
  [scanner resetTokenIndex];
  [scanner startScan];
  [scanner scanToEnd];
  assert(scanner.tokens.count == 7);
  examToken(scanner.tokens[0],
            tokenTypeChar,
            @[[[WRCharRange alloc]        initWithStart:'a'
                                          andEnd:'z']]);
  examToken(scanner.tokens[1],
            tokenTypeChar,
            @[[[WRCharRange alloc]        initWithStart:'b'
                                          andEnd:'b']]);
  examToken(scanner.tokens[2],
            tokenTypeChar,
            @[[[WRCharRange alloc]        initWithStart:'\n'
                                          andEnd:'\n']]);
  examToken(scanner.tokens[3], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:' '],
    [[WRCharRange alloc] initWithChar:'\t'],
    [[WRCharRange alloc] initWithChar:'\n'],
    [[WRCharRange alloc] initWithChar:'\r']]);
  examToken(scanner.tokens[4],
            tokenTypeChar,
            @[[[WRCharRange alloc]        initWithStart:'0'
                                          andEnd:'9'],
              [[WRCharRange alloc]        initWithStart:'a'
                                          andEnd:'z'],
              [[WRCharRange alloc]        initWithStart:'A'
                                          andEnd:'Z'],
            ]);
  examToken(scanner.tokens[5],
            tokenTypeChar,
            @[[[WRCharRange alloc]        initWithStart:'0'
                                          andEnd:'9']]);
  examToken(scanner.tokens[6], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:'\\']]);

  // char range test 1
  [scanner setNumOfEof:0];
  scanner.inputStr = @"[-ac-a-]";
  [scanner resetTokenIndex];
  [scanner startScan];
  [scanner scanToEnd];
  assert(scanner.tokens.count == 1);
  examToken(scanner.tokens[0], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:'-'],
    [[WRCharRange alloc] initWithChar:'a'],
    [[WRCharRange alloc] initWithStart:'c'
                                andEnd:'a'],
    [[WRCharRange alloc] initWithStart:'-'
                                andEnd:'-'],
  ]);

  // char range test 2
  [scanner setNumOfEof:0];
  scanner.inputStr = @"[acb]";
  [scanner resetTokenIndex];
  [scanner startScan];
  [scanner scanToEnd];
  assert(scanner.tokens.count == 1);
  examToken(scanner.tokens[0], tokenTypeChar,
            @[[[WRCharRange alloc] initWithChar:'a'],
              [[WRCharRange alloc] initWithChar:'c'],
              [[WRCharRange alloc]        initWithStart:'b'
                                          andEnd:'b']
            ]);
}

void testMapper() {
  WRRegexScanner *scanner = [[WRRegexScanner alloc] init];
  // basic
  [scanner setNumOfEof:0];
  scanner.inputStr = @"[a-df]h\\d";
  [scanner resetTokenIndex];
  [scanner startScan];
  [scanner scanToEnd];

  WRCharRangeNormalizeMapper *mapper =
    [[WRCharRangeNormalizeMapper alloc] initWithRanges:scanner.ranges];
  for (WRCharTerminal *charTerminal in scanner.charTerminals) {
    charTerminal.rangeIndexes = [mapper decomposeRangeList:charTerminal.ranges];
  };
}

void examToken(WRTerminal *terminal, WRRegexTokenType type, NSArray <WRCharRange *> *rangeList) {
  switch (type) {
    case tokenTypeChar: {
      WRCharTerminal *charTerminal = (WRCharTerminal *) terminal;
      assert([charTerminal.symbol isEqualToString:@"char"]);
      assert(charTerminal.ranges.count == rangeList.count);
      for (int i = 0; i < rangeList.count; i++) {
        assert([rangeList[i] isEqual:charTerminal.ranges[i]]);
      }
      break;
    }
    default:break;
  }
}

void testCharRange() {
  // hash test
  WRCharRange *range1 = [[WRCharRange alloc] initWithStart:'a'
                                                    andEnd:'v'];
  WRCharRange *range2 = [[WRCharRange alloc] initWithStart:'a'
                                                    andEnd:'v'];
  NSMutableSet<WRCharRange *> *set = [NSMutableSet set];
  [set addObject:range1];
  assert(set.count == 1);
  [set addObject:range2];
  assert(set.count == 1);
  assert([range1 isEqual:range2]);
  assert(range1 != range2);

  range1 = [[WRCharRange alloc] initWithStart:'\0'
                                       andEnd:'\0'];
  range2 = [[WRCharRange alloc] initWithChar:'\0'];
  assert([range1 isEqual:range2]);
  assert(range1 != range2);
}

void testCharRangeSetAlgorithm() {
  WRCharRange *range1 = [[WRCharRange alloc] initWithStart:0
                                                    andEnd:2];
  WRCharRange *range2 = [[WRCharRange alloc] initWithStart:3
                                                    andEnd:4];
  WRCharRangeNormalizeMapper *al = [[WRCharRangeNormalizeMapper alloc] initWithRanges:@[range1, range2]];
  examRangeContent(al.normalizedRanges[0], 0, 2);
  examRangeContent(al.normalizedRanges[1], 3, 4);

  WRCharRange *range3 = [[WRCharRange alloc] initWithStart:1
                                                    andEnd:7];
  WRCharRangeNormalizeMapper
    *al1 = [[WRCharRangeNormalizeMapper alloc] initWithRanges:@[range1, range2, range3]];
  assert(al1.normalizedRanges.count == 4);
  examRangeContent(al1.normalizedRanges[0], 0, 0);
  examRangeContent(al1.normalizedRanges[1], 1, 2);
  examRangeContent(al1.normalizedRanges[2], 3, 4);
  examRangeContent(al1.normalizedRanges[3], 5, 7);

  WRCharRange *range4 = [[WRCharRange alloc] initWithStart:7
                                                    andEnd:7];
  WRCharRangeNormalizeMapper *al2 = [[WRCharRangeNormalizeMapper alloc] initWithRanges:@[range4, range3]];
  assert(al2.normalizedRanges.count == 2);
  examRangeContent(al2.normalizedRanges[0], 1, 6);
  examRangeContent(al2.normalizedRanges[1], 7, 7);

  WRCharRange *range5 = [[WRCharRange alloc] initWithStart:6
                                                    andEnd:10];
  WRCharRangeNormalizeMapper
    *al3 = [[WRCharRangeNormalizeMapper alloc] initWithRanges:@[range5, range2, range1]];
  assert(al3.normalizedRanges.count == 3);
  examRangeContent(al3.normalizedRanges[0], 0, 2);
  examRangeContent(al3.normalizedRanges[1], 3, 4);
  examRangeContent(al3.normalizedRanges[2], 6, 10);

  WRCharRangeNormalizeMapper
    *al4 = [[WRCharRangeNormalizeMapper alloc] initWithRanges:@[range1, range5, range2]];
  assert(al4.normalizedRanges.count == 3);
  examRangeContent(al4.normalizedRanges[0], 0, 2);
  examRangeContent(al4.normalizedRanges[1], 3, 4);
  examRangeContent(al4.normalizedRanges[2], 6, 10);
}

void examRangeContent(WRCharRange *range, WRChar start, WRChar end) {
  assert(range.start == start && range.end == end);
}



void testFABuilder(){
  
  WRLR1Parser *parser = [[WRLR1Parser alloc] init];
  WRLanguage *language = [[WRRegexLanguage alloc] init];
  WRRegexScanner *scanner = [[WRRegexScanner alloc] init];
  scanner.inputStr = @"\0ab+(c|d)*";
//  scanner.inputStr = @"(a|d)*";
  parser.language = language;
  parser.scanner = scanner;
  [parser prepare];
  [parser startParsing];
  
//  [parser constructSPPF];
//  [parser constructParseTree];
  
  WRTreeHorizontalDashStylePrinter *hdPrinter = [[WRTreeHorizontalDashStylePrinter alloc] init];
  WRTreeLispStylePrinter *lispPrinter = [[WRTreeLispStylePrinter alloc] init];
  [parser.parseTree accept:hdPrinter];
  [parser.parseTree accept:lispPrinter];
  [hdPrinter print];
  [lispPrinter print];
  WRAST *ast = [language astNodeForToken:parser.parseTree];
  [hdPrinter reset];
  [lispPrinter reset];
  [ast accept:hdPrinter];
  [ast accept:lispPrinter];
  [hdPrinter print];
  [lispPrinter print];
  
  WRCharRangeNormalizeMapper *mapper = [[WRCharRangeNormalizeMapper alloc]initWithRanges:scanner.ranges];
  
  for (WRCharTerminal *charTerminal in scanner.charTerminals) {
    charTerminal.rangeIndexes = [mapper decomposeRangeList:charTerminal.ranges];
  };
  
  WRREFABuilder *builder = [[WRREFABuilder alloc]initWithCharRangeMapper:mapper
                                                                     ast:ast];
  WRREState *epsilonStart = builder.epsilonNFAStart;
  [builder epsilonNFA2NFA];
  WRREState *NFAStart = builder.NFAStart;
  [builder NFA2DFA];
  WRREDFAState *DFAStart = builder.DFAStart;
  [builder printDFA];
  
  // exam DFA match
  examDFAMatch(@"a.*b", @"aasdfsadfasdfb", YES, scanner, parser, language);
  examDFAMatch(@"a.*b", @"aasdfsadfasdf", NO, scanner, parser, language);
  examDFAMatch(@"a[c-e]?b", @"aeb", YES, scanner, parser, language);
  examDFAMatch(@"a[c-e]?b", @"ab", YES, scanner, parser, language);
  examDFAMatch(@"a[c-e]?b", @"af", NO, scanner, parser, language);
  examDFAMatch(@"(a[fh-p].*)+b?", @"aa", NO, scanner, parser, language);
  examDFAMatch(@"(a[fh-p].*)+b?", @"afapakal", YES, scanner, parser, language);
  examDFAMatch(@"\\d*", @"7676976", YES, scanner, parser, language);
  examDFAMatch(@"\\w*", @"7676976hgjhg", YES, scanner, parser, language);
  examDFAMatch(@"\\w+\\.[0-9a-z]+\\.(com|cn|edu)", @"www.123.com", YES, scanner, parser, language);
  
  // **test
  examDFAMatch(@"a***b", @"www.123.com", NO, scanner, parser, language);
  examDFAMatch(@"a***b", @"aaaaa", NO, scanner, parser, language);
  examDFAMatch(@"a***b", @"b", YES, scanner, parser, language);
  examDFAMatch(@"a***b", @"aab", YES, scanner, parser, language);
  
  // ++test
  examDFAMatch(@"a++b", @"aab", YES, scanner, parser, language);
  
  // exam negation
  examNegation(@"a.*b", @"aasdfsadfasdfb", scanner, parser, language);
  examNegation(@"a[c-e]?b", @"aeb", scanner, parser, language);
  examNegation(@"a[c-e]?b", @"ab", scanner, parser, language);
  examNegation(@"(a[fh-p].*)+b?", @"afapakal", scanner, parser, language);
  examNegation(@"\\d*", @"7676976", scanner, parser, language);
  examNegation(@"\\w*", @"7676976hgjhg", scanner, parser, language);
  examNegation(@"\\w+\\.[0-9a-z]+\\.(com|cn|edu)", @"www.123.com", scanner, parser, language);
  
  // **test
  examNegation(@"a***b", @"b", scanner, parser, language);
  examNegation(@"a***b", @"aab", scanner, parser, language);
  
  // ++test
  examNegation(@"a++b", @"aab", scanner, parser, language);
  examNegation(@"a+bc", @"aabc", scanner, parser, language);
  
  // test DFA to Regex
  [builder DFA2Regex];
  
}


void examDFAMatch(NSString *regex, NSString *input, BOOL res, WRRegexScanner *scanner, WRLR1Parser *parser,WRLanguage *language){
  scanner.inputStr = regex;
  [parser startParsing];
  WRAST *ast = [language astNodeForToken:parser.parseTree];
  WRCharRangeNormalizeMapper *mapper = [[WRCharRangeNormalizeMapper alloc]initWithRanges:scanner.ranges];
  
  for (WRCharTerminal *charTerminal in scanner.charTerminals) {
    charTerminal.rangeIndexes = [mapper decomposeRangeList:charTerminal.ranges];
  };
  
  WRREFABuilder *builder = [[WRREFABuilder alloc]initWithCharRangeMapper:mapper
                                                                     ast:ast];
  [builder epsilonNFA2NFA];
  [builder NFA2DFA];
  [builder printDFA];
  assert([builder matchWithString:input] == res);
}

void examNegation(NSString *regex, NSString *input, WRRegexScanner *scanner, WRLR1Parser *parser, WRLanguage *language){
  scanner.inputStr = regex;
  [parser startParsing];
  WRAST *ast = [language astNodeForToken:parser.parseTree];
  WRCharRangeNormalizeMapper *mapper = [[WRCharRangeNormalizeMapper alloc]initWithRanges:scanner.ranges];
  
  for (WRCharTerminal *charTerminal in scanner.charTerminals) {
    charTerminal.rangeIndexes = [mapper decomposeRangeList:charTerminal.ranges];
  };
  
  WRREFABuilder *builder = [[WRREFABuilder alloc]initWithCharRangeMapper:mapper
                                                                     ast:ast];
  [builder epsilonNFA2NFA];
  [builder NFA2DFA];
  [builder printDFA];
  assert([builder matchWithString:input] == YES);
  builder = [builder negation];
  [builder printDFA];
  assert([builder matchWithString:input] == NO);
}

void testRegexWriter(){
  WRCharRange *ca = [[WRCharRange alloc]initWithChar:'a'];
  WRCharRange *cb = [[WRCharRange alloc]initWithChar:'b'];
  WRRERegexCarrierSingle *a = [[WRRERegexCarrierSingle alloc]initWithCharRange:ca];
  WRRERegexCarrierSingle *b = [[WRRERegexCarrierSingle alloc]initWithCharRange:cb];
  WRRERegexCarrierOr *or = [WRRERegexCarrierOr orCarrierWithChildren:@[a,a]];
  WRRERegexCarrierConcatenate *cat = [WRRERegexCarrier concatenateCarrierWithChildren:@[or, b]];
  [cat print];
  ;
}
