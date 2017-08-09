/**
 * Copyright (c) 2017, Bongmi
 * All rights reserved
 * Author: wangrui@bongmi.com
 */

#import "WRRegexWriter.h"
#import "WRRERegexCarrier.h"

@interface WRRegexWriter ()
@property (nonatomic, strong, readwrite)NSMutableString *result;
@end

@implementation WRRegexWriter
- (void)visit:(WRRERegexCarrier *)carrier
 withChildren:(NSArray<WRRERegexCarrier *> *)children{

}
@end