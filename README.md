# 文件标签应用 (FileTaggingApp)

一个基于Qt6开发的现代化文件管理和标签工具,支持文件预览、实时监控和多种视图模式。本应用采用 C++17 和 QML 开发,提供高性能的文件操作和流畅的用户体验。

## 功能特点

### 核心功能
- 📁 文件系统实时监控
  - 自动检测文件变更
  - 支持递归监控子目录
  - 可配置监控过滤器
- 🏷️ 文件标签管理
  - 自定义标签分类
  - 批量标签操作
  - 标签搜索和过滤
- 🖼️ 文件预览功能
  - 支持主流图片格式 (JPG, PNG, GIF, BMP, WebP)
  - 集成FFmpeg视频预览 (MP4, AVI, MKV等)
  - 异步预览生成
  - 智能预览缓存
- 📊 多视图模式
  - 列表视图
  - 大图标视图
  - 可自定义缩略图大小
- 🔍 高级搜索功能
  - 文件名搜索
  - 标签过滤
  - 文件类型筛选
  - 大小和日期范围过滤
- 📝 文件信息显示
  - 基础文件属性
  - 媒体文件元数据
  - 自定义标签信息

### 用户界面
- Material Design 风格界面
  - 符合现代设计规范
  - 视觉层次分明
  - 流畅的动画过渡
- 自适应布局
  - 响应式设计
  - 可调节分割面板
  - 自动适应窗口大小
- 主题支持
  - 深色/浅色主题切换
  - 主题色自定义
  - 高对比度支持
- 交互优化
  - 拖放操作支持
  - 右键菜单定制
  - 快捷键支持
- 多语言支持
  - 中文简体/繁体
  - 英文
  - 可扩展的翻译系统

### 技术特性
- 异步操作
  - 多线程文件扫描
  - 异步预览生成
  - 后台缓存管理
- 缓存系统
  - 预览图片缓存
  - 文件信息缓存
  - 自动清理机制
- 性能优化
  - 延迟加载
  - 虚拟滚动
  - 内存占用优化
- FFmpeg集成
  - 视频帧提取
  - 格式转换
  - 硬件加速支持
- 插件系统
  - 预览插件扩展
  - 自定义操作插件
  - 标签规则插件

## 系统要求

### 运行环境
- 操作系统
  - Windows 10/11 (64位)
  - Linux (计划支持)
  - macOS (计划支持)
- 依赖组件
  - Qt 6.2+
  - FFmpeg 4.0+
  - OpenGL 3.3+
- 硬件要求
  - CPU: 双核及以上
  - 内存: 4GB及以上
  - 显卡: 支持OpenGL 3.3
  - 存储: 500MB可用空间

### 开发环境
- IDE和工具
  - Qt Creator 6.0+
  - Visual Studio 2019+ (Windows)
  - CMake 3.16+
- 编译器要求
  - MSVC 2019+ (Windows)
  - GCC 8+ (Linux)
  - Clang 10+ (macOS)
- 开发依赖
  - C++17 兼容编译器
  - Qt 6.2+ 开发包
  - FFmpeg 开发库
  - CMake 构建系统

## 安装说明

### Windows 安装
1. 安装依赖
   - 下载并安装 Visual C++ Redistributable 2019+
   - 安装 FFmpeg 4.0+ 并添加到系统环境变量
   - 确保 OpenGL 驱动已更新

2. 应用安装
   - 下载最新发布版本
   - 运行安装程序
   - 按照向导完成安装

### 开发环境配置
1. 安装开发工具
   ```bash
   # 安装 Qt Creator 和 Qt 6.2+
   # 安装 Visual Studio 2019+ (Windows)
   # 安装 CMake 3.16+
   ```

2. 配置FFmpeg
   ```bash
   # 设置 FFMPEG_ROOT 环境变量
   # Windows示例:
   set FFMPEG_ROOT=D:/Environment/ffmpeg
   ```

3. 构建项目
   ```bash
   mkdir build
   cd build
   cmake ..
   cmake --build .
   ```

## 使用指南

### 快速开始
1. 启动应用
2. 选择要监控的文件夹
3. 配置文件过滤器
4. 开始使用文件管理功能

### 常用操作
- 文件预览: 双击文件
- 添加标签: 右键菜单 -> 添加标签
- 切换视图: 工具栏视图按钮
- 搜索文件: 使用顶部搜索栏

### 高级功能
- 自定义过滤器
- 批量标签操作
- 预览设置调整
- 插件管理

## 贡献指南

### 开发流程
1. Fork 项目
2. 创建特性分支
3. 提交变更
4. 发起 Pull Request

### 编码规范
- 遵循 Qt 编码规范
- 使用 C++17 特性
- 保持代码文档完整

### 测试要求
- 单元测试覆盖
- 界面测试
- 性能测试

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式

- 项目主页: [GitHub](https://github.com/yourusername/FileTaggingApp)
- 问题反馈: [Issues](https://github.com/yourusername/FileTaggingApp/issues)
- 邮件联系: your.email@example.com

## 架构设计

### 核心模块
- 文件系统管理器 (FileSystemManager)
  - 文件监控与变更检测
  - 文件元数据管理
  - 文件操作接口
- 预览生成器 (PreviewGenerator)
  - 异步预览生成
  - 缓存管理
  - 格式转换
- 模型层 (Models)
  - FileListModel: 文件列表数据模型
  - FileData: 文件数据结构
  - TagModel: 标签管理模型
- 界面层 (UI)
  - QML组件化设计
  - MVVM架构模式
  - 响应式数据绑定

### 数据流
```
[文件系统] -> [FileSystemManager] -> [FileListModel] -> [UI视图]
                      |                     |
                      v                     v
              [PreviewGenerator]    [标签管理系统]
```

## 开发文档

### 项目结构
```
FileTaggingApp/
├── src/
│   ├── core/           # 核心功能模块
│   ├── models/         # 数据模型
│   ├── utils/          # 工具类
│   └── main.cpp        # 程序入口
├── qml/
│   ├── components/     # QML组件
│   ├── dialogs/        # 对话框
│   └── utils/          # QML工具
├── resources/          # 资源文件
│   ├── images/         # 图标和图片
│   └── translations/   # 翻译文件
└── tests/              # 测试用例
```

### 关键类说明

#### FileSystemManager
```cpp
class FileSystemManager : public QObject {
    // 文件系统管理核心类
    // 负责文件监控、扫描和操作
};
```

#### PreviewGenerator
```cpp
class PreviewGenerator : public QObject {
    // 预览生成器
    // 支持图片和视频预览
};
```

#### FileListModel
```cpp
class FileListModel : public QAbstractListModel {
    // 文件列表数据模型
    // 支持排序、过滤和搜索
};
```

### API 文档

#### 文件操作 API
```cpp
// 文件扫描
void scanDirectory(const QString &path);

// 文件监控
void startWatching(const QString &path);
void stopWatching();

// 预览生成
void generatePreview(const QString &filePath);
```

#### 标签操作 API
```cpp
// 标签管理
void addTag(const QString &filePath, const QString &tag);
void removeTag(const QString &filePath, const QString &tag);
QStringList getTags(const QString &filePath);
```

## 性能优化

### 文件扫描优化
- 使用多线程异步扫描
- 实现增量更新机制
- 采用文件系统事件监听

### 预览生成优化
- 后台线程预览生成
- 智能缓存策略
- 预览大小自适应

### 内存管理
- 延迟加载机制
- 资源自动释放
- 缓存大小限制

## 常见问题

### 安装相关
1. FFmpeg配置问题
   ```bash
   # 检查FFmpeg配置
   echo %FFMPEG_ROOT%
   # 确保包含以下目录
   %FFMPEG_ROOT%/bin
   %FFMPEG_ROOT%/lib
   %FFMPEG_ROOT%/include
   ```

2. Qt环境问题
   - 确保Qt版本 >= 6.2
   - 检查环境变量设置
   - 验证Qt插件可用性

### 运行相关
1. 文件预览不显示
   - 检查FFmpeg配置
   - 确认文件格式支持
   - 查看日志输出

2. 性能问题
   - 调整预览缓存大小
   - 限制监控目录深度
   - 优化文件过滤设置

## 更新日志

### v1.0.0 (2024-03)
- 初始版本发布
- 基础文件管理功能
- 图片和视频预览支持

### v1.1.0 (计划中)
- 添加标签管理系统
- 优化预览生成性能
- 支持更多文件格式

## 路线图

### 近期计划
- [ ] 完善标签系统
- [ ] 添加文件搜索功能
- [ ] 优化预览生成性能

### 长期计划
- [ ] 跨平台支持
- [ ] 云同步功能
- [ ] 插件系统

## 参与贡献

### 提交规范
- feat: 新功能
- fix: 修复问题
- docs: 文档更新
- style: 代码格式
- refactor: 重构
- test: 测试相关
- chore: 构建相关

### 分支管理
- main: 主分支
- develop: 开发分支
- feature/*: 特性分支
- bugfix/*: 修复分支

## 技术支持

### 资源链接
- [Qt文档](https://doc.qt.io/)
- [FFmpeg文档](https://ffmpeg.org/documentation.html)
- [项目Wiki](https://github.com/yourusername/FileTaggingApp/wiki)

### 社区支持
- [GitHub Discussions](https://github.com/yourusername/FileTaggingApp/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/filetaggingapp)
- QQ群: 123456789

## 赞助支持

如果您觉得这个项目对您有帮助,欢迎赞助支持我们的开发:

- 微信/支付宝打赏
- GitHub Sponsors
- OpenCollective

## 致谢

感谢以下开源项目:
- Qt Framework
- FFmpeg
- OpenCV
- 以及所有贡献者