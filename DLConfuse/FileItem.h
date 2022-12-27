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
    FileIsXIB,       // xib
    FileIsStoryBoard,     // storyboard
};

@interface OtherClassNameItem : NSObject
@property (nonatomic, copy) NSString *className;
// 新名字 (这个不为nil 就会修改)
@property (nonatomic, copy, nullable) NSString *reClassName;
+ (instancetype)itemWithClassName:(NSString *)clsname;
@end


@interface FileItem : NSObject

@property (nonatomic, assign) FileType type;
@property (nonatomic, copy) NSString *fileName;              // 没后缀 (原始文件名)
@property (nonatomic, copy) NSString *parentDirectoryABSPath;// 父目录

- (NSArray<NSString *> *)absFilesPath;


// 新文件名 (这个不为nil 就会修改其文件名)
@property (nonatomic, copy, nullable) NSString *reFileName;

// 当前文件中 匹配出的其它class name, 不包含原始文件名
@property (nonatomic, strong) NSArray<OtherClassNameItem *> *otherClassItems;
@end



NS_ASSUME_NONNULL_END
