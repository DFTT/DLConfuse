//
//  ViewController.m
//  DLConfuse
//
//  Created by 大大东 on 2019/3/22.
//  Copyright © 2019 大大东. All rights reserved.
//

#import "ViewController.h"
#import "FileItem.h"
#import "HardStringEncryptDecryptUnit.h"

@interface XYZBaseView : NSView
@end
@implementation XYZBaseView
- (BOOL)isFlipped {
    return YES;
}
@end


@interface ViewController ()
{
    // 根目录
    NSURL *_rootDirectoryPathURL;
    
    // .xcodeproj 完整路径
    NSString *_xcodeprojPath;
    // TODO: 排除目录数组
    
    // .h .m .swift .pch
    NSMutableArray<FileItem *> *_codeFileArr;
    
    // .xib  .stroryboare
    NSMutableArray<FileItem *> *_IBFileArr;
    
    // 需要过滤掉的 文件名/文件夹
    NSSet<NSString *> *_filterFileNames;
    
    // UI
    NSTextView *_messageView;
    NSTextField *_filterTf;
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
    _xcodeprojPath = nil;
    
    NSArray *names = [_filterTf.stringValue componentsSeparatedByString:@";"];
    _filterFileNames = [NSSet setWithArray:names];
}
#pragma mark - UI
- (void)setupUI {
    //    CGSize size = [NSApplication sharedApplication].windows.firstObject.frame.size;
    
    // btn
    NSButton *btn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 10, 200, 50)];
    btn.bezelStyle = NSBezelStyleRounded;
    [btn setTitle:@"选择代码目录"];
    [btn setTarget:self];
    [btn setAction:@selector(btnClickAction)];
    [self.view addSubview:btn];
    
    NSTextField *tf = [[NSTextField alloc] initWithFrame:CGRectMake(5, 60, 200, 50)];
    tf.placeholderString = @"要忽略的文件夹 用分号分隔 (例如: Verder;YYKit)";
    [self.view addSubview:tf];
    _filterTf = tf;
    
    //
    NSButton *encryptBtn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 210, 200, 50)];
    encryptBtn.bezelStyle = NSBezelStyleRounded;
    [encryptBtn setTitle:@"hardSrtring加密"];
    [encryptBtn setTarget:self];
    [encryptBtn setAction:@selector(encryptBtnAction)];
    [self.view addSubview:encryptBtn];
    
    //
    NSButton *addPreBtn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 260, 200, 50)];
    addPreBtn.bezelStyle = NSBezelStyleRounded;
    [addPreBtn setTitle:@"修改代码文件前缀"];
    [addPreBtn setTarget:self];
    [addPreBtn setAction:@selector(addPreBtnAction)];
    [self.view addSubview:addPreBtn];
    
    //
    NSButton *changeDirectoryNameBtn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 310, 200, 50)];
    changeDirectoryNameBtn.bezelStyle = NSBezelStyleRounded;
    [changeDirectoryNameBtn setTitle:@"修改文件夹名(深度遍历)"];
    [changeDirectoryNameBtn setTarget:self];
    [changeDirectoryNameBtn setAction:@selector(changeDirectoryNameBtnAciton)];
    [self.view addSubview:changeDirectoryNameBtn];
    
    
    //
    NSScrollView *scrolleView = [[NSScrollView alloc] initWithFrame:CGRectMake(220, 10, 800, self.view.bounds.size.height - 10)];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:text];
        
        
        [[self->_messageView textStorage] appendAttributedString:attr];
        [self->_messageView scrollRangeToVisible:NSMakeRange([[self->_messageView string] length], 0)];
    });
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
                
                strongSelf->_rootDirectoryPathURL = document;
                [self p_appendMessage:[NSString stringWithFormat:@"---已选中目录:%@",document]];
            }else {
                [self p_appendMessage:[NSString stringWithFormat:@"---请选中一个文件目录:%@",document]];
            }
        }
    }];
}

#pragma mark - 查找符合条件的文件

- (void)p__findVisiableFilesInURL:(NSURL *)rootURL {
    if (!rootURL) {
        return;
    }
    NSFileManager *fileM = [NSFileManager defaultManager];
    
    BOOL isDirectiry = NO;
    if (NO == [fileM fileExistsAtPath:rootURL.path isDirectory:&isDirectiry]) {
        // 过滤 非目录
        return;
    }
    if (isDirectiry && rootURL.pathExtension.length != 0) {
        // 过滤 有后缀的目录
        if (!_xcodeprojPath &&
            [rootURL.pathExtension isEqualToString:@"xcodeproj"] &&
            ![rootURL.absoluteString containsString:@"/Pods/"]) {
            _xcodeprojPath = rootURL.path;
        }
        return;
    }
    if (isDirectiry && [rootURL.lastPathComponent hasPrefix:@"."]) {
        // 过滤 .xx  这种命名的文件夹
        return;
    }
    
    if ([_filterFileNames containsObject:rootURL.lastPathComponent]) {
        // 命中过滤
        NSLog(@" 命中过滤文件夹 %@", rootURL.lastPathComponent);
        return;
    }
    
    NSError *err = nil;
    NSArray<NSURL *> *contentURLs = [fileM contentsOfDirectoryAtURL:rootURL
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                            options:NSDirectoryEnumerationSkipsHiddenFiles   // 忽略隐藏文件/夹
                                                              error:&err];
    if (err) {
        NSLog(@" 艹 contents error = %@", err);
        return;
    }
    //
    NSMutableSet *subhFileArr = [[NSMutableSet alloc] init];
    NSMutableSet *submFileArr = [[NSMutableSet alloc] init];
    NSMutableArray<NSURL *> *subDirectorysURL = [[NSMutableArray alloc] init];
    
    for (NSURL *subURL in contentURLs) {
        
        if ([fileM isWritableFileAtPath:subURL.path] == NO) {
            // 不能修改的跳过
            NSLog(@" 艹 跳过 这个文件没有覆写权限 = %@", subURL);
            continue;
        }
        NSString *fileExtension = subURL.pathExtension;
        if ([fileExtension isEqualToString:@"h"]) {
            [subhFileArr addObject:subURL.lastPathComponent];
            continue;
        }
        if ([fileExtension isEqualToString:@"m"]) {
            [submFileArr addObject:subURL.lastPathComponent];
            continue;
        }
        if ([fileExtension isEqualToString:@"swift"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subURL.URLByDeletingPathExtension.lastPathComponent;
            item.parentDirectoryABSPath = rootURL.path;
            item.type                = FileIsSwift;
            [_codeFileArr addObject:item];
            continue;
        }
        if ([fileExtension isEqualToString:@"pch"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subURL.URLByDeletingPathExtension.lastPathComponent;
            item.parentDirectoryABSPath = rootURL.path;
            item.type                = FileIsPCH;
            [_codeFileArr addObject:item];
            continue;
        }
        if ([fileExtension isEqualToString:@"xib"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subURL.URLByDeletingPathExtension.lastPathComponent;
            item.parentDirectoryABSPath = rootURL.path;
            item.type                = FileIsXIB;
            [_IBFileArr addObject:item];
            continue;
        }
        if ([fileExtension isEqualToString:@"storyboard"]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = subURL.URLByDeletingPathExtension.lastPathComponent;
            item.parentDirectoryABSPath = rootURL.path;
            item.type                = FileIsStoryBoard;
            [_IBFileArr addObject:item];
            continue;
        }
        
        err = nil;
        if ([[[subURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&err] objectForKey:NSURLIsDirectoryKey] boolValue] == YES && nil == err) {
            // 子目录 后面继续递归
            [subDirectorysURL addObject:subURL];
        }
    }
    // 判断文件夹内.h/.m是否同时存在
    [subhFileArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString *h, BOOL * _Nonnull stop) {
        NSString *tempM = [h stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
        if ([submFileArr containsObject:tempM]) {
            //.h .m同时存在
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = h.stringByDeletingPathExtension;
            item.parentDirectoryABSPath = rootURL.path;
            item.type = FileIsHAndM;
            [_codeFileArr addObject:item];
            
            [submFileArr removeObject:tempM];
            return;
        }
        // 单独.h
        FileItem *item              = [[FileItem alloc] init];
        item.fileName               = h.stringByDeletingPathExtension;
        item.parentDirectoryABSPath = rootURL.path;
        item.type = FileIsOnlyH;
        [_codeFileArr addObject:item];
    }];
    // 单独.m
    [submFileArr enumerateObjectsUsingBlock:^(NSString *m, BOOL * _Nonnull stop) {
        FileItem *item              = [[FileItem alloc] init];
        item.fileName               = m.stringByDeletingPathExtension;
        item.parentDirectoryABSPath = rootURL.path;
        item.type = FileIsOnlyM;
        [_codeFileArr addObject:item];
    }];
    
    // 递归子路径
    for (NSURL *subDirURL in subDirectorysURL) {
        [self p__findVisiableFilesInURL:subDirURL];
    }
}

#pragma mark - 修改文件夹名(深度遍历)
- (void)changeDirectoryNameBtnAciton {
    if (!_rootDirectoryPathURL) {
        [self p_appendMessage:@"---请先指定一个目录"];
        return;
    }
    //
    [self __reset];
    [self p_appendMessage:@"---开始深度遍历指定目录, 并修改文件夹名称"];
//        ..
    [self p__changeAllDirectoryInURL:_rootDirectoryPathURL];
    
    [self p_appendMessage:@"---完成拉👏🏻"];
}
- (void)p__changeAllDirectoryInURL:(NSURL *)rootURL {
    if (!rootURL) {
        return;
    }
    NSFileManager *fileM = [NSFileManager defaultManager];
    
    BOOL isDirectiry = NO;
    if (NO == [fileM fileExistsAtPath:rootURL.path isDirectory:&isDirectiry]) {
        // 过滤 非目录
        return;
    }
    if ([fileM isWritableFileAtPath:rootURL.path] == NO) {
        // 过滤 无写权限的的
        return;
    }
    if (isDirectiry && rootURL.pathExtension.length != 0) {
        // 过滤 有后缀的目录
        if (!_xcodeprojPath &&
            [rootURL.pathExtension isEqualToString:@"xcodeproj"] &&
            ![rootURL.absoluteString containsString:@"/Pods/"]) {
            _xcodeprojPath = rootURL.path;
        }
        return;
    }
    if (isDirectiry && [rootURL.lastPathComponent hasPrefix:@"."]) {
        // 过滤 .xx  这种命名的文件夹
        return;
    }
    
    if ([_filterFileNames containsObject:rootURL.lastPathComponent]) {
        // 命中过滤
        NSLog(@" 命中过滤文件夹 %@", rootURL.lastPathComponent);
        return;
    }
    
    NSError *err = nil;
    
    // 修改
    NSString *dirName = rootURL.lastPathComponent;
    NSURL *supperDirURL = rootURL.URLByDeletingLastPathComponent;
    NSString *newDirName = [[dirName substringFromIndex:dirName.length - 2] stringByAppendingString:[dirName substringToIndex:dirName.length - 2]];
    
    NSURL *newURL = [supperDirURL URLByAppendingPathComponent:newDirName];
    if ([rootURL isEqualTo:_rootDirectoryPathURL]) {
        // 根目录不修改 因为可能是git根目录 修改后soucetree会识别不大 这个手动处理
        newURL = rootURL;
    }else if ([fileM moveItemAtURL:rootURL toURL:newURL error:&err] == NO || err) {
        // 修改失败, 继续修改子目录
        newURL = rootURL;
        NSLog(@"目录修改失败了: %@", err);
    }
    
    // 处理子目录
    NSArray<NSURL *> *contentURLs = [fileM contentsOfDirectoryAtURL:newURL
                                         includingPropertiesForKeys:@[NSURLIsDirectoryKey]
                                                            options:NSDirectoryEnumerationSkipsHiddenFiles   // 忽略隐藏文件/夹
                                                              error:&err];
    if (err) {
        NSLog(@" 艹 contents error = %@", err);
        return;
    }
    
    for (NSURL *subURL in contentURLs) {
        err = nil;
        if ([[[subURL resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&err] objectForKey:NSURLIsDirectoryKey] boolValue] == YES && nil == err) {
            
            // 子目录 后面继续递归
            [self p__changeAllDirectoryInURL:subURL];
        }
    }
}


#pragma mark - 批量修改代码文件前缀
- (void)addPreBtnAction {
    
    [self p_appendMessage:@"---开始搜索符合条件的文件(.h/.m/.swift)"];
    [self __reset];
    [self p__findVisiableFilesInURL:_rootDirectoryPathURL];
    
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 对.h/.m/.swift/.pch 文件",(int)_codeFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个IB文件",(int)_IBFileArr.count]];
    
    if (_xcodeprojPath.length <= 0) {
        //
        [self p_appendMessage:@"---未找到.xcodeproj, 请修改搜索目录, 或初始化时赋值"];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self modify];
        
        [self p_appendMessage:@"前缀修改完成"];
    });
}


// fromFile 这个参数是为了debugLog
- (BOOL)p_reguleChange:(NSMutableString *)mContent fromFile:(NSString *)file match:(NSString *)old to:(NSString *)new {
    return [self p_reguleChange:mContent fromFile:file match:old regularMatch:nil to:new];
}
- (BOOL)p_reguleChange:(NSMutableString *)mContent fromFile:(NSString *)file match:(NSString *)old regularMatch:(NSString *)regularOld to:(NSString *)new {
    if (new.length <= 0 ) {
        NSLog(@" 艹 这里不会走的");
        return NO;
    }
    NSString *pattern = nil;
    if (regularOld.length > 0) {
        pattern = regularOld;
    }else {
        // 构造正则表达式, 处理特殊字符
        NSString *temp = [old stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
        temp = [temp stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
        pattern = [NSString stringWithFormat:@"\\b%@\\b", temp];
    }
    
    NSError *err = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&err];
    if (!regex || err) {
        NSLog(@" 艹 正则表达式创建失败, 请检查 %@", err);
        return NO;
    }
    NSArray<NSTextCheckingResult *> *matchRes = [regex matchesInString:mContent options:0 range:NSMakeRange(0, mContent.length)];
    //    NSLog(@" DEBUG LOG %@ 中匹配到 %d 个 %@", file, (int)matchRes.count, old);
    if (matchRes.count == 0) {
        return NO;
    }
    for (NSInteger i = matchRes.count - 1; i >= 0; i--) {
        NSTextCheckingResult *result = matchRes[i];
        //        if (![[mContent substringWithRange:result.range] isEqualToString:old]) {
        //            NSLog(@" DEBUG LOG 匹配错啦 错啦 错啦: %@", old);
        //        }
        [mContent replaceCharactersInRange:result.range withString:new];
    }
    return YES;
}

- (void)modify {
    NSArray *oldPreArr = @[@"TP", @"PW", @"SU"];
    NSString *newPre = @"TP";
    
    // 后缀修改, 仅是为了增加变化, 不喜欢也可以不要
    NSDictionary<NSString *, NSString *> *subFixMap = @{@"ViewController" : @"VC",
                                                        @"Ctl" : @"VC",
                                                        @"Ctrl" : @"VC",
    };
    
    typedef NSString *_Nullable (^CheckAndBackNewPreFixBlock)(NSString *oldName);
    CheckAndBackNewPreFixBlock __checkAndBackNewPreFix = ^ NSString * (NSString *oldName) {
        // 过滤常见系统前缀
        if ([oldName hasPrefix:@"NS"] || [oldName hasPrefix:@"UI"] || [oldName hasPrefix:@"CA"] || [oldName hasPrefix:@"AV"] ||
            [oldName isEqualToString:@"Appdelegate"]) {
            return nil;
        }
        
        
        // 后缀
        __block NSString *newSufixName = nil;
        [subFixMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([oldName hasSuffix:key]) {
                newSufixName = [oldName stringByReplacingCharactersInRange:NSMakeRange(newSufixName.length - key.length, key.length) withString:obj];
                *stop = YES;
            }
        }];
        
        // 前缀匹配
        NSString *newName = newSufixName ? newSufixName : oldName;
        for (NSString *oPre in oldPreArr) {
            if ([newName hasPrefix:oPre]) {
                return [newName stringByReplacingCharactersInRange:NSMakeRange(0, oPre.length) withString:newPre];
            }
        }
        
        // 如果仅第二个字符不是大写 说明没有前缀 一般swift类居多 (这里给其加上前缀)
        newName = newSufixName ? newSufixName : oldName;
        if (newName.length >= 2) {
            unichar firstChar = [newName characterAtIndex:0];
            unichar secondChar = [newName characterAtIndex:1];
            if (secondChar >= 'a' && secondChar <= 'z') {
                NSString *upperFirstChar = [[NSString stringWithCharacters:&firstChar length:1] uppercaseString];
                
                return [NSString stringWithFormat:@"%@%@%@", newPre, upperFirstChar, [newName substringFromIndex:1]];
            }
        }
        return nil;
    };
    
    // 工程文件_xcodeprojPath/project.pbxproj 内容
    NSString *pbxprojPath = [_xcodeprojPath stringByAppendingPathComponent:@"project.pbxproj"];
    NSMutableString *pbxprojContentString = [[NSMutableString alloc] initWithContentsOfFile:pbxprojPath encoding:NSUTF8StringEncoding error:nil];
    if (pbxprojContentString.length == 0) {
        NSAssert(NO, @"project.pbxproj 读取失败");
        return;
    }
    
    // 筛选需要修改的 代码文件 (不包含类扩展文件)
    NSMutableDictionary<NSString *,FileItem *> * needReNameCodeFileItemMap = [NSMutableDictionary dictionaryWithCapacity:200];
    for (FileItem *item in _codeFileArr) {
        if ((item.type == FileIsHAndM || item.type == FileIsSwift) &&
            [item.fileName componentsSeparatedByString:@"+"].count != 2) {
            NSString *newName = __checkAndBackNewPreFix(item.fileName);
            if (newName == nil) {
                continue;
            }
            // 非扩展 (后面应该同时考虑 同名的xib 扩展文件)  (名字中1个"+"认为是扩展 后面处理, 没有或2个及以上"+"认为是普通文件 这里处理)
            item.reFileName = newName;
            needReNameCodeFileItemMap[item.fileName] = item;
            
            // 继续寻找 代码文件中有 其它class struct  后面一起改掉
            NSString *pattern = nil;
            if (item.type == FileIsHAndM) {
                pattern = @"@implementation +(\\w+) *(\\(.*\\)|\n)";
            }else {
                pattern = @"(class|struct|protocol|enum) +(\\w+)+ *[{:]";
            }
            for(NSString *path in item.absFilesPath) {
                if ([path.pathExtension isEqualToString:@"m"] || [path.pathExtension isEqualToString:@"swift"]) {
                    NSMutableDictionary *classNameMap = [self p_matchClassNameFromCodeFile:path
                                                                                regularPat:pattern
                                                                                     swift:item.type == FileIsSwift];
                    // 去除和文件同名的
                    [classNameMap removeObjectForKey:item.fileName];
                    // 去除前缀不匹配的
                    NSArray<OtherClassNameItem *> *finalArr = [classNameMap.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OtherClassNameItem *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                        
                        NSString *newName = __checkAndBackNewPreFix(evaluatedObject.className);
                        if (newName == nil) {
                            return NO;
                        }
                        
                        evaluatedObject.reClassName = newName;
                        return YES;
                    }]];
                    // 记录
                    item.otherClassItems = finalArr;
                    break;
                }
            }
        }
    }
    
    // 根据上面需要改名的代码文件 这里筛选出其对应的 扩展文件
    NSMutableDictionary<NSString *, FileItem *> *needReNameCategoryFileItemMap = [NSMutableDictionary dictionaryWithCapacity:200];
    for (FileItem *item in _codeFileArr) {
        NSArray *halfFileNames = [item.fileName componentsSeparatedByString:@"+"];
        if (halfFileNames.count == 2) {
            NSString *pre = halfFileNames.firstObject;
            NSString *suf = halfFileNames.lastObject;
            FileItem *hitItem = needReNameCodeFileItemMap[pre];
            if (hitItem) {
                // 同名扩展
                // 特殊 不需判断是否同时存在h/m (比如要改 aaa.swift, 这里找到 aaa+xxx.swift, aaa+xxx.h/m 后续都一起改掉)
                suf = __checkAndBackNewPreFix(suf) ? : suf;
                // 修改前缀+后缀
                item.reFileName = [NSString stringWithFormat:@"%@+%@", hitItem.reFileName, suf];
                needReNameCategoryFileItemMap[item.fileName] = item;
                
            }else if (item.type == FileIsHAndM || item.type == FileIsSwift) {
                // 其它扩展
                // 只判断后半截 后续替换时 只替换aaa+bbb.h 及 bbb, aaa不能替换 会错, 因为如果aaa满足改名条件, 则会命中上面的逻辑
                NSString *newSuf = __checkAndBackNewPreFix(suf);
                if (newSuf.length > 0) {
                    // 仅修改后缀
                    item.reFileName = [NSString stringWithFormat:@"%@+%@", pre, newSuf];
                    needReNameCategoryFileItemMap[item.fileName] = item;
                }
            }
        }
    }
    
    // 根据上面需要改名的代码文件 这里筛选出其对应的 IB文件
    NSMutableDictionary<NSString *, FileItem *> *needReNameIBFileItemMap = [NSMutableDictionary dictionaryWithCapacity:200];
    for (FileItem *item in _IBFileArr) {
        // ib 文件
        if (item.type == FileIsXIB || item.type == FileIsStoryBoard) {
            FileItem *hitItem = needReNameCodeFileItemMap[item.fileName];
            if (hitItem) {
                // 特殊 (比如要改 aaa.swift, 这里找到 aaa.xib, aaa.storyboard 后续都一起改掉)
                // 改名成和代码文件同名
                item.reFileName = hitItem.reFileName;
                needReNameIBFileItemMap[item.fileName] = item;
            }
            continue;
        }
    }
    
    // 开始改文件
    NSInteger needRenameFileCount = needReNameCategoryFileItemMap.count + needReNameCodeFileItemMap.count + needReNameIBFileItemMap.count;
    if (needRenameFileCount == 0) {
        [self p_appendMessage:[NSString stringWithFormat:@"---没有发现需要修改前缀的文件"]];
        NSLog(@"\n\n 完成拉~~~~~~~~~\n");
        return;
    }
    [self p_appendMessage:[NSString stringWithFormat:@"---有 %d 组需要修改前缀的代码文件", (int)(needRenameFileCount)]];
    
    // 1. 先改文件内容 (这样遍历修改能减少文件I/O)
    NSMutableArray *allFiles = [_codeFileArr mutableCopy];
    // 加上IB文件
    [allFiles addObjectsFromArray:_IBFileArr];
    [allFiles enumerateObjectsUsingBlock:^(FileItem * _Nonnull codeFile, NSUInteger idx, BOOL * _Nonnull stop) {
        for (NSString *path in codeFile.absFilesPath) {
            // 对遍历的文件内容进行修改:
            NSError *err = nil;
            NSMutableString *filecontent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
            if (filecontent.length == 0 || err) {
                NSLog(@" 艹 文件读取失败, 请检查重试 %@", err);
                return;
            }
            // 当前文件内容是否 被修改的标志位
            __block BOOL didChange = NO;
            
            // 一定先改扩展的文件的 (因为其名称范围 大于 代码文件名称)
            [needReNameCategoryFileItemMap.allValues enumerateObjectsUsingBlock:^(FileItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // 记录是否修改过 用 "|="
                // 改全名
                didChange |= [self p_reguleChange:filecontent fromFile:path.lastPathComponent match:obj.fileName to:obj.reFileName];
                // 改后半截 (只要有OC代码文件需要)
                if ([obj isOCCodeFile] && [codeFile isOCCodeFile]) {
                    NSArray *oldStrings = [obj.fileName componentsSeparatedByString:@"+"];
                    NSArray *newStrings = [obj.reFileName componentsSeparatedByString:@"+"];
                    if (oldStrings.count == 2 && oldStrings.count == newStrings.count) {
                        NSString *regu_match = [NSString stringWithFormat:@"\\( *%@ *\\)",oldStrings.lastObject];
                        NSString *new = [NSString stringWithFormat:@"(%@)",newStrings.lastObject];
                        didChange |= [self p_reguleChange:filecontent fromFile:path.lastPathComponent match:regu_match regularMatch:regu_match to:new];
                    }else {
                        NSLog(@" 艹 扩展后半截出错拉, 请检查重试 %@", err);
                    }
                }
            }];
            
            // 再改代码文件的
            [needReNameCodeFileItemMap.allValues enumerateObjectsUsingBlock:^(FileItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // 记录是否修改过 用 "|="
                didChange |= [self p_reguleChange:filecontent fromFile:path.lastPathComponent match:obj.fileName to:obj.reFileName];
                // 修改当前文件中的其它类
                [obj.otherClassItems enumerateObjectsUsingBlock:^(OtherClassNameItem * _Nonnull otherClsItem, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (otherClsItem.reClassName.length > 0) {
                        didChange |= [self p_reguleChange:filecontent fromFile:path.lastPathComponent match:otherClsItem.className to:otherClsItem.reClassName];
                    }
                }];
            }];
            
            // 在改Ib文件的
            [needReNameIBFileItemMap.allValues enumerateObjectsUsingBlock:^(FileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // 记录是否修改过 用 "|="
                didChange |= [self p_reguleChange:filecontent fromFile:path.lastPathComponent match:obj.fileName to:obj.reFileName];
            }];
            
            if (didChange) {
                // 回写
                err = nil;
                [filecontent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
                if (err) {
                    NSLog(@"\n\n 艹 回写失败 ： %@", path);
                }
            }
        }
    }];
    
    // 2. 在改开始改文件名
    NSFileManager *film = [NSFileManager defaultManager];
    NSMutableArray *allArr = [NSMutableArray arrayWithCapacity:needRenameFileCount];
    // 这里添加也是有顺序的 先扩展 再代码 再ib
    [allArr addObjectsFromArray:needReNameCategoryFileItemMap.allValues];
    [allArr addObjectsFromArray:needReNameCodeFileItemMap.allValues];
    [allArr addObjectsFromArray:needReNameIBFileItemMap.allValues];
    for (FileItem *item in allArr) {
        if (item.reFileName.length <= 0) {
            continue;
        }
        for (NSString *path in item.absFilesPath) {
            NSString *newName = [NSString stringWithFormat:@"%@.%@", item.reFileName, path.pathExtension];
            NSString *newPath = [item.parentDirectoryABSPath stringByAppendingPathComponent:newName];
            if (NO == [film moveItemAtPath:path toPath:newPath error:nil]) {
                NSLog(@" 艹  rename error -----");
                continue;
            }
            // 修改工程文件
            if ([self p_reguleChange:pbxprojContentString fromFile:pbxprojPath.lastPathComponent match:path.lastPathComponent to:newName] == NO) {
                NSLog(@" 艹  pbxprojContentString change faile ----- %@", path);
            }
        }
    }
    // 2.2 回写工程文件pbxproj
    NSError *err = nil;
    if (![pbxprojContentString writeToFile:pbxprojPath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        NSLog(@" 艹  回写pbxproj error -----%@", err);
    }
    
    NSLog(@"\n\n 完成拉~~~~~~~~~\n");
}
- (nullable NSMutableDictionary<NSString *, OtherClassNameItem *> *)p_matchClassNameFromCodeFile:(NSString *)path regularPat:(NSString *)reguPat swift:(BOOL)isSwift {
    NSError *err = nil;
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:reguPat options:0 error:&err];
    if (!regExp || err) {
        return nil;
    }
    NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (fileContent.length == 0) {
        return nil;
    }
    
    NSArray<NSTextCheckingResult *> *resArr = [regExp matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    if (resArr.count == 0) {
        return nil;
    }
    NSMutableDictionary *classMap = [NSMutableDictionary dictionaryWithCapacity:resArr.count];
    for (NSTextCheckingResult *res in resArr) {
        if (isSwift) {
            if(res.numberOfRanges == 3) {
                NSString *class = [fileContent substringWithRange:[res rangeAtIndex:2]];
                class = [class stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                [classMap setObject:[OtherClassNameItem itemWithClassName:class] forKey:class];
            }else {
                NSLog(@"请检查~~~~1");
            }
        }else {
            if(res.numberOfRanges == 3) {
                NSString *class = [fileContent substringWithRange:[res rangeAtIndex:1]];
                class = [class stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                [classMap setObject:[OtherClassNameItem itemWithClassName:class] forKey:class];
            }else {
                NSLog(@"请检查~~~~2");
            }
        }
    }
    return classMap;
}
#pragma mark - 三方库加前缀
// 这个方法 危险, 仅是为了给三方库加前缀用的 (文件名修改 请使用上面的方法, 单独调用此方法; 文件夹路径仅设置需要修改的库源码文件夹即可)
// 遍历所有代码文件 修改所有符合规则的单词
- (void)nuke___modifyThirdLibary {
    // 重新查找文件
    [self __reset];
    [self p__findVisiableFilesInURL:_rootDirectoryPathURL];
    
    NSString *oldPre = @"AF";
    NSString *newPre = @"XM_AF";
    
    // 构造正则表达式
    NSString *pattern = [NSString stringWithFormat:@"\\b%@.+?\\b", oldPre];
    NSError *err = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&err];
    if (!regex || err) {
        NSLog(@" 艹 正则表达式创建失败, 请检查 %@", err);
        return;
    }
    
    // 全部修改
    for (FileItem *item in _codeFileArr) {
        
        [item.absFilesPath enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableString *mContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            if (mContent.length == 0) {
                NSLog(@" 艹 文件读取失败, 请检查 %@", path);
                return;
            }
            NSArray<NSTextCheckingResult *> *matchRes = [regex matchesInString:mContent options:0 range:NSMakeRange(0, mContent.length)];
            if (matchRes.count == 0) {
                return;
            }
            for (NSInteger i = matchRes.count - 1; i >= 0; i--) {
                NSTextCheckingResult *result = matchRes[i];
                // 只替换前缀即可
                [mContent replaceCharactersInRange:NSMakeRange(result.range.location, oldPre.length) withString:newPre];
            }
            // 回写
            if ([mContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil] == NO) {
                NSLog(@"\n\n 艹 回写失败 ： %@", path);
            }
        }];
        
    }
    
    NSLog(@"\n\n 修改完成啦啦啦");
}

#pragma mark - 混淆标记的字符串
- (void)encryptBtnAction {
    [self p_appendMessage:@"---开始搜索符合条件的文件(.h/.m/.swift)"];
    
    //
    [self __reset];
    [self p__findVisiableFilesInURL:_rootDirectoryPathURL];
    
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 对.h/.m/.swift/.pch 文件",(int)_codeFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个IB文件",(int)_IBFileArr.count]];
    
    [self p_appendMessage:@"开始混淆HardString..."];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 混淆 hard string
        [self p_filterAndEncodeHardString];
    });
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
    
    NSRegularExpression *regExp = nil;
    NSError *err = nil;
    if (item.type == FileIsSwift) {
        regExp = [NSRegularExpression regularExpressionWithPattern:@"(\"\")|(\".*?[^\\\\]\")" options:NSRegularExpressionCaseInsensitive error:&err];
    }else if (item.type == FileIsOnlyM || item.type == FileIsHAndM) {
        regExp = [NSRegularExpression regularExpressionWithPattern:@"(@\"\")|(@\".*?[^\\\\]\")" options:NSRegularExpressionCaseInsensitive error:&err];
    }
    
    if (regExp == nil) {
        // 其它文件不处理
        return;
    }
    
    err = nil;
    NSString *fileCntent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (!fileCntent || err) {
        NSLog(@" 艹 file read failure : %@", err);
        return;
    }
    
    __block BOOL writeback = NO;
    NSString *newContentString = nil;
    
    if (item.type == FileIsSwift) {
        /**
         有一些奇怪的创景还没想好怎么怎么处理 ,先按行匹配
         如
         "aa\(aaa ?? "")"
         "aa\(aaa ? "aa" : "bb")"
         */
        
        // 先按行处理
        NSMutableString *newMString = [NSMutableString stringWithCapacity:fileCntent.length];
        
        [fileCntent enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            NSString *trimLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([trimLine rangeOfString:@"\\("].location != NSNotFound || [trimLine hasPrefix:@"case"] || [trimLine hasPrefix:@"@available("]) {
                // 使用原始行
                [newMString appendString:line];
                [newMString appendString:@"\n"];
                return;
            }
            NSString *newline = [self p__confuseTargetString:line regx:regExp isSwift:YES];
            if (newline.length > 0) {
                writeback = YES;
                [newMString appendString:newline];
                [newMString appendString:@"\n"];
                return;
            }
            // 使用原始行
            [newMString appendString:line];
            [newMString appendString:@"\n"];
        }];
        
        if (writeback) {
            newContentString = newMString;
        }
        //        NSString *changedString = [self p__confuseTargetString:fileCntent regx:regExp isSwift:YES];
        //        if (changedString.length > 0) {
        //            writeback = YES;
        //            newContentString = changedString;
        //        }
    }else {
        // 为了避免匹配到 static const NSString *xx = @""
        // 这里先匹配出 @implementation ... @end 的内容, 然后在匹配字符串
        NSRegularExpression *mContentExp = [NSRegularExpression regularExpressionWithPattern:@"@implementation[\\s\\S]+?@end" options:NSRegularExpressionCaseInsensitive error:&err];
        NSArray<NSTextCheckingResult *> *mContents = [mContentExp matchesInString:fileCntent options:0 range:NSMakeRange(0, fileCntent.length)];
        if (mContents.count == 0) {
            // 这个文件不是.m文件 或者 异常
            return;
        }
        // 新结果
        NSMutableString *newFileContent = [fileCntent mutableCopy];
        // 倒序
        [mContents enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull res, NSUInteger idx, BOOL * _Nonnull stop) {
            // 取出对应部分
            NSString *matchContent = [fileCntent substringWithRange:res.range];
            // 在查找混淆
            NSString *changedString = [self p__confuseTargetString:matchContent regx:regExp isSwift:NO];
            if (changedString.length > 0) {
                [newFileContent replaceCharactersInRange:res.range withString:changedString];
                writeback = YES;
            }
        }];
        if (writeback) {
            newContentString = newFileContent;
        }
    }
    
    if (writeback) {
        // 写回去
        [newContentString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            NSLog(@"\n\n 艹 回写失败 ： %@", path);
        }
    }
}

- (NSString *)p__confuseTargetString:(NSString *)targetString regx:(NSRegularExpression *)regExp isSwift:(BOOL)isSwift {
    // 寻找hard string
    NSArray<NSTextCheckingResult *> *matchs = [regExp matchesInString:targetString options:0 range:NSMakeRange(0, targetString.length)];
    if ([matchs count] <= 0) {
        return nil;
    }
    
    BOOL changed = NO;
    NSMutableString *newString = [targetString mutableCopy];
    // 得倒着来 （为了result.range 替换不出错）
    for (int i = (int)matchs.count - 1; i >= 0; i--) {
        NSTextCheckingResult *result = matchs[i];
        if (isSwift == NO) {
            // OC中的static 或 const 修饰过的字符串, 这里过滤掉, 因为其不能替换为函数获取,  后续可以考虑换为char数组
            NSRange lineRange = [targetString lineRangeForRange:result.range];
            NSString *lineString = [targetString substringWithRange:lineRange];
            if ([lineString containsString:@"static "] || [lineString containsString:@"const "]) {
                NSLog(@"跳过 OC中的static或const修饰过的字符串: %@",
                      [lineString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
                continue;
            }
        }
        NSString *matchedString = [targetString substringWithRange:result.range];
        NSString *hardStringCode = nil;
        if (isSwift) {
            hardStringCode = [matchedString substringWithRange:NSMakeRange(1, matchedString.length - 2)];
        }else{
            hardStringCode = [matchedString substringWithRange:NSMakeRange(2, matchedString.length - 3)];
        }
        if (hardStringCode.length == 0) {
            // 空串不需混淆
            continue;
        }
        
        // 混淆编码
        NSString *encriptedStr = XYZ_encriptHardString(hardStringCode);
        if (encriptedStr.length == 0) {
            NSLog(@"注意啦注意啦: 硬编码字符串加密有bug啦啦~");
            continue;
        }
        NSString *new = nil;
        if (isSwift) {
            new = [NSString stringWithFormat:@"XYZ_decriptHardString(\"%@\")", encriptedStr];
        }else {
            new = [NSString stringWithFormat:@"XYZ_decriptHardString(@\"%@\")", encriptedStr];
        }
        
        if (new.length == 0) {
            NSLog(@"注意啦注意啦: 创建字符串失败啦~");
            continue;
        }
        // 替换回去
        [newString replaceCharactersInRange:result.range withString:new];
        changed = YES;
        //测试
        //        NSLog(@"加密验证结果: %d", [XYZ_decriptHardString(encriptedStr) isEqualToString:matchSubContent]);
    }
    return changed ? newString : nil;
}
@end
