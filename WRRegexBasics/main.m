/**
 * Copyright (c) 2017, Ray Wang
 * All rights reserved
 * Author: RayWang
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WRRegexLib.h"

void testLanguage();

void testScanner();
void examToken(WRTerminal *terminal, WRRegexTokenType type, NSArray <WRCharRange *> *rangeList);

void testCharRange();
void rangeContentExam(WRCharRange *range, WRChar start, WRChar end);

void testCharRangeSetAlgorithm();

int main(int argc, const char *argv[]) {
  @autoreleasepool {
//    testCharRange();
//    testCharRangeSetAlgorithm();
//    testLanguage();
    testScanner();
  }
  return 0;
}

void testLanguage() {
  WRLR1Parser *parser = [[WRLR1Parser alloc] init];
  WRWordScanner *scanner = [[WRWordScanner alloc] init];
  WRLanguage *language = [[WRRegexLanguage alloc] init];
  scanner.inputStr = @"charList ( char or charList * )";
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
  [scanner reset];
  [scanner startScan];
  [scanner scanToEnd];
  assert(scanner.tokens.count == 2);
  examToken(scanner.tokens[0], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:'a']]);
  examToken(scanner.tokens[1], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:'b']]);

  // escape
  [scanner setNumOfEof:0];
  scanner.inputStr = @"\\a\\b\\n\\s\\w\\d\\\\";
  [scanner reset];
  [scanner startScan];
  [scanner scanToEnd];
  assert(scanner.tokens.count == 7);
  examToken(scanner.tokens[0],
            tokenTypeChar,
            @[[[WRCharRange alloc] initWithStart:'a'
                                          andEnd:'z']]);
  examToken(scanner.tokens[1],
            tokenTypeChar,
            @[[[WRCharRange alloc] initWithStart:'b'
                                          andEnd:'b']]);
  examToken(scanner.tokens[2],
            tokenTypeChar,
            @[[[WRCharRange alloc] initWithStart:'\n'
                                          andEnd:'\n']]);
  examToken(scanner.tokens[3], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:' '],
    [[WRCharRange alloc] initWithChar:'\t'],
    [[WRCharRange alloc] initWithChar:'\n'],
    [[WRCharRange alloc] initWithChar:'\r']]);
  examToken(scanner.tokens[4],
            tokenTypeChar,
            @[[[WRCharRange alloc] initWithStart:'0'
                                          andEnd:'9'],
              [[WRCharRange alloc] initWithStart:'a'
                                          andEnd:'z'],
              [[WRCharRange alloc] initWithStart:'A'
                                          andEnd:'Z'],
            ]);
  examToken(scanner.tokens[5],
            tokenTypeChar,
            @[[[WRCharRange alloc] initWithStart:'0'
                                          andEnd:'9']]);
  examToken(scanner.tokens[6], tokenTypeChar, @[[[WRCharRange alloc] initWithChar:'\\']]);

  // char range test 1
  [scanner setNumOfEof:0];
  scanner.inputStr = @"[-ac-a-]";
  [scanner reset];
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
  [scanner reset];
  [scanner startScan];
  [scanner scanToEnd];
  assert(scanner.tokens.count == 1);
  examToken(scanner.tokens[0], tokenTypeChar,
            @[[[WRCharRange alloc] initWithChar:'a'],
              [[WRCharRange alloc] initWithChar:'c'],
              [[WRCharRange alloc] initWithStart:'b'
                                          andEnd:'b']
            ]);
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
  WRCharRangeNormalizeManager *al = [[WRCharRangeNormalizeManager alloc] initWithRanges:@[range1, range2]];
  rangeContentExam(al.normalizedRanges[0], 0, 2);
  rangeContentExam(al.normalizedRanges[1], 3, 4);

  WRCharRange *range3 = [[WRCharRange alloc] initWithStart:1
                                                    andEnd:7];
  WRCharRangeNormalizeManager
    *al1 = [[WRCharRangeNormalizeManager alloc] initWithRanges:@[range1, range2, range3]];
  assert(al1.normalizedRanges.count == 4);
  rangeContentExam(al1.normalizedRanges[0], 0, 0);
  rangeContentExam(al1.normalizedRanges[1], 1, 2);
  rangeContentExam(al1.normalizedRanges[2], 3, 4);
  rangeContentExam(al1.normalizedRanges[3], 5, 7);

  WRCharRange *range4 = [[WRCharRange alloc] initWithStart:7
                                                    andEnd:7];
  WRCharRangeNormalizeManager *al2 = [[WRCharRangeNormalizeManager alloc] initWithRanges:@[range4, range3]];
  assert(al2.normalizedRanges.count == 2);
  rangeContentExam(al2.normalizedRanges[0], 1, 6);
  rangeContentExam(al2.normalizedRanges[1], 7, 7);

  WRCharRange *range5 = [[WRCharRange alloc] initWithStart:6
                                                    andEnd:10];
  WRCharRangeNormalizeManager
    *al3 = [[WRCharRangeNormalizeManager alloc] initWithRanges:@[range5, range2, range1]];
  assert(al3.normalizedRanges.count == 3);
  rangeContentExam(al3.normalizedRanges[0], 0, 2);
  rangeContentExam(al3.normalizedRanges[1], 3, 4);
  rangeContentExam(al3.normalizedRanges[2], 6, 10);

  WRCharRangeNormalizeManager
    *al4 = [[WRCharRangeNormalizeManager alloc] initWithRanges:@[range1, range5, range2]];
  assert(al4.normalizedRanges.count == 3);
  rangeContentExam(al4.normalizedRanges[0], 0, 2);
  rangeContentExam(al4.normalizedRanges[1], 3, 4);
  rangeContentExam(al4.normalizedRanges[2], 6, 10);
}

void rangeContentExam(WRCharRange *range, WRChar start, WRChar end) {
  assert(range.start == start && range.end == end);
}
