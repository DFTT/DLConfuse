//
//  ViewController.m
//  DLConfuse
//
//  Created by 大大东 on 2019/3/22.
//  Copyright © 2019 大大东. All rights reserved.
//

#import "ViewController.h"
#import "FileItem.h"



// md5加密
#import <CommonCrypto/CommonDigest.h>
static NSString * MD5_32(NSString *originString) {
    if (!originString || originString.length == 0) {
        return @"";
    }
    const char* str = [originString UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];//
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}






@interface ViewController ()
{
    // 根目录
    NSString *_rootDirectoryPath;
    
    
    
    //.h / .m
    NSMutableArray<FileItem *> *_visiableFileArr;
    // .swift
    NSMutableArray<FileItem *> *_swiftFileArr;
    // .xib  .stroryboare
    NSMutableArray<FileItem *> *_IBFileArr;
    
    
    
    // UI
    NSTextView *_messageView;
}
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // init
    [self __reset];
    
    
    [self setupUI];
}
- (void)__reset {
    _visiableFileArr = [[NSMutableArray alloc] init];
    _swiftFileArr    = [[NSMutableArray alloc] init];
    _IBFileArr       = [[NSMutableArray alloc] init];
}
#pragma mark - UI
- (void)setupUI {
    // btn
    NSButton *btn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 10, 100, 50)];
    btn.bezelStyle = NSBezelStyleRounded;
    [btn setTitle:@"选择代码目录"];
    [btn setTarget:self];
    [btn setAction:@selector(btnClickAction)];
    [self.view addSubview:btn];
    
    //
    NSButton *encryptBtn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 110, 100, 50)];
    encryptBtn.bezelStyle = NSBezelStyleRounded;
    [encryptBtn setTitle:@"开始加密字符串"];
    [encryptBtn setTarget:self];
    [encryptBtn setAction:@selector(encryptBtnAction)];
    [self.view addSubview:encryptBtn];
    
    
    //
    NSButton *addPreBtn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 160, 180, 50)];
    addPreBtn.bezelStyle = NSBezelStyleRounded;
    [addPreBtn setTitle:@"代码文件批量增加前缀Beta"];
    [addPreBtn setTarget:self];
    [addPreBtn setAction:@selector(addPreBtnAction)];
    [self.view addSubview:addPreBtn];
    
    
    //
    NSScrollView *scrolleView = [[NSScrollView alloc] initWithFrame:CGRectMake(190, 10, 800, self.view.bounds.size.height - 10)];
    [scrolleView setHasVerticalScroller:YES];
    [scrolleView setHasHorizontalScroller:NO];
    [self.view addSubview:scrolleView];
    //
    NSTextView *textView = [[NSTextView alloc] initWithFrame:CGRectMake(150, 10, 800, self.view.bounds.size.height - 10)];
    textView.editable    = NO;
    textView.string      = @"欢迎使用 ~~！ \n\n";
    [scrolleView setDocumentView:textView];
   
    _messageView = textView;
}
- (void)p_appendMessage:(NSString *)text {
    if (text == nil) {
        return;
    }
    
    text = [text stringByAppendingString:@"\n\n"];
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:text];

    
    [[_messageView textStorage] appendAttributedString:attr];
    [_messageView scrollRangeToVisible:NSMakeRange([[_messageView string] length], 0)];
}
#pragma mark - Action
- (void)btnClickAction {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES;
    panel.resolvesAliases = NO;
    
    __weak typeof(self)weakSelf = self;
    [panel beginWithCompletionHandler:^(NSInteger result){
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (result == NSModalResponseOK) {
            NSURL *document = [[panel URLs] objectAtIndex:0];
            
            strongSelf->_rootDirectoryPath = document.path;
            
            [self p_appendMessage:[NSString stringWithFormat:@"---已选中目录:%@",document.path]];
        }
    }];
}


#pragma mark - 查找符合条件的文件

- (void)p__findVisiableFilePath:(NSString *)rootPath needOnlyHFile:(BOOL)needOnlyH {
    
    if (rootPath.length == 0) {
        return;
    }
    
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSError       *err        = nil;
    
    NSArray<NSString *> *contents = [fileM contentsOfDirectoryAtPath:rootPath error:&err];
    if (err) {
        NSLog(@"contents error = %@", err);
        return;
    }
    //
    NSMutableSet *subhFileArr = [[NSMutableSet alloc] init];
    NSMutableSet *submFileArr = [[NSMutableSet alloc] init];
    NSMutableArray *subDirectoryABSPathArr = [[NSMutableArray alloc] init];
    
    for (NSString *subpath in contents) {
        
        NSString *absPath = [rootPath stringByAppendingPathComponent:subpath];
        if ([fileM isWritableFileAtPath:absPath] == NO) {
            // 不能修改的跳过
            continue;
        }
       
        if ([subpath.pathExtension isEqualToString:@"h"]) {
            [subhFileArr addObject:subpath];
            continue;
        }
        if ([subpath.pathExtension isEqualToString:@"m"]) {
            [submFileArr addObject:subpath];
            continue;
        }
        if ([subpath.pathExtension isEqualToString:@"swift"] && ![subpath isEqualToString:@"Macros.swift"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = [subpath stringByReplacingOccurrencesOfString:@".swift" withString:@""];
            item.parentDirectoryABSPath = rootPath;
            item.isSwift                = YES;
            [_swiftFileArr addObject:item];
            continue;
        }
        if ([subpath.pathExtension isEqualToString:@"xib"] || [subpath.pathExtension isEqualToString:@"storyboard"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subpath;
            item.parentDirectoryABSPath = rootPath;
            [_IBFileArr addObject:item];
            continue;
        }
        
        
        err = nil;
        NSDictionary *attr = [fileM attributesOfItemAtPath:absPath error:&err];
        if (err) {
            NSLog(@"attributes error = %@", err);
            continue;
        }
        if ([attr[NSFileType] isEqualToString:NSFileTypeDirectory]) {
            if (subpath.pathExtension.length == 0) {
                [subDirectoryABSPathArr addObject:absPath];
            }else {
                NSLog(@"过滤有后缀的文件夹 : %@", subpath);
            }
            continue;
        }
        
        NSLog(@"跳过的文件-- %@", subpath);
    }
    // 判断是否两个文件都在
    for (NSString *h in subhFileArr) {
        NSString *temp = [h stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
        if ([submFileArr containsObject:temp]) {
            //.h .m同时存在
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = [h stringByReplacingOccurrencesOfString:@".h" withString:@""];
            item.parentDirectoryABSPath = rootPath;
            [_visiableFileArr addObject:item];
        }else {
            // 只有.h
            NSLog(@"未配对文件: %@", h);
            
            if(needOnlyH) {
                FileItem *item              = [[FileItem alloc] init];
                item.onlyHFile              = YES;
                item.fileName               = [h stringByReplacingOccurrencesOfString:@".h" withString:@""];
                item.parentDirectoryABSPath = rootPath;
                [_visiableFileArr addObject:item];
            }
        }
    }
    // 递归子路径
    for (NSString *absDir in subDirectoryABSPathArr) {
        [self p__findVisiableFilePath:absDir needOnlyHFile:needOnlyH];
    }
}
#pragma mark - 批量修改代码文件前缀
- (void)addPreBtnAction {
    [self p_appendMessage:@"---开始搜索符合条件的文件(.h/.m/.swift)"];
    [self p__findVisiableFilePath:_rootDirectoryPath needOnlyHFile:YES];
    
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 对.h/.m文件",(int)_visiableFileArr.count + (int)_swiftFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个.swift文件",(int)_swiftFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个IB文件",(int)_IBFileArr.count]];
    
    [self modify];
    
    [self p_appendMessage:@"前缀修改完成"];
}
- (void)modify {
    NSString *oldPre = @"BDD";
    NSString *newPre = @"DDL";
    
    NSMutableArray *reanmeInfo = [NSMutableArray array];
    //
    for (FileItem *item in _visiableFileArr) {
        if (item.onlyHFile == YES) {
            // 这个情况要在考虑
            continue;;
        }
        if ([item.fileName containsString:@"+"]) {
            // 扩展 这个情况也要在考虑
            continue;
        }
        
        NSString *oldFileName = item.fileName;
        if (NO == [oldFileName hasPrefix:oldPre]) {
            // 只有符合条件的 才修改
            continue;
        }
        
        NSString *newFileName = [oldFileName stringByReplacingCharactersInRange:NSMakeRange(0, oldPre.length) withString:newPre];
        
        // 改一遍头文件导入名
        NSString *fileContent = nil;
        for (FileItem *item2 in _visiableFileArr) {
            @autoreleasepool {
                // h
                fileContent = [[NSString alloc] initWithContentsOfFile:item2.abs_h_FilePath encoding:NSUTF8StringEncoding error:nil];
                fileContent = [fileContent stringByReplacingOccurrencesOfString:oldFileName withString:newFileName];
                [fileContent writeToFile:item2.abs_h_FilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                // m
                fileContent = [[NSString alloc] initWithContentsOfFile:item2.abs_m_FilePath encoding:NSUTF8StringEncoding error:nil];
                fileContent = [fileContent stringByReplacingOccurrencesOfString:oldFileName withString:newFileName];
                [fileContent writeToFile:item2.abs_m_FilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        }
        // 记录
        [reanmeInfo addObject:@{@"new":[item.parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h", newFileName]],
                                @"old":[item.parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.h", oldFileName]],
        }];
        [reanmeInfo addObject:@{@"new":[item.parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m", newFileName]],
                                @"old":[item.parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m", oldFileName]],
        }];
    }
    
    for (FileItem *item in _swiftFileArr) {
        if ([item.fileName containsString:@"+"]) {
            // 这个情况也要在考虑
            continue;
        }
        
        NSString *oldFileName = item.fileName;
        if (NO == [oldFileName hasPrefix:oldPre]) {
            continue;
        }
        NSString *newFileName = [oldFileName stringByReplacingCharactersInRange:NSMakeRange(0, oldPre.length) withString:newPre];
        // swift
        [reanmeInfo addObject:@{@"new":[item.parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.swift", newFileName]],
                                @"old":[item.parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.swift", oldFileName]],
        }];
    }
    
    
    NSFileManager *film = [NSFileManager defaultManager];
    for (NSDictionary *dic in reanmeInfo) {
        NSString *new = dic[@"new"];
        NSString *old = dic[@"old"];
        if (NO == [film moveItemAtPath:old toPath:new error:nil]) {
            NSLog(@"rename error -----");
        }
    }
}


#pragma mark - 混淆标记的字符串
- (void)encryptBtnAction {
    [self p_appendMessage:@"---开始搜索符合条件的文件(.h/.m/.swift)"];
    
    //
    [self p__findVisiableFilePath:_rootDirectoryPath needOnlyHFile:NO];
    
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 对文件",(int)_visiableFileArr.count+(int)_swiftFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个IB文件",(int)_IBFileArr.count]];
    
    // 混淆 hard string
    [self p_filterAndEncodeHardString];
}

// 加密 hard string <金币,现金,钱,赚,红包,提现,任务>
- (void)p_filterAndEncodeHardString {
    for (FileItem *item in _visiableFileArr) {
        for (int i = 0; i<2; i++) {
            NSString *path = i == 0 ? [item abs_h_FilePath] : [item abs_m_FilePath];
            [self hardString:item path:path ];
        }
    }
    
    for (FileItem *item in _swiftFileArr) {
        [self hardString:item path:[item abs_swift_FilePath]];
    }
    
    [self p_appendMessage:[NSString stringWithFormat:@"---hard string 处理结束"]];
}

- (void)hardString:(FileItem *)item path:(NSString *)path {
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:@"FlAG_ENCODE_STRING\\(.+?\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSError *err         = nil;
    NSString *fileCntent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (!fileCntent || err) {
        NSLog(@"file read failure : %@", err);
        return;
    }
    
    NSArray *char_Arr = @[@"?",@"<",@"!",@"*",@">",@"]"];
    
    // 寻找标记的hard string
    NSArray<NSTextCheckingResult *> *matchs = [regExp matchesInString:fileCntent options:0 range:NSMakeRange(0, fileCntent.length)];
    if ([matchs count] > 0) {
        NSMutableString *newFileContent = [fileCntent mutableCopy];
        // 得倒着来 （为了result.range 替换不出错）
        for (int i = (int)matchs.count - 1; i >= 0; i--) {
            // FlAG_ENCODE_STRING(@"xxxx")
            NSTextCheckingResult *result = matchs[i];
            NSString *matchSub        = [fileCntent substringWithRange:result.range];
            NSString *matchSubContent = [matchSub substringWithRange:NSMakeRange(19, result.range.length - 19 - 1)];
            matchSubContent = [matchSubContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (item.isSwift) {
                matchSubContent = [matchSubContent substringWithRange:NSMakeRange(1, matchSubContent.length - 2)];
            }else{
                matchSubContent = [matchSubContent substringWithRange:NSMakeRange(2, matchSubContent.length - 3)];
            }
            
            if (matchSubContent.length == 0) {
                continue;
            }
            // 混淆编码
            NSMutableString *mTmp = [[[matchSubContent dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0] mutableCopy];
            for (NSString *ch_ar in char_Arr) {
                [mTmp insertString:ch_ar atIndex:arc4random() % mTmp.length];
            }
            if (item.isSwift) {
                matchSub = [NSString stringWithFormat:@"DECODE_STRING(\"%@\")", mTmp];
            }else{
                matchSub = [NSString stringWithFormat:@"DECODE_STRING(@\"%@\")", mTmp];
            }
            
            // 替换回去
            [newFileContent replaceCharactersInRange:result.range withString:matchSub];
        }
        
        // 写回去
        [newFileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            NSLog(@"\n\n 艹 回写失败 ： %@", path);
        }
    }
}
@end
