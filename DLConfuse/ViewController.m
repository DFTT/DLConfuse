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
    // shuchu目录
    NSString *_outDirectoryPath;
    
    
    //.h / .m
    NSMutableArray<FileItem *> *_visiableFileArr;
    // .xib  .stroryboare
    NSMutableArray<FileItem *> *_IBFileArr;
    
    
    // 类名arr
    NSMutableArray<NSString *> *_classNameArr;
    // 静态字符串set
    NSMutableSet<NSString *> *_hardStringSet;
    
    
    
    // UI
    NSTextView *_messageView;
}
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // init
    [self __reset];
    
    
    NSURL *path = [[[NSFileManager defaultManager] URLsForDirectory:NSDesktopDirectory inDomains:NSUserDomainMask] firstObject];
    _outDirectoryPath = path.path;
    
    [self setupUI];
}
- (void)__reset {
    _visiableFileArr = [[NSMutableArray alloc] init];
    _IBFileArr       = [[NSMutableArray alloc] init];
    _classNameArr    = [[NSMutableArray alloc] init];
    _hardStringSet   = [[NSMutableSet alloc] init];
}
#pragma mark - UI
- (void)setupUI {
    // btn
    NSButton *btn  = [[NSButton alloc] initWithFrame:CGRectMake(10, 60, 100, 50)];
    btn.bezelStyle = NSBezelStyleRounded;
    [btn setTitle:@"选择代码目录"];
    [btn setTarget:self];
    [btn setAction:@selector(btnClickAction)];
    [self.view addSubview:btn];
    
    //
    NSButton *start  = [[NSButton alloc] initWithFrame:CGRectMake(10, 10, 100, 50)];
    start.bezelStyle = NSBezelStyleRounded;
    [start setTitle:@"开始混淆"];
    [start setTarget:self];
    [start setAction:@selector(startBtnAction)];
    [self.view addSubview:start];
    
    //
    NSScrollView *scrolleView = [[NSScrollView alloc] initWithFrame:CGRectMake(120, 10, 800, self.view.bounds.size.height - 10)];
    [scrolleView setHasVerticalScroller:YES];
    [scrolleView setHasHorizontalScroller:NO];
    [self.view addSubview:scrolleView];
  
    NSTextView *textView = [[NSTextView alloc] initWithFrame:CGRectMake(120, 10, 800, self.view.bounds.size.height - 10)];
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

- (void)startBtnAction {
    [self p_appendMessage:@"---开始搜索符合条件的文件(.h/.m)"];
    
    
    [self p_findVisiableFilePath:_rootDirectoryPath];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 对文件",(int)_visiableFileArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个IB文件",(int)_IBFileArr.count]];
    
    
    // 必须在.h .m文件中找到声明和实现 、 静态字符串
    [self p_findClassName];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个className",(int)_classNameArr.count]];
    [self p_appendMessage:[NSString stringWithFormat:@"---共找到 %d 个Hard String",(int)_hardStringSet.count]];
    
    // 混淆 hard string
    [self p_filterAndEncodeHardString];
return;
    // 过滤掉 声明为静态字符串的类名 && 过滤掉IBFile中包含的类名
    NSArray<NSString *> *newArr = [self p_filter];

    // 开始生成宏定义文件
    [self p_creatFileWithArr:newArr];
}

//- (void)
#pragma mark - 查找符合条件的文件
- (void)p_findVisiableFilePath:(NSString *)rootPath {
    
    if (rootPath.length == 0) {
        return;
    }
    
    NSFileManager *fileM = [NSFileManager defaultManager];
    
    
    NSError       *err        = nil;
    NSMutableSet *subhFileArr = [[NSMutableSet alloc] init];
    NSMutableSet *submFileArr = [[NSMutableSet alloc] init];
    
    NSArray<NSString *> *contents = [fileM contentsOfDirectoryAtPath:rootPath error:&err];
    if (err) {
        NSLog(@"contents error = %@", err);
        return;
    }
    //
    NSMutableArray *subDirectoryABSPathArr = [[NSMutableArray alloc] init];
    for (NSString *subpath in contents) {
        
        NSString *absPath = [rootPath stringByAppendingPathComponent:subpath];
        if ([fileM isReadableFileAtPath:absPath] == NO) {
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
                NSLog(@"过滤文件目录 : %@", subpath);
            }
            continue;
        }
    }
    for (NSString *h in subhFileArr) {
        NSString *temp = [h stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
        if ([submFileArr containsObject:temp]) {
            FileItem *item              = [[FileItem alloc] init];
            item.fileName               = [h stringByReplacingOccurrencesOfString:@".h" withString:@""];
            item.parentDirectoryABSPath = rootPath;
            [_visiableFileArr addObject:item];
        }
    }
    for (NSString *absDir in subDirectoryABSPathArr) {
        [self p_findVisiableFilePath:absDir];
    }
}

#pragma mark - 查找类名
- (void)p_findClassName {
    
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:@"@\".+?\"" options:NSRegularExpressionCaseInsensitive error:nil];
    
    for (FileItem *item in _visiableFileArr) {
        // 过滤扩展
        if ([item.fileName containsString:@"+"]) {
            continue;
        }
        // .h
        NSMutableSet *h_class = [[NSMutableSet alloc] init];
        // .m
        NSMutableSet *m_class = [[NSMutableSet alloc] init];
        for (int i = 0; i < 2; i++) {
            NSError *err         = nil;
            NSString *path       = (i == 0 ? [item abs_h_FilePath] : [item abs_m_FilePath]);
            NSString *fileCntent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
            if (!fileCntent || err) {
                NSLog(@"file read failure : %@", err);
                continue;
            }
            // 应该过滤掉注释内容
            
            
            // 寻找静态字符串
            NSArray<NSTextCheckingResult *> *matchs = [regExp matchesInString:fileCntent options:0 range:NSMakeRange(0, fileCntent.length)];
            for (NSTextCheckingResult *result in matchs) {
                [_hardStringSet addObject:[fileCntent substringWithRange:result.range]];
            }
            
            // 按行找className
            NSArray *lines = [fileCntent componentsSeparatedByString:@"\n"];
            if (lines.count == 0) {
                NSLog(@"file content number == 0");
                continue;
            }
            for (NSString *lineString in lines) {
                if (i == 0) {
                    // .h
                    NSArray *temparr = [lineString componentsSeparatedByString:@"@interface"];
                    if (temparr.count <= 1) {
                        continue;
                    }
                    temparr = [[temparr lastObject] componentsSeparatedByString:@":"];
                    if (temparr.count <= 1) {
                        continue;
                    }
                    NSString *classN = [[temparr firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (!classN || classN.length == 0) {
                        continue;
                    }
                    [h_class addObject:classN];
                }else {
                    // .m
                    NSArray *temparr = [lineString componentsSeparatedByString:@"@implementation"];
                    if (temparr.count <= 1) {
                        continue;
                    }
                    NSString *newLine = [[temparr lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    temparr = [newLine componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ("]];
                    
                    NSString *classN = [[temparr firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (!classN || classN.length == 0) {
                        continue;
                    }
                    [m_class addObject:classN];
                }
            }
        }
        // 过滤
        for (NSString *h in h_class.allObjects) {
            if ([m_class containsObject:h]) {
                [_classNameArr addObject:h];
            }
        }
    }
}
#pragma mark - 开始过滤
- (NSArray<NSString *> *)p_filter {
    
    NSMutableString *IBContent = [[NSMutableString alloc] init];
    NSError *err = nil;
    for (FileItem *IB_Item in _IBFileArr) {
        NSString *filePath = [IB_Item.parentDirectoryABSPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", IB_Item.fileName]];
        NSString *fileCntent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
        if (!fileCntent || err) {
            NSLog(@"IB File read failure : %@", err);
            continue;
        }
        [IBContent appendString:fileCntent];
    }
    
    NSMutableArray<NSString *> *newClassArr = [[NSMutableArray alloc] initWithCapacity:_classNameArr.count];
    for (NSString *claName in _classNameArr) {
        if ([_hardStringSet containsObject:[NSString stringWithFormat:@"@\"%@\"",claName]]) {
            NSLog(@"过滤静态字符串包含中包含的: %@",claName);
            continue;
        }
        if ([IBContent rangeOfString:claName].location != NSNotFound) {
            NSLog(@"过滤IB中包含的: %@",claName);
            continue;
        }
        [newClassArr addObject:claName];
    }
    return newClassArr;
}

#pragma mark - creat file
- (void)p_creatFileWithArr:(NSArray<NSString *> *)arr {
    // start obfuscator
    NSMutableString *result = [[NSMutableString alloc] init];
    [result appendString:@"\n\n#if (DEBUG != 1)\n\n//--------------------DLConfuse--------------------\n\n"];

    for (NSString *claName in arr) {
        // confuse class name
        NSString *newStr = [NSString stringWithFormat:@"#ifndef %@\n#define %@ DL%@\n#endif\n",claName, claName, MD5_32(claName)];
        [result appendString:newStr];
        // 记录混淆map
        
    }
    [result appendString:@"\n#endif\n//------------------------------------------------------\n\n\n"];
    // update headerFile
    NSData *data      = [NSData dataWithBytes:result.UTF8String length:result.length];

    NSString *outPath = [_outDirectoryPath stringByAppendingPathComponent:@"DLConfuse.h"];
    BOOL flag         = [data writeToFile:outPath atomically:YES];
    NSLog(@"--写入结果-%d",flag);
    if (flag) {
        [self p_appendMessage:[NSString stringWithFormat:@"---文件写入成功：%@",outPath]];
    }
}

#pragma mark - 加密 hard string <金币,现金,钱,赚,红包,提现,任务>
- (void)p_filterAndEncodeHardString {
    
    NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:@"FlAG_ENCODE_STRING\\(.+?\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    
    for (FileItem *item in _visiableFileArr) {
        NSError *err         = nil;
        NSString *path       = [item abs_m_FilePath];
        NSString *fileCntent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
        if (!fileCntent || err) {
            NSLog(@"file read failure : %@", err);
            continue;
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
                NSString *matchSubContent = [matchSub substringWithRange:NSMakeRange(21, result.range.length - 21 - 2)];
                // 混淆编码
                NSMutableString *mTmp = [[[matchSubContent dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0] mutableCopy];
                for (NSString *ch_ar in char_Arr) {
                    [mTmp insertString:ch_ar atIndex:arc4random() % mTmp.length];
                }
                matchSub = [NSString stringWithFormat:@"DECODE_STRING(@\"%@\")", mTmp];
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
    
    [self p_appendMessage:[NSString stringWithFormat:@"---hard string 处理结束"]];
}
@end







