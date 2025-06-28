#!/bin/bash

# 传送功能快速测试脚本
# 适用于macOS系统

echo "🚀 启动传送功能测试..."
echo "📁 项目路径: $(pwd)"

# 检查Godot是否安装
if command -v godot &> /dev/null; then
    echo "✅ 找到Godot命令行工具"
    echo "🎮 启动测试场景..."
    godot --path . tests/integration/teleport_test_scene.tscn
else
    echo "⚠️  未找到Godot命令行工具"
    echo "📖 请手动在Godot编辑器中运行测试:"
    echo "   1. 打开Godot编辑器"
    echo "   2. 加载项目: project.godot"
    echo "   3. 运行场景: tests/integration/teleport_test_scene.tscn"
echo "   4. 或者运行现有关卡: scenes/levels/level2.tscn"
    
    # 尝试直接打开项目文件
    echo "\n🔧 尝试打开项目文件..."
    open project.godot
fi

echo "\n📚 查看测试指南: TELEPORT_TEST_GUIDE.md"
echo "🎯 测试完成后，检查控制台输出获取详细结果"