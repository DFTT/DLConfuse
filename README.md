# DLConfuse

### 类名混淆
    TODO: ...

### 静态敏感字符串混淆
支持.h/.m/.swift文件中的各种hardString (static NSString * const 这种不支持)

1. 自行添加pch头文件
2. 在增加两个宏定义
```
//以下内容添加于pch头文件
// 标识字符串
#define FlAG_ENCODE_STRING(str) str
// 解密字符串 (自动化处理), 此C方法为动态解密方法
extern id xm_realString(id input); 
#define DECODE_STRING(str) xm_realString(str)
```
3. 添加一个Marco.swift文件 (如果无swift代码 可跳过)
```
//以下内容添加Macros.swift文件
func FlAG_ENCODE_STRING(_ clearStr: String) -> String {
    return clearStr
}

func DECODE_STRING(_ cipherStr: String) -> String {
    if cipherStr.isEmpty {
        return ""
    }
    
    var result = cipherStr.replacingOccurrences(of: "\\?|\\<|\\!|\\*|\\>|\\]", with: "", options: String.CompareOptions.regularExpression, range:  Range<String.Index>(NSRange(location: 0, length: cipherStr.count), in: cipherStr) )
    
    guard let data = Data(base64Encoded: result) else {
        return ""
    }
    
    result = String(data: data, encoding: .utf8) ?? ""
    result = result.replacingOccurrences(of: "\\n", with: "\n")
    return result
}
```
4. 增加一个C解密方法 <此解密方和自动化处理的加密方法配套，如需自定义->请同时修改>
```
// base64Str “中间插入了（#><）符号”
NSString *xm_realString(NSString *base64Str) {
    if (STTUtils.validString(base64Str) == NO) {
        return @"";
    }
    
    NSString *result = [base64Str stringByReplacingOccurrencesOfString:@"\\?|\\<|\\!|\\*|\\>|\\]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, base64Str.length)];
    result = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:result options:0] encoding:NSUTF8StringEncoding];
    result = [result stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    return result;
}
```
5. 提前在项目中使用FlAG_ENCODE_STRING()包裹需要加密的字符串，运行工具，即可完成替换
