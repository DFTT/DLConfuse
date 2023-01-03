# DLConfuse

使用前请把git工作区/暂存区清空，避免修改出错无法回滚

### 类名混淆 (修改后基本不会报错)
对项目中OC/Swift代码文件进行前缀修改, 包括对```.xcodeproj```及IB文件的修改
1. 修改和文件同名的类名 
2. 修改代码文件中其它符合前缀匹配的类名 (swift文件还包括 struct enum protocol)
3. 对于前缀不匹配但是类型第二个字符为小写字母的类名, 会直接添加新前缀 
4. 可设置过滤文件夹不修改

### 静态敏感字符串混淆
支持.h/.m/.swift文件中的各种hardString (static NSString * const 这种不支持)
可以自定义字符串混淆方法(见HardStringEncryptDecryptUnit.h)
1. HardStringEncryptDecryptUnit.h文件放入混淆的项目中, 并在pch文件中导入, 如果有swift代码, 需要在桥接文件中也导入 (目的是为了访问解密函数XYZ_decriptHardString())
2. 运行工具，即可完成替换

### 修改目录名称(深度遍历)xco
给定一个目录, 自动深度遍历并修改文件夹名称. (仅修改磁盘目录, 不会修改xcodeproj中的引用, 因此需要修改后, 重新拖入xcode, 并且重新设置build setting中的PCH文件路径 / oc-swift-bridge文件路径)
1. 自动删除空目录
2. 目前名称的修改方式仅仅为吧后两个字母移动前前面 (可以修改, 有更好的方案我在修改, 本想通过词典找近义词, 但没找到本地的词典接口)
3. 可设置过滤文件夹不修改

