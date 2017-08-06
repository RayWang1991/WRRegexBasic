/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRegexScanner.h"
#import "WRRegexLanguage.h"
#import "WRRegexUtils.h"

@implementation WRCharTerminal
- (instancetype)initWithRanges:(NSArray <WRCharRange *> *)ranges {
  if (self = [super initWithSymbol:@"char"]) {
    _ranges = ranges;
  }
  return self;
}

- (NSString *)debugDescription{
  return [NSString stringWithFormat:@"%@ :%@\n",self.ranges,self.rangeIndexes];
}

@end

const NSString *kWRRegexScannerErrorDomain = @"WR.Error.Regex.Scanner";

typedef NS_ENUM(NSInteger, WRRegexScannerState) {
  Begin,
  InCharSet,
  InCharSetOneChar,
  InCharSetInRange,
  InSlash,
};

//@"S -> Frag",
//@"Frag -> Frag or Seq | Seq ",
//@"Seq -> Seq Unit | Unit ",
//@"Unit -> Single | Single PostOp | ( Frag ) ",
//@"PostOp -> + | * | ? ",
//@"Single -> char | charList ",

@interface WRRegexScanner ()
@property (nonatomic, assign, readwrite) WRRegexScannerState state;
@property (nonatomic, assign, readwrite) NSInteger tokenBegin;
@property (nonatomic, assign, readwrite) NSInteger tokenLength;
@property (nonatomic, assign, readwrite) NSInteger strIndex;
// content info
@property (nonatomic, assign, readwrite) NSInteger currentColumn;
@property (nonatomic, assign, readwrite) NSInteger currentLine;
@property (nonatomic, assign, readwrite) NSInteger numOfEof;
// range list
@property (nonatomic, strong, readwrite) NSMutableArray<WRCharRange *> *rangesInternal;
@property (nonatomic, strong, readwrite) NSMutableArray<WRCharTerminal *> *charTerminalsInternal;
@property (nonatomic, assign, readwrite) WRChar charRangeStart;
@property (nonatomic, strong, readwrite) NSMutableArray<WRCharRange *> *rangeList;

@end

#define inputCharAt(x) (WRChar)[self.inputStr characterAtIndex:x]
#define newCharRange(x, y) [[WRCharRange alloc]initWithStart:x andEnd:y]
#define newCharRangeChar(x) [[WRCharRange alloc]initWithChar:x]

@implementation WRRegexScanner
#pragma mark -public
// eof num
- (void)setNumOfEof:(NSInteger)num {
  _numOfEof = num;
}

- (void)startScan {
  _state = Begin;
  _tokenBegin = 0;
  _tokenLength = 0;
  _strIndex = 0;
  self.tokenIndex = 0; // token to be return
  _currentColumn = 1;
  _currentLine = 1;
  _rangeList = [NSMutableArray array];
  _charTerminalsInternal = [NSMutableArray array];
  _rangesInternal = [NSMutableArray array];
  [self.tokens removeAllObjects];
  [self.errors removeAllObjects];
}

- (void)resetAll {
  [_rangeList removeAllObjects];
  [_rangesInternal removeAllObjects];
  [_charTerminalsInternal removeAllObjects];
  self.tokenIndex = 0;
}

- (WRTerminal *)tokenAtIndex:(NSInteger)index {
  if (index < 0 || index + 1 > self.tokens.count) {
    return nil;
  }
  return self.tokens[index];
}

- (WRTerminal *)nextToken {
  return [self tokenAtIndex:self.tokenIndex++];
}

- (NSArray <WRCharRange *> *)ranges{
  return self.rangesInternal;
}

- (NSArray <WRCharTerminal *> *)charTerminals{
  return self.charTerminalsInternal;
}

- (void)scanToEnd {
  NSInteger len = self.inputStr.length;
  WRRegexTokenType type;
  for (; _strIndex < len; _strIndex++, _currentColumn++) {
    WRChar c = inputCharAt(_strIndex);
    if (c == '\n' || c == '\r') {
      _currentLine++;
      _currentColumn = 0;
    }
    switch (_state) {
      case Begin: {
        switch (c) {
          case '.':{
            // any
            type = tokenTypeCharList;
            // notice that \0 (eof) is not included here
            [self.rangeList addObject:[[WRCharRange alloc] initWithStart:1
                                                                  andEnd:MAXLenCharRange - 1]];
            [self addTerminalWithType:type];
            break;
          }
          case '|': {
            type = tokenTypeOr;
            [self addTerminalWithType:type];
            break;
          }
          case '*': {
            type = tokenTypeAsterisk;
            [self addTerminalWithType:type];
            break;
          }
          case '+': {
            type = tokenTypePlus;
            [self addTerminalWithType:type];
            break;
          }
          case '?': {
            type = tokenTypeQues;
            [self addTerminalWithType:type];
            break;
          }
          case '(':{
            type = tokenTypeLeftBracket;
            [self addTerminalWithType:type];
            break;
          }
          case ')':{
            type = tokenTypeRightBracket;
            [self addTerminalWithType:type];
            break;
          }
          case '[': {
            _state = InCharSet;
            break;
            // look ahead for'^' should be considered
          }
          case '\\': {
            _state = InSlash;
            break;
          }
          default: {
            type = tokenTypeChar;
            [self addTerminalWithType:type];
            break;
          }
        }
        break;
      }
      case InSlash: {
        type = tokenTypeChar;
        [self addSlashChar];
        _state = Begin;
        break;
      }
      case InCharSet: {
        //right after a '['
        switch (c) {
          case ']': {
            _state = Begin;
            // actually, can be ignored
            // error
//           [self addErrorWithType:WRRegexScannerEpsilonCharRange];
            break;
          }
          case '^': {
            // reserved for negative
          }
          default: {
            // look ahead
            if (inputCharAt(_strIndex + 1) == '-') {
              _state = InCharSetInRange;
              _charRangeStart = c;
              _strIndex++;
              _currentColumn++;
            } else {
              [self.rangeList addObject:[[WRCharRange alloc] initWithChar:c]];
              _state = InCharSetOneChar;
            }
            break;
          }
        }
        break;
      }
      case InCharSetOneChar: {
        // in '[', finished match at least one valid char or char range, distinguish from '[' case '^'
        switch (c) {
          case ']': {
            [self addTerminalWithType:tokenTypeCharList];
            _state = Begin;
            break;
          }
          case '-': {
            // may be
          }
          default: {
            // look ahead
            if (inputCharAt(_strIndex + 1) == '-') {
              _state = InCharSetInRange;
              _charRangeStart = c;
              _strIndex++;
              _currentColumn++;
            } else {
              // here '-' is included
              [self.rangeList addObject:[[WRCharRange alloc] initWithChar:c]];
              _state = InCharSetOneChar;
            }
            break;
          }
        }
        break;
      }
      case InCharSetInRange: {
        switch (c) {
          case ']': {
            // may be
          }
          default: {
            // here '-' is included
            [self.rangeList addObject:[[WRCharRange alloc] initWithStart:_charRangeStart
                                                                  andEnd:c]];
            _state = InCharSetOneChar;
            break;
          }
        }
        break;
      }
    }
  }

  switch (_state) {
    case InCharSet:[self addErrorWithType:WRRegexScannerEndInCharSet];
      break;
    case InCharSetOneChar:[self addErrorWithType:WRRegexScannerEndInCharSetOneChar];
      break;
    case InCharSetInRange:[self addErrorWithType:WRRegexScannerEndInCharSetOneChar];
      break;
    case InSlash:[self addErrorWithType:WRRegexScannerEndInSlash];
      break;
    case Begin:
    default:break;
  }
  for (; _numOfEof > 0; _numOfEof--) {
    WRTerminal *token = [WRTerminal tokenWithSymbol:WREndOfFileTokenSymbol];
    WRTerminalContentInfo contentInfo = {_currentLine, _currentColumn, 0};
    token.contentInfo = contentInfo;
    [self.tokens addObject:token];
  }
}

- (void)addSlashChar {
  WRChar input = inputCharAt(_strIndex);
  WRChar c = 0;
  NSArray <WRCharRange *> *rangeList = nil;
  switch (input) {
    case 'n': {
      c = '\n';
      break;
    }
    case 't': {
      c = '\t';
      break;
    }
    case '\\': {
      c = '\\';
      break;
    }
    case 's': {
      rangeList = @[newCharRangeChar(' '),
        newCharRangeChar('\t'),
        newCharRangeChar('\n'),
        newCharRangeChar('\r')];
      break;
    }
    case 'd':
    case 'D': {
      rangeList = @[newCharRange('0', '9')
      ];
      break;
    }
    case 'w':
    case 'W': {
      rangeList = @[newCharRange('0', '9'),
        newCharRange('a', 'z'),
        newCharRange('A', 'Z'),
      ];
      break;
    }
    case 'a': {
      rangeList = @[
        newCharRange('a', 'z'),
      ];
      break;
    }
    case 'A': {
      rangeList = @[
        newCharRange('A', 'Z'),
      ];
      break;
    }
    default: {
      c = input;
      break;
    }
  }

  WRTerminalContentInfo contentInfo = {_currentLine, _currentColumn, _tokenLength};
  WRTerminal *terminal = nil;

  if (c) {
    WRCharTerminal *charTerminal = [WRCharTerminal tokenWithSymbol:@"char"];
    terminal = charTerminal;
    terminal.terminalType = tokenTypeChar;
    WRCharRange *range = newCharRangeChar(c);
    charTerminal.ranges = @[range];
    [self.charTerminalsInternal addObject:charTerminal];
    [self.rangesInternal addObject:range];
  } else {
    WRCharTerminal *charTerminal = [WRCharTerminal tokenWithSymbol:@"char"];
    terminal = charTerminal;
    terminal.terminalType = tokenTypeCharList;
    charTerminal.ranges = rangeList;
    [self.charTerminalsInternal addObject:charTerminal];
    [self.rangesInternal addObjectsFromArray:rangeList];
  }

  terminal.contentInfo = contentInfo;
  [self.tokens addObject:terminal];
}

- (void)addTerminalWithType:(WRRegexTokenType)type {
  WRTerminalContentInfo contentInfo = {_currentLine, _currentColumn, _tokenLength};
  WRTerminal *terminal = nil;
  switch (type) {
    case tokenTypeOr: {
      terminal = [WRTerminal tokenWithSymbol:@"or"];
      break;
    }
    case tokenTypePlus: {
      terminal = [WRTerminal tokenWithSymbol:@"+"];
      break;
    }
    case tokenTypeAsterisk: {
      terminal = [WRTerminal tokenWithSymbol:@"*"];
      break;
    }
    case tokenTypeQues: {
      terminal = [WRTerminal tokenWithSymbol:@"?"];
      break;
    }
    case tokenTypeLeftBracket: {
      terminal = [WRTerminal tokenWithSymbol:@"("];
      break;
    }
    case tokenTypeRightBracket: {
      terminal = [WRTerminal tokenWithSymbol:@")"];
      break;
    }
    case tokenTypeChar: {
      WRCharTerminal *charTerminal = [WRCharTerminal tokenWithSymbol:@"char"];
      terminal = charTerminal;
      WRCharRange *range = newCharRangeChar(inputCharAt(_strIndex));
      charTerminal.ranges = @[range];
      [self.charTerminalsInternal addObject:charTerminal];
      [self.rangesInternal addObject:range];
      break;
    }
    case tokenTypeCharList: {
      WRCharTerminal *charTerminal = [WRCharTerminal tokenWithSymbol:@"char"];
      terminal = charTerminal;
      charTerminal.ranges = [NSArray arrayWithArray:self.rangeList];
      [self.charTerminalsInternal addObject:charTerminal];
      [self.rangesInternal addObjectsFromArray:self.rangeList];
      [self.rangeList removeAllObjects];
      break;
    }
    default:
      // can not be
      assert(NO);
      break;
  }
  terminal.terminalType = type;
  terminal.contentInfo = contentInfo;
  [self.tokens addObject:terminal];
}

#define addTerminal(x) [self.tokens addObjcect:[self terminalWithType: x ]]

- (void)addErrorWithType:(WRRegexScannerErrorType)type {
  NSString *content;
  switch (type) {
    case WRRegexScannerEpsilonCharRange: {
      content = @"epsilon char range is forbidden\n";
      break;
    }
    case WRRegexScannerEndInCharSet: {
      content = @"please enter any character(s) and end up with a '['\n";
      break;
    }
    case WRRegexScannerEndInCharSetOneChar: {
      content = @"please complete the char set ending with a ']'\n";
      break;
    }
    case WRRegexScannerEndInCharSetInRange: {
      content = @"please complete the char range with a character, ending with a ']'\n";
      break;
    }
    case WRRegexScannerEndInSlash: {
      content = @"please enter a character after the slash '\\'\n";
      break;
    }
    default:break;
  }
  NSError *error = [NSError errorWithDomain:kWRRegexScannerErrorDomain
                                       code:type
                                   userInfo:@{@"content": content}];
  [self.errors addObject:error];
  [self printLastError];
  assert(NO);
}

- (void)printLastError {
  printf("ERROR, Lex issues: %s", [self.errors.lastObject.userInfo[@"content"] UTF8String]);
}

@end
