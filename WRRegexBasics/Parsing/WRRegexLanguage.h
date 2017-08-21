/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"

typedef NS_ENUM(NSInteger, WRRegexTokenType) {
  tokenTypeOr = 0,
  tokenTypeCancatenate,
  tokenTypePlus,
  tokenTypeAsterisk,
  tokenTypeQues,
  tokenTypeLeftBracket,
  tokenTypeRightBracket,
  tokenTypeChar,
  tokenTypeCharList,
  tokenTypeExprOr,
  tokenTypeExprAnd,
  tokenTypeExprNot,
};

@interface WRRegexLanguage : WRLanguage
@end
