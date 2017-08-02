/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import <Foundation/Foundation.h>
#import "WRParsingBasicLib.h"
#import "WRCharRange.h"

extern NSString const *kWRRegexScannerErrorDomain;

typedef NS_ENUM(NSInteger, WRRegexScannerErrorType) {
  WRRegexScannerEpsilonCharRange,
  WRRegexScannerEndInCharSet,
  WRRegexScannerEndInCharSetOneChar,
  WRRegexScannerEndInCharSetInRange,
  WRRegexScannerEndInSlash,
};

@interface WRCharTerminal : WRTerminal
@property(nonatomic, strong, readwrite)NSArray<WRCharRange *>*ranges;
- (instancetype)initWithRanges:(NSArray <WRCharRange *>*)ranges;
@end

@interface WRRegexScanner : WRScanner

- (void)startScan;

- (void)reset;

- (WRTerminal *)nextToken;

- (void)scanToEnd;

@end
