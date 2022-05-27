//
//  FileItem.m
//  DLConfuse
//
//  Created by 大大东 on 2019/3/25.
//  Copyright © 2019 大大东. All rights reserved.
//

#import "FileItem.h"

@implementation FileItem
//
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ -> %@", _fileName, _parentDirectoryABSPath];
}


#pragma mark - M
- (NSArray<NSString *> *)absFilesPath {
    if (_type == FileIsSwift) {
        return @[[_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.swift", _fileName]]];
    }
    if (_type == FileIsOnlyH) {
        return @[[_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h", _fileName]]];
    }
    if (_type == FileIsOnlyM) {
        return @[[_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m", _fileName]]];
    }
    if (_type == FileIsHAndM) {
        return @[[_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h", _fileName]],
                 [_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m", _fileName]],
        ];
    }
    if (_type == FileIsPCH) {
        return @[[_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pch", _fileName]]];
    }
    if (_type == FileIsXIB) {
        return @[[_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xib", _fileName]]];
    }
    if (_type == FileIsStoryBoard) {
        return @[[_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.storyboard", _fileName]]];
    }
    NSAssert(NO, @"漏判断啦啦啦");
    return @[];
}
@end
