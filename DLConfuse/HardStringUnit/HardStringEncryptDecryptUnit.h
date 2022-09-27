//
//  HardStringEncryptDecryptUnit.h
//  DLConfuse
//
//  Created by 大大东 on 2022/9/26.
//  Copyright © 2022 大大东. All rights reserved.
//

#import <Foundation/Foundation.h>


/// 加密 (工具使用此方法生成密文)
/// 加密算法
/// 1. 生成一个[3, 8]的随机数a
/// 2. 把明文进行base64编码得到b
/// 3. 如果b的长度大于a, 则对b进行倒序插入随机字符, 插入间隔为a, 否则不处理
/// 4. 把a拼接在b的第一个字符
static inline NSString *_Nonnull XYZ_encriptHardString(NSString * _Nonnull hstring) {
    
    NSString *base64 = [[hstring dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    int intervel = arc4random() % 6 + 3; // 3 - 8
    
    NSMutableString *newstring = [base64 mutableCopy];;
    if (intervel < base64.length) {
        NSArray *arr = @[@"a", @"1", @"b", @"2", @"c", @"3", @"d", @"4", @"5", @"e", @"6", @"f", @"7", @"8", @"9"];
        
        int count = 0;
        for (NSInteger i = base64.length - 1; i >= 0 ; i--) {
            count++;
            if (count == intervel) {
                [newstring insertString:arr[arc4random() % arr.count] atIndex:i];
                count = 0;
            }
        }
    }
    [newstring insertString:[NSString stringWithFormat:@"%d", intervel] atIndex:0];
    return newstring ? : base64;
}



/// 解密 (工具把原明文字符串 替换为XYZ_decriptHardString(密文))
static inline NSString *_Nonnull XYZ_decriptHardString(NSString * _Nonnull hstring) {
    
    // 取出插入间隔
    int intervel = [[hstring substringToIndex:1] intValue];
    NSString *newString = [hstring substringFromIndex:1];
    
    // 去除插入的字符
    NSMutableString *mNewtring = nil;
    if (intervel <= newString.length) {
        mNewtring = [newString mutableCopy];
        int count = 0;
        for (NSInteger i = newString.length - 1; i >= 0 ; i--) {
            count++;
            if (count == intervel + 1) { // 这里需要加1
                [mNewtring deleteCharactersInRange:NSMakeRange(i, 1)];
                count = 0;
            }
        }
    }
    
    NSData *base64Data = [[NSData alloc] initWithBase64EncodedString:mNewtring ? : newString options:0];
    
    return [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
}
