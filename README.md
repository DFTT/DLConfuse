# DLConfuse

使用前请把git工作区/暂存区清空，避免修改出错无法回滚

### 类名混淆 (修改后基本不会报错)
对项目中代码文件进行前缀修改，同时修改和文件同名的类名, 包括对```.xcodeproj```及IB文件的修改 

### 静态敏感字符串混淆
支持.h/.m/.swift文件中的各种hardString (static NSString * const 这种不支持)
可以自定义字符串混淆方法(见HardStringEncryptDecryptUnit.h)
1. HardStringEncryptDecryptUnit.h文件放入混淆的项目中, 并在pch文件中导入, 如果有swift代码, 需要在桥接文件中也导入 (目的是为了访问解密函数XYZ_decriptHardString())
2. 运行工具，即可完成替换
