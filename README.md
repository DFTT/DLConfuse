# DLConfuse

### class混淆(应该不能过审马甲包...)
一个简单的OC代码混淆（本着宁可放过，也不混错的原则）

##### 原理：

深度遍历指定目录，寻找同文件夹下同名的.h/.m文件，并且解析出其中的className，生成宏定义文件（默认写到桌面），需要吧生成的宏定义文件在pch文件中import导入即可。

##### 手动检查：

导入宏定义文件后，要在编译警告中搜索redefine，如有需要手动处理（避免定义多次），
小心plist文件中写死的类名，比如部分扩展Target的入口controllerName就不能改名。

#####注意事项：

1. xib/storyboard中包含的类名不能混淆（已经支持）.
2. @"xxx"静态字符串包含的类名不能混淆（基本支持，如果是接口返回的字符串或者拼接的字符串暂未支持）.

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
