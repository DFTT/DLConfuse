//
//  FileItem.h
//  DLConfuse
//
//  Created by 大大东 on 2019/3/25.
//  Copyright © 2019 大大东. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FileType) {
    FileIsSwift,     // swift
    FileIsOnlyH,     // H
    FileIsOnlyM,     // M
    FileIsPCH,       // PCH
    FileIsHAndM,     // H & M
    FileIsXIB,     // xib
    FileIsStoryBoard,     // storyboard
};


@interface FileItem : NSObject

@property (nonatomic, assign) FileType type;
@property (nonatomic, copy) NSString *fileName;              // 没后缀
@property (nonatomic, copy) NSString *parentDirectoryABSPath;// 父目录

- (NSArray<NSString *> *)absFilesPath;


// 新名字
@property (nonatomic, copy, nullable) NSString *reFileName;
@end



NS_ASSUME_NONNULL_END
