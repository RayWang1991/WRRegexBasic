/**
 * Copyright (c) 2017, Ray Wang
 * All rights reserved
 * Author: RayWang
 */

#import <Foundation/Foundation.h>
#import "WRRegexLib.h"

void testCharRange();
void rangeContentExam(WRCharRange *range,unsigned char start, unsigned char end);
void testCharRangeSetAlgorithm();

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    testCharRange();
    testCharRangeSetAlgorithm();
  }
  return 0;
}

void testCharRange() {
  // hash test
  WRCharRange *range1 = [[WRCharRange alloc] initWithStart:'a'
                                                    andEnd:'v'];
  WRCharRange *range2 = [[WRCharRange alloc] initWithStart:'a'
                                                    andEnd:'v'];
  NSMutableSet<WRCharRange*> *set = [NSMutableSet set];
  [set addObject:range1];
  assert(set.count == 1);
  [set addObject:range2];
  assert(set.count == 1);
  assert([range1 isEqual:range2]);
  assert(range1 != range2);
  
  range1 = [[WRCharRange alloc]initWithStart:'\0' andEnd:'\0'];
  range2 = [[WRCharRange alloc]initWithChar:'\0'];
  assert([range1 isEqual:range2]);
  assert(range1 != range2);
}


void testCharRangeSetAlgorithm() {
  WRCharRange *range1 = [[WRCharRange alloc] initWithStart:0
                                                    andEnd:2];
  WRCharRange *range2 = [[WRCharRange alloc] initWithStart:3
                                                    andEnd:4];
  WRNormalizeCharRangeSetAlgorithm *al = [[WRNormalizeCharRangeSetAlgorithm alloc]initWithRanges:@[range1,range2]];
  rangeContentExam(al.normalizedRanges[0], 0, 2);
  rangeContentExam(al.normalizedRanges[1], 3, 4);
  
  WRCharRange *range3 = [[WRCharRange alloc]initWithStart:1
                                                   andEnd:7];
  WRNormalizeCharRangeSetAlgorithm *al1 = [[WRNormalizeCharRangeSetAlgorithm alloc]initWithRanges:@[range1,range2,range3]];
  assert(al1.normalizedRanges.count == 4);
  rangeContentExam(al1.normalizedRanges[0], 0, 0);
  rangeContentExam(al1.normalizedRanges[1], 1, 2);
  rangeContentExam(al1.normalizedRanges[2], 3, 4);
  rangeContentExam(al1.normalizedRanges[3], 5, 7);
  
  WRCharRange *range4 = [[WRCharRange alloc]initWithStart:7
                                                   andEnd:7];
  WRNormalizeCharRangeSetAlgorithm *al2 = [[WRNormalizeCharRangeSetAlgorithm alloc]initWithRanges:@[range4,range3]];
  assert(al2.normalizedRanges.count == 2);
  rangeContentExam(al2.normalizedRanges[0], 1, 6);
  rangeContentExam(al2.normalizedRanges[1], 7, 7);
  
  WRCharRange *range5 = [[WRCharRange alloc]initWithStart:6
                                                   andEnd:10];
  WRNormalizeCharRangeSetAlgorithm *al3 = [[WRNormalizeCharRangeSetAlgorithm alloc]initWithRanges:@[range5,range2,range1]];
  assert(al3.normalizedRanges.count == 3);
  rangeContentExam(al3.normalizedRanges[0], 0, 2);
  rangeContentExam(al3.normalizedRanges[1], 3, 4);
  rangeContentExam(al3.normalizedRanges[2], 6, 10);
  
  
  WRNormalizeCharRangeSetAlgorithm *al4 = [[WRNormalizeCharRangeSetAlgorithm alloc]initWithRanges:@[range1,range5,range2]];
  assert(al4.normalizedRanges.count == 3);
  rangeContentExam(al4.normalizedRanges[0], 0, 2);
  rangeContentExam(al4.normalizedRanges[1], 3, 4);
  rangeContentExam(al4.normalizedRanges[2], 6, 10);
  }

void rangeContentExam(WRCharRange *range,unsigned char start, unsigned char end){
  assert(range.start == start && range.end == end);
}
