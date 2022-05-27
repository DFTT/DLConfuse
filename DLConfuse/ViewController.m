//
//  ViewController.m
//  DLConfuse
//
//  Created by 大大东 on 2019/3/22.
//  Copyright © 2019 大大东. All rights reserved.
//

#import "ViewController.h"
#import "FileItem.h"

@interface ViewController ()
{
    // 根目录
    NSString *_rootDirectoryPath;
    
    // .xcodeproj 完整路径
    NSString *_xcodeprojPath;
    // TODO: 排除目录数组
    
    // .h .m .swift .pch
    NSMutableArray<FileItem *> *_codeFileArr;
    
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
    _codeFileArr = [[NSMutableArray alloc] init];
    _IBFileArr = [[NSMutableArray alloc] init];
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
    textView.string      = @"欢迎使用 ~~！ \n请一定要确保当前git工作区内容已提交, 便于工具修改错误时git回滚\n\n";
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
            
            if ([[[NSFileManager.defaultManager attributesOfItemAtPath:document.path error:nil] objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory]) {
                
                strongSelf->_rootDirectoryPath = document.path;
                [self p_appendMessage:[NSString stringWithFormat:@"---已选中目录:%@",document.path]];
            }else {
                [self p_appendMessage:[NSString stringWithFormat:@"---请选中一个目录:%@",document.path]];
            }
        }
    }];
}

#pragma mark - 查找符合条件的文件

- (void)p__findVisiableFilePath:(NSString *)rootPath {
    if (rootPath.length == 0) {
        return;
    }
    NSFileManager *fileM = [NSFileManager defaultManager];
    
    BOOL isDirectiry = NO;
    if (NO == [fileM fileExistsAtPath:rootPath isDirectory:&isDirectiry]) {
        // 过滤 非目录
        return;
    }
    if (isDirectiry && rootPath.pathExtension.length != 0) {
        // 过滤 有后缀的目录
        if (!_xcodeprojPath && [rootPath.pathExtension isEqualToString:@"xcodeproj"]) {
            _xcodeprojPath = rootPath;
        }
        return;
    }
    
    NSError *err = nil;
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
        if ([subpath.pathExtension isEqualToString:@"swift"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subpath.stringByDeletingPathExtension;
            item.parentDirectoryABSPath = rootPath;
            item.type                = FileIsSwift;
            [_codeFileArr addObject:item];
            continue;
        }
        if ([subpath.pathExtension isEqualToString:@"pch"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subpath.stringByDeletingPathExtension;
            item.parentDirectoryABSPath = rootPath;
            item.type                = FileIsPCH;
            [_codeFileArr addObject:item];
            continue;
        }
        if ([subpath.pathExtension isEqualToString:@"xib"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subpath.stringByDeletingPathExtension;
            item.parentDirectoryABSPath = rootPath;
            item.type                = FileIsXIB;
            [_IBFileArr addObject:item];
            continue;
        }
        if ([subpath.pathExtension isEqualToString:@"storyboard"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subpath.stringByDeletingPathExtension;
            item.parentDirectoryABSPath = rootPath;
            item.type                = FileIsStoryBoard;
            [_IBFileArr addObject:item];
            continue;
        }
        
        err = nil;
        NSDictionary *attr = [fileM attributesOfItemAtPath:absPath error:&err];
        if (nil == err && [attr[NSFileType] isEqualToString:NSFileTypeDirectory]) {
            // 没有后缀的子目录 后面继续递归
            [subDirectoryABSPathArr addObject:absPath];
        }
    }
    // 判断文件夹内.h/.m是否同时存在
    [subhFileArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *h, BOOL * _Nonnull stop) {
        NSString *tempM = [h stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
        if ([submFileArr containsObject:tempM]) {
            //.h .m同时存在
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = h.stringByDeletingPathExtension;
            item.parentDirectoryABSPath = rootPath;
            item.type = FileIsHAndM;
            [_codeFileArr addObject:item];
            
            [submFileArr removeObject:tempM];
            return;
        }
        // 单独.h
        FileItem *item              = [[FileItem alloc] init];
        item.fileName               = h.stringByDeletingPathExtension;
        item.parentDirectoryABSPath = rootPath;
        item.type = FileIsOnlyH;
        [_codeFileArr addObject:item];
    }];
    // 单独.m
    [submFileArr enumerateObjectsUsingBlock:^(NSString *m, BOOL * _Nonnull stop) {
        FileItem *item              = [[FileItem alloc] init];
        item.fileName               = m.stringByDeletingPathExtension;
        item.parentDirectoryABSPath = rootPath;
        item.type = FileIsOnlyM;
        [_codeFileArr addObject:item];
    }];
    
    // 递归子路径
    for (NSString *absDir in subDirectoryABSPathArr) {
        [self p__findVisiableFilePath:absDir];
    }
}
#pragma mark - 批量修改代码文件前缀
- (void)addPreBtnAction {
    [self p_appendMessage:@"---开始搜索符合条件的文件(.h/.m/.swift)"];
    [self p__findVisiableFilePath:_rootDirectoryPath];
    
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 对.h/.m/.swift/.pch 文件",(int)_codeFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个IB文件",(int)_IBFileArr.count]];
    
    if (_xcodeprojPath.length <= 0) {
        //
        [self p_appendMessage:@"---未找到.xcodeproj, 请修改搜索目录, 或初始化时赋值"];
        return;
    }
    
    [self modify];
    
    [self p_appendMessage:@"前缀修改完成"];
}

- (BOOL)p_reguleChange:(NSMutableString *)mContent from:(NSString *)old to:(NSString *)new {
    if (new.length <= 0 ) {
        return NO;
    }
    old = [old stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
    old = [old stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    NSString *pattern = [NSString stringWithFormat:@"\\b%@\\b", old];
    NSError *err = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&err];
    if (!regex || err) {
        NSLog(@"正则表达式创建失败, 请检查 %@", err);
        return NO;
    }
    NSArray<NSTextCheckingResult *> *matchRes = [regex matchesInString:mContent options:0 range:NSMakeRange(0, mContent.length)];
    if (matchRes.count == 0) {
        return NO;
    }
    for (NSInteger i = matchRes.count - 1; i >= 0; i--) {
        NSTextCheckingResult *result = matchRes[i];
        [mContent replaceCharactersInRange:result.range withString:new];
    }
    return YES;
}

- (void)modify {
    NSString *oldPre = @"BDD";
    NSString *newPre = @"DDL";
    
    // 工程文件_xcodeprojPath/project.pbxproj 内容
    NSString *pbxprojPath = [_xcodeprojPath stringByAppendingPathComponent:@"project.pbxproj"];
    NSMutableString *pbxprojContentString = [[NSMutableString alloc] initWithContentsOfFile:pbxprojPath encoding:NSUTF8StringEncoding error:nil];
    if (pbxprojContentString.length == 0) {
        NSAssert(NO, @"project.pbxproj 读取失败");
        return;
    }
    
    // 筛选需要修改文件名的
    NSMutableDictionary<NSString *, FileItem *> *nomalItemsMap = [NSMutableDictionary dictionaryWithCapacity:200];
    for (FileItem *item in _codeFileArr) {
        if ((item.type == FileIsHAndM || item.type == FileIsSwift) && ![item.fileName containsString:@"+"] && [item.fileName hasPrefix:oldPre]) {
            // 非扩展 (后面应该同时考虑 同名的xib 扩展文件)
            item.reFileName = [item.fileName stringByReplacingCharactersInRange:NSMakeRange(0, oldPre.length) withString:newPre];
            nomalItemsMap[item.fileName] = item;
        }
    }
    
    // 需要修改文件名的category
    NSMutableDictionary<NSString *, FileItem *> *categoryItemsMap = [NSMutableDictionary dictionaryWithCapacity:200];
    // 寻找需要该名的扩展
    for (FileItem *item in _codeFileArr) {
        NSArray *halfFileNames = [item.fileName componentsSeparatedByString:@"+"];
        if (halfFileNames.count == 2) {
            NSString *pre = halfFileNames.firstObject;
            NSString *suf = halfFileNames.lastObject;
            
            FileItem *hitItem = nomalItemsMap[pre];
            if (hitItem) {
                // 特殊 不需判断是否同时存在h/m (比如要改 aaa.swift, 这里找到 aaa+xxx.swift, aaa+xxx.h/m 后续都一起改掉)
                if ([suf hasPrefix:oldPre]) {
                    suf = [suf stringByReplacingCharactersInRange:NSMakeRange(0, oldPre.length) withString:newPre];
                }
                // 改名
                item.reFileName = [NSString stringWithFormat:@"%@+%@", hitItem.reFileName, suf];
                categoryItemsMap[item.fileName] = item;
                continue;
            }
            
            if (item.type == FileIsHAndM || item.type == FileIsSwift) {
                // 普通
                BOOL hit = NO;
                if ([pre hasPrefix:oldPre]) {
                    pre = [pre stringByReplacingCharactersInRange:NSMakeRange(0, oldPre.length) withString:newPre];
                    hit = YES;
                }
                if ([suf hasPrefix:oldPre]) {
                    suf = [suf stringByReplacingCharactersInRange:NSMakeRange(0, oldPre.length) withString:newPre];
                    hit = YES;
                }
                if (hit) {
                    // 改名
                    item.reFileName = [NSString stringWithFormat:@"%@+%@", pre, suf];
                    categoryItemsMap[item.fileName] = item;
                    continue;
                }
            }
            continue;
        }
        if (item.type == FileIsXIB || item.type == FileIsStoryBoard) {
            FileItem *hitItem = nomalItemsMap[item.fileName];
            if (hitItem) {
                // 特殊 (比如要改 aaa.swift, 这里找到 aaa.xib, aaa.storyboard 后续都一起改掉)
                // 改名
                item.reFileName = hitItem.reFileName;
                continue;
            }
        }
    }
    
    // 开始改文件内容
    NSMutableArray *reNameItems = [NSMutableArray arrayWithCapacity:categoryItemsMap.count + nomalItemsMap.count];
    [reNameItems addObjectsFromArray:categoryItemsMap.allValues]; // 一定先改扩展的
    [reNameItems addObjectsFromArray:nomalItemsMap.allValues];
    
    // 这样遍历修改能减少文件io
    [_codeFileArr enumerateObjectsUsingBlock:^(FileItem * _Nonnull codeFile, NSUInteger idx, BOOL * _Nonnull stop) {
        [codeFile.absFilesPath enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError *err = nil;
            NSMutableString *filecontent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
            if (filecontent.length == 0 || err) {
                NSLog(@"文件读取失败, 请检查重试 %@", err);
                return;
            }
            __block BOOL didChange = NO;
            [reNameItems enumerateObjectsUsingBlock:^(FileItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                didChange = [self p_reguleChange:filecontent from:obj.fileName to:obj.reFileName];
            }];
            if (didChange) {
                // 回写
                err = nil;
                [filecontent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
                if (err) {
                    NSLog(@"\n\n 艹 回写失败 ： %@", path);
                }
            }
        }];
    }];
    
    // 开始改文件名
    NSFileManager *film = [NSFileManager defaultManager];
    for (FileItem *item in _codeFileArr) {
        if (item.reFileName.length <= 0) {
            continue;
        }
        for (NSString *path in item.absFilesPath) {
            NSString *newName = [NSString stringWithFormat:@"%@.%@", item.reFileName, path.pathExtension];
            NSString *newPath = [item.parentDirectoryABSPath stringByAppendingPathComponent:newName];
            if (NO == [film moveItemAtPath:path toPath:newPath error:nil]) {
                NSLog(@"cao rename error -----");
                continue;
            }
            // 修改工程文件
            if ([self p_reguleChange:pbxprojContentString from:path.lastPathComponent to:newName] == NO) {
                NSLog(@"cao pbxprojContentString change faile -----");
            }
        }
    }
    // 回写pbxproj
    NSError *err = nil;
    if (![pbxprojContentString writeToFile:pbxprojPath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@"cao 回写pbxproj error -----%@", err);
    }
}


#pragma mark - 混淆标记的字符串
- (void)encryptBtnAction {
    [self p_appendMessage:@"---开始搜索符合条件的文件(.h/.m/.swift)"];
    
    //
    [self p__findVisiableFilePath:_rootDirectoryPath];
    
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 对.h/.m/.swift/.pch 文件",(int)_codeFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个IB文件",(int)_IBFileArr.count]];
    
    // 混淆 hard string
    [self p_filterAndEncodeHardString];
}

// 加密 hard string <金币,现金,钱,赚,红包,提现,任务>
- (void)p_filterAndEncodeHardString {
    for (FileItem *item in _codeFileArr) {
        NSArray *paths = [item absFilesPath];
        for (int i = 0; i<paths.count; i++) {
            NSString *path = paths[i];
            @autoreleasepool {
                [self hardString:item path:path];
            }
        }
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
    if ([matchs count] <= 0) {
        return;
    }
    NSMutableString *newFileContent = [fileCntent mutableCopy];
    // 得倒着来 （为了result.range 替换不出错）
    for (int i = (int)matchs.count - 1; i >= 0; i--) {
        // FlAG_ENCODE_STRING(@"xxxx")
        NSTextCheckingResult *result = matchs[i];
        NSString *matchSub        = [fileCntent substringWithRange:result.range];
        NSString *matchSubContent = [matchSub substringWithRange:NSMakeRange(19, result.range.length - 19 - 1)];
        matchSubContent = [matchSubContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (item.type == FileIsSwift) {
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
        if (item.type == FileIsSwift) {
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
@end
