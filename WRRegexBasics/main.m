/**
 * Copyright (c) 2017, Ray Wang
 * All rights reserved
 * Author: RayWang
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WRRegexLib.h"
#import "WRREState.h"

void example();

void showResult(NSString *regex,
                NSString *input,
                BOOL res,
                WRRegexScanner *scanner,
                WRLR1Parser *parser,
                WRLanguage *language);

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    example();
  }
  return 0;
}

void example(){
  // parser generator
  WRLR1Parser *parser = [[WRLR1Parser alloc] init];
  WRLanguage *language = [[WRRegexLanguage alloc] init];
  WRRegexScanner *scanner = [[WRRegexScanner alloc] init];
  parser.language = language;
  parser.scanner = scanner;
  [parser prepare];
  
//  showResult(@"1", @"1", YES, scanner, parser, language);
//  showResult(@"1", @"0", NO, scanner, parser, language);
//  showResult(@"1*1+1?", @"1", YES, scanner, parser, language);
//  //
//  showResult(@"\\!1*1+1?", @"1", NO, scanner, parser, language);
//  showResult(@"1*1+1?\\|0", @"0", YES, scanner, parser, language);
//  showResult(@"1*1+1?\\&0", @"0", NO, scanner, parser, language);
//  //
//  showResult(@".*111.*\\&\\!.*00.*", @"111", YES, scanner, parser, language);
//  showResult(@".*111.*\\&\\!.*00.*", @"111011", YES, scanner, parser, language);
//  showResult(@".*111.*\\&\\!.*00.*", @"000111", NO, scanner, parser, language);
//  showResult(@".*111.*\\&\\!.*00.*", @"11011011011", NO, scanner, parser, language);
//  showResult(@".*111.*\\&\\!.*00.*", @"110110110111", YES, scanner, parser, language);
  
  showResult(@"(0|1)*111(0|1)*", @"111", YES, scanner, parser, language);
  showResult(@"(0|1)*00(0|1)*", @"00", YES, scanner, parser, language);
  showResult(@"(0|1)*111[01]*\\&\\![01]*00[01]*", @"110110110111", YES, scanner, parser, language);
  
  
//  showResult(@"[a-zA-Z0-9]+@.*(com|cn|edu)", @"raywang@bongmi.com", YES, scanner, parser, language);
//  showResult(@"(\\+86)?(15|13|17)\\d+", @"+8615068173902", YES, scanner, parser, language);
//  showResult(@"[0369]*(([147][0369]*|[258][0369]*[258][0369]*)([147][0369]*[258][0369]*)*([258][0369]*|[147][0369]*[147][0369]*)|[258][0369]*[147][0369]*)*", @"3366993333", YES, scanner, parser, language);
}

void showResult(NSString *regex,
                NSString *input,
                BOOL res,
                WRRegexScanner *scanner,
                WRLR1Parser *parser,
                WRLanguage *language) {
  scanner.inputStr = regex;
  [parser startParsing];
  WRAST *ast = [language astNodeForToken:parser.parseTree];
  WRCharRangeNormalizeMapper *mapper = [[WRCharRangeNormalizeMapper alloc] initWithRanges:scanner.ranges];
  
  for (WRCharTerminal *charTerminal in scanner.charTerminals) {
    charTerminal.rangeIndexes = [mapper decomposeRangeList:charTerminal.ranges];
  };
  
  WRTreeHorizontalDashStylePrinter *hdPrinter = [[WRTreeHorizontalDashStylePrinter alloc]init];
  [ast accept:hdPrinter];
  [hdPrinter print];
  
  WRREFAManager *manager = [[WRREFAManager alloc] initWithCharRangeMapper:mapper
                                                                      ast:ast];
  
  WRREFABuilder *builder = manager.builder;
  [builder printDFA];
  assert([builder matchWithString:input] == res);
  [builder DFA2Regex];
}
