# 项目重构计划

## 当前问题分析

1. **根目录混乱**: 测试文件直接放在根目录
2. **scripts分类不清**: 所有脚本混在一起，缺乏逻辑分组
3. **文档分散**: 设计文档和系统文档分开存放
4. **测试文件无组织**: 测试相关文件散落各处

## 新的文件夹结构

```
fygame/
├── .gitattributes
├── .gitignore
├── .vscode/
├── README.md
├── project.godot
├── icon.svg
├── export_presets.cfg
├── default_bus_layout.tres
├── quick_test.sh
│
├── addons/                    # Godot插件
│   └── teleport_system/
│
├── assets/                    # 游戏资源
│   ├── fonts/
│   ├── images/
│   ├── music/
│   ├── sounds/
│   └── sprites/
│
├── docs/                      # 所有文档
│   ├── design/               # 设计文档
│   ├── system/               # 系统文档
│   └── guides/               # 使用指南
│
├── scenes/                    # 场景文件
│   ├── levels/               # 关卡场景
│   ├── ui/                   # UI场景
│   ├── entities/             # 实体场景(玩家、敌人、道具等)
│   └── managers/             # 管理器场景
│
├── scripts/                   # 脚本文件
│   ├── autoload/             # 自动加载脚本
│   ├── entities/             # 实体脚本
│   │   ├── player/           # 玩家相关
│   │   ├── enemies/          # 敌人相关
│   │   └── items/            # 道具相关
│   ├── managers/             # 管理器脚本
│   ├── ui/                   # UI脚本
│   ├── levels/               # 关卡脚本
│   ├── systems/              # 系统脚本(传送、配置等)
│   └── utils/                # 工具脚本
│
├── resources/                 # 资源配置文件
│
├── shaders/                   # 着色器
│
├── tests/                     # 测试文件
│   ├── unit/                 # 单元测试
│   ├── integration/          # 集成测试
│   └── examples/             # 示例代码
│
└── tools/                     # 开发工具
    └── scripts/              # 工具脚本
```

## 重构步骤

1. 创建新的文件夹结构
2. 移动文档文件到docs文件夹
3. 重新组织scripts文件夹
4. 重新组织scenes文件夹
5. 移动测试文件到tests文件夹
6. 创建工具文件夹