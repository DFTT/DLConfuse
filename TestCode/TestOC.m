//
//  TestOC.m
//  DLConfuse
//
//  Created by 大大东 on 2022/4/25.
//  Copyright © 2022 大大东. All rights reserved.
//

#import "TestOC.h"

// 标识字符串
#define FlAG_ENCODE_STRING(str) str


@implementation TestOC
- (void)aaaa {
    FlAG_ENCODE_STRING(@"123\\n456");
    FlAG_ENCODE_STRING(@"321\n654");
}
    
@end
