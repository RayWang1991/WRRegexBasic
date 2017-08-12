/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRegexWriter.h"
#import "WRRERegexCarrier.h"
#import "WRCharRange.h"

@interface WRRegexWriter ()
@property (nonatomic, strong, readwrite) NSMutableString *result;
@end

@implementation WRRegexWriter

- (instancetype)init {
  if (self = [super init]) {
    _result = [NSMutableString string];
  }
  return self;
}

- (void)reset {
  [_result deleteCharactersInRange:NSMakeRange(0, _result.length)];
}

- (void)print {
  printf("%s\n", self.result.UTF8String);
}

- (void)visit:(WRRERegexCarrier *)carrier
 withChildren:(NSArray<WRRERegexCarrier *> *)children {
  switch (carrier.type) {
    case WRRERegexCarrierTypeNoWay: {
      [_result appendString:@"Ø"];
      break;
    }
    case WRRERegexCarrierTypeEpsilon: {
      [_result appendString:@"ε"];
      break;
    }
    case WRRERegexCarrierTypeSingle: {
      [_result appendString:((WRRERegexCarrierSingle *) carrier).charRange.description];
      break;
    }
    case WRRERegexCarrierTypeClosure: {
      WRRERegexCarrierClosure *closure = carrier;
      [closure.child accept:self];
      [_result appendString:@"*"];
      break;
    }
    case WRRERegexCarrierTypeConcatenate: {
      WRRERegexCarrierConcatenate *concatenate = carrier;
      [_result appendString:@"("];
      for (WRRERegexCarrier *child in concatenate.children) {
        [child accept:self];
      }
      [_result appendString:@")"];
    }
    case WRRERegexCarrierTypeOr: {
      WRRERegexCarrierOr *or = carrier;
      [_result appendString:@"("];
      BOOL show = NO;
      for (WRRERegexCarrier *child in or.children) {
        if (show) {
          [_result appendString:@"|"];
        } else {
          show = YES;
        }
        [child accept:self];
      }
      [_result appendString:@")"];
    }
    default:break;
  }
}
@end
