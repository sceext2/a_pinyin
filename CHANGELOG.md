<!-- CHANGELOG.md, a_pinyin/
-->

# A拼音 更新日志


## a_pinyin version 1.3.1 test20180621 2344

+ 增加镜像, 应对不稳定的复杂网络环境.

  目前共有 4 个镜像: (含项目主页)

  + <https://bitbucket.org/sceext2018/a_pinyin/>
  + <https://github.com/sceext-mirror-201806/a_pinyin>
  + <https://gitee.com/sceext2133/a_pinyin>
  + <https://coding.net/u/sceext2133/p/a_pinyin>

+ 修复 (apk/UI): 下载数据库时可选择使用不同的镜像.

+ 修复 (apk/UI): 自定义输入 界面添加文本框的 placeholder 文本颜色.


## a_pinyin version 1.3.0 test20180621 0900

+ 转移项目代码至 [bitbucket.org](https://bitbucket.org/sceext2018/a_pinyin/)
  并在 [github 上建立镜像](https://github.com/sceext-mirror-201806/a_pinyin).

  数据库现在从 bitbucket 下载.

+ 新增功能 (apk/UI): 粘贴按钮, 可以快速输入剪切版中的内容.

+ 新增功能 (apk): 自定义输入, 可以添加符号/短语等, 补充本输入法没有自带的符号, 或者方便快速输入短语.

+ 优化 (apk/UI): 界面颜色, 改进 深色界面 外观.

+ 重写 (apk/UI): 用户界面代码, 提高了界面性能 (响应时间).

+ 其它细节优化

### 已知问题

+ 键盘界面的滚动部分 (`ScrollView`, `FlatList` 等组件) 在本应用的主界面之下无法操作.
  也就是说, 使用本输入法向本输入法的应用界面 (文本框) 中进行输入, 会存在 BUG, 部分输入功能无法使用.
  (自己向自己输入有 BUG)

  但是使用本输入法向其它应用中进行输入一切正常.

  这是个 `react-native` 相关的问题, 目前还没有找到解决办法.

+ 由于 `react-native` 框架工作原理的限制, 使用本输入法时, 需要保持本应用的主界面打开.
  关闭本应用主界面后, 会造成键盘界面无法显示, 或者键盘界面失去响应无法操作等问题.

  如果出现这种情况, 将本应用的主界面再次打开即可.
  如果还无法解决, 请尝试强行终止本应用, 然后再重新打开.

+ 启用本输入法之后, 根据 Android 系统的设计, 本输入法会一直在后台长期运行.
  然而, 本输入法长期运行之后, 用户界面可能会出现响应缓慢/卡顿等问题.

  强行终止本应用后再重新打开, 即可解决此问题, 恢复快速运行.

  如果不会强行终止应用的操作, 卸载本输入法再重新安装也可达到相同的效果.
  卸载本输入法后, 用户数据 (记录用户常用的字词等, 用于学习用户的输入习惯) 不会丢失,
  再次安装即可继续使用.

  这个问题估计也和 `react-native` 高度相关.


## a_pinyin version 1.2.0 test20180604 1147

+ 新增功能 (apk/UI): 按键振动, 振动时长可设置, 设为 0 禁用振动

+ 新增功能 (apk): 启用生僻汉字, 除了常用 7,000 汉字之外, 还可输入 Unicode 10.0 标准中收录的 3 万多个生僻汉字

+ 新增功能 (apk): 显示更多数据库信息

+ 新增功能 (apk): 整理 (优化) 用户数据库

+ 新增功能 (apk/UI): 设置界面, 可集中进行多项设置

+ 新增功能 (apk/UI): 自动下载数据库功能改进, 显示提示框 (Alert)

+ 新增功能 (apk/UI): 处理硬件返回按钮

+ 新增功能 (apk/DEBUG): 添加 react-devtools, 调试版 显示 DEV 字样

+ 代码优化: 使用 react-native 的 StyleSheet 定义样式


## a_pinyin version 1.1.0 test20180601 0028

+ 新增功能 (apk/UI): 安装后可自动下载数据库

+ 新增功能 (apk/UI): 首次启动自动请求读写存储权限

+ 新增功能 (apk/UI): 关于界面文本可选择

+ 代码清理


## a_pinyin version 1.0.0 test20180525 0150

+ 发布首个版本

+ 主要功能

  + 非汉字输入: 数字, 大小写英文字母, ASCII 符号, 中文标点等更多常用符号
  + 汉字输入 (拼音输入): 拼音切分, 单个汉字输入, 多字输入 (词组 及 语句 输入)
  + 用户语言模型: 记录 用户输入 的 字/词 等, 学习用户输入特征
  + 无痕模式
  + 用户界面样式: 深色 / 浅色 两种 颜色主题

+ 主要核心模型/算法

  + 马尔可夫模型 / 隐马尔可夫模型 (Hidden Markov Model, HMM), n-best Viterbi 算法
  + 词典 (词频)

+ 主要使用技术

  + react-native
  + Android 输入法框架
  + gradle
  + kotlin
  + coffeescript
  + kryo
  + JSON / klaxon
  + sqlite3
  + HanLP

<!-- end CHANGELOG.md -->
