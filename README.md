# 我的血压 (My Blood Pressure)

这是一个使用 Flutter 开发的个人血压管理应用程序，旨在帮助用户轻松记录、追踪和分析血压数据，关注心血管健康。

## ✨ 主要功能

*   **📊 仪表盘 (Dashboard)**
    *   直观展示血压数据的统计信息和趋势。
    *   可视化图表支持，帮助用户快速了解健康状况变化。
    *   显示最近更新时间和数据概览。

*   **📝 记录管理**
    *   **添加记录**：轻松录入收缩压（高压）、舒张压（低压）、心率以及备注信息。
    *   **历史记录**：查看所有过往的测量数据列表。
    *   **标签分类**：支持为每条记录添加标签（如“晨起”、“服药后”、“运动后”），便于分类分析。

*   **⚙️ 标签管理**
    *   用户可以自定义标签（添加、修改、删除）。
    *   支持设置标签名称和颜色，个性化管理记录场景。

*   **⏰ 智能提醒**
    *   支持设置每日测量提醒。
    *   **智能逻辑**：如果当天已经记录过血压，系统将自动跳过当天的提醒，避免打扰。

*   **📤 数据导出**
    *   支持将所有血压记录导出为 CSV 文件。
    *   方便用户备份数据或与医生分享健康记录。

*   **🎨 个性化设置**
    *   支持更换用户头像（内置多种健康相关图标）。

## 🛠️ 技术栈

本项目基于 Flutter 构建，使用了以下关键技术和库：

*   **核心框架**: [Flutter](https://flutter.dev/)
*   **状态管理**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) - 高效、安全的状态管理方案。
*   **本地存储**: [SQLite](https://pub.dev/packages/sqflite) (`sqflite`) - 用于持久化存储血压记录和标签数据。
*   **图表展示**: [FL Chart](https://pub.dev/packages/fl_chart) (`fl_chart`) - 绘制美观的统计图表。
*   **本地通知**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications) (`flutter_local_notifications`) - 实现定时和智能提醒功能。
*   **数据导出**:
    *   `csv`: 生成 CSV 格式数据。
    *   `share_plus`: 调用系统分享功能导出文件。
*   **UI 组件**:
    *   `font_awesome_flutter`: 丰富的图标库。
    *   `google_fonts`: 优化字体显示。
    *   `image_picker`: 图片选择支持。

## 📂 项目结构

```
lib/
├── models/          # 数据模型 (如 BloodPressureRecord)
├── providers/       # Riverpod 状态管理 (RecordProvider, SettingsProvider)
├── screens/         # UI 页面
│   ├── dashboard_screen.dart   # 主界面容器 (包含底部导航)
│   ├── home_screen.dart        # 首页 (统计概览)
│   ├── history_screen.dart     # 历史记录页
│   ├── add_record_screen.dart  # 添加记录页
│   ├── settings_screen.dart    # 设置页 (导出、头像等)
│   └── tag_management_screen.dart # 标签管理页
├── services/        # 核心服务
│   ├── database_helper.dart    # 数据库操作 (CRUD)
│   └── notification_service.dart # 通知服务管理
└── main.dart        # 应用入口
```

## 🚀 快速开始

1.  **环境准备**
    确保本地已安装 Flutter SDK (推荐版本 3.10.4 或更高)。

2.  **获取代码**
    ```bash
    git clone <repository-url>
    cd my_blood_pressure
    ```

3.  **安装依赖**
    ```bash
    flutter pub get
    ```

4.  **运行应用**
    连接 Android 模拟器或真机，运行：
    ```bash
    flutter run
    ```

## 📄 许可证

本项目为个人学习和开发项目。
