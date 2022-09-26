# DLConfuse

运行工具, 先选择需要处理的目录, 在执行不同动作

### 类名混淆
    目前支持前缀修改, 包括ib文件中的修改 (准确率较高)

### 静态敏感字符串混淆
支持.h/.m/.swift文件中的各种hardString (static NSString * const 这种不支持)

可选: 可以自定义混淆方案(见HardStringEncryptDecryptUnit.h)
1. HardStringEncryptDecryptUnit.h文件放入混淆的项目中, 并在pch文件中导入, 如果有swift代码, 需要在桥接文件中也导入 (目的是为了访问解密函数XYZ_decriptHardString())
2. 运行工具，即可完成替换
