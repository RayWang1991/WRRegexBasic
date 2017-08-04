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
@property (nonatomic, strong, readwrite) NSArray<WRCharRange *> *ranges;
@property (nonatomic, strong, readwrite) NSArray<NSNumber *> *rangeIndexes;
- (instancetype)initWithRanges:(NSArray <WRCharRange *> *)ranges;
@end

@interface WRRegexScanner : WRWordScanner

- (NSArray <WRCharRange *> *)ranges;

- (NSArray <WRCharTerminal *> *)charTerminals;

- (void)startScan;

- (void)resetAll;

- (WRTerminal *)nextToken;

- (void)scanToEnd;

- (void)setNumOfEof:(NSInteger)num;

@end
