# File Tagger Pro

一个基于Qt6和现代C++的高性能文件标签管理系统，提供强大的文件组织、标签管理和预览功能。

## 项目概述

File Tagger Pro 是一款专注于文件标签管理的桌面应用程序，采用Qt6 + QML技术栈开发，支持高效的文件组织、智能标签管理和实时文件预览功能。本项目采用现代C++17标准开发，确保了代码的高效性和可维护性。

## 核心特性

### 文件管理
- 🔍 智能文件扫描与索引
  - 支持递归目录扫描
  - 实时文件系统监控
  - 增量更新机制
- 📋 高效文件操作
  - 批量文件处理
  - 拖拽支持
  - 快速预览

### 标签系统
- 🏷️ 灵活的标签管理
  - 层级标签结构
  - 智能标签建议
  - 批量标签操作
- 🔍 高级搜索
  - 多条件组合查询
  - 标签过滤
  - 实时搜索结果

### 用户界面
- 🎨 现代化UI设计
  - Material Design 3
  - 深色/浅色主题
  - 响应式布局
- 📱 多视图支持
  - 列表/网格/详情视图
  - 自定义视图配置
  - 视图切换动画

## 技术栈

- **前端框架**: Qt 6.5+ / QML
- **后端语言**: C++17
- **构建工具**: CMake 3.16+
- **依赖管理**: vcpkg
- **版本控制**: Git
- **代码规范**: Qt Coding Style

## 系统要求

### 最低配置
- **操作系统**: Windows 10 64位 (版本 1909 或更高)
- **处理器**: Intel/AMD 双核处理器
- **内存**: 4GB RAM
- **存储**: 200MB 可用空间
- **显卡**: 支持 OpenGL 3.3

### 推荐配置
- **操作系统**: Windows 11 64位
- **处理器**: Intel/AMD 四核处理器
- **内存**: 8GB RAM
- **存储**: 500MB SSD
- **显卡**: 独立显卡，支持 OpenGL 4.0

## 开发环境配置

### 必需组件
1. **Qt开发环境**
   ```bash
   # 安装Qt 6.5.0或更高版本
   # 必选组件：
   # - MSVC 2019 64-bit
   # - Qt Quick/QML
   # - Qt Multimedia
   ```

2. **编译工具**
   - Visual Studio 2019/2022 (推荐)
   - CMake 3.16+
   - vcpkg包管理器

### 构建步骤
1. 克隆仓库
   ```bash
   git clone https://github.com/yourusername/file-tagger-pro.git
   cd file-tagger-pro
   ```

2. 配置vcpkg依赖
   ```bash
   vcpkg install ffmpeg:x64-windows
   vcpkg install boost:x64-windows
   ```

3. 构建项目
   ```bash
   mkdir build && cd build
   cmake -DCMAKE_TOOLCHAIN_FILE=[vcpkg root]/scripts/buildsystems/vcpkg.cmake ..
   cmake --build . --config Release
   ```

## 项目结构

```
file-tagger-pro/
├── src/                    # 源代码目录
│   ├── core/              # 核心功能实现
│   ├── models/            # 数据模型
│   └── utils/             # 工具类
├── qml/                   # QML界面文件
├── resources/             # 资源文件
└── CMakeLists.txt        # CMake配置文件
```

## 贡献指南

### 开发流程
1. Fork 项目仓库
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范
- 遵循Qt代码规范
- 使用驼峰命名法
- 保持代码注释完整
- 编写单元测试

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式

- **项目主页**: [GitHub](https://github.com/yourusername/file-tagger-pro)
- **问题反馈**: [Issues](https://github.com/yourusername/file-tagger-pro/issues)
- **邮件联系**: your.email@example.com

## 更新日志

### v0.1.0 (2023-11-29)
- 初始版本发布
- 实现基础文件扫描功能
- 添加标签管理系统
- 支持文件预览