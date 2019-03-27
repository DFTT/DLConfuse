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
- (NSString *)abs_h_FilePath {
    return [_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h", _fileName]];
}

- (NSString *)abs_m_FilePath {
    return [_parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m", _fileName]];
}
@end
