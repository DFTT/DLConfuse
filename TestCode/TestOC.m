//
//  TestOC.m
//  DLConfuse
//
//  Created by 大大东 on 2022/4/25.
//  Copyright © 2022 大大东. All rights reserved.
//

#import "TestOC.h"
#import "HardStringEncryptDecryptUnit.h"

@implementation TestOC
- (void)aaaa {
    NSString *aa = (@"123\\n456");
    NSString *bb = (@"321\n654");
}

- (void)bbbbbb {
    NSString *nnn = [@"你好吗\"先生" stringByAppendingString:@" 当然好啦"];
    NSString *nn1 = @"你好吗\"先生2\"";
}
@end

@interface TestOC2: NSObject
@end
@implementation TestOC2
@end

@interface TestOC2 (C222)
@end
@implementation TestOC2 (C222)
@end

@interface TestOC2(C333)
@end
@implementation TestOC2(C333)
@end
