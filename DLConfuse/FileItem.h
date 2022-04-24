//
//  FileItem.h
//  DLConfuse
//
//  Created by 大大东 on 2019/3/25.
//  Copyright © 2019 大大东. All rights reserved.
//

#import <Foundation/Foundation.h>

//NS_ASSUME_NONNULL_BEGIN

@interface FileItem : NSObject

@property (nonatomic, copy) NSString *fileName;              // 没后缀
@property (nonatomic, copy) NSString *parentDirectoryABSPath;// 父目录

// 同目录没有对应m文件
@property (nonatomic, assign) BOOL onlyHFile;

@property (nonatomic, assign) BOOL isSwift;
// .h
- (NSString *)abs_h_FilePath;
// .m
- (NSString *)abs_m_FilePath;
// .swift
- (NSString *)abs_swift_FilePath;
@end



//NS_ASSUME_NONNULL_END
