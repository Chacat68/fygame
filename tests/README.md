# 测试框架使用指南

## 问题解决方案

之前遇到的错误：
```
ERROR: res://tests/test_level_manager.gd:1 - Parse Error: Could not find base class "GutTest".
```

### 解决步骤

1. **安装GUT测试框架**
   - 已从GitHub克隆GUT框架到项目的`addons/gut/`目录
   - GUT是Godot的单元测试框架，用于编写和运行测试

2. **启用插件**
   - 在`project.godot`文件中添加了GUT插件配置
   - 插件现在已在编辑器中启用

3. **修复类定义**
   - 为`ResourceManager`添加了`class_name`定义
   - 确保测试文件能够正确引用所需的类

## 如何使用GUT测试框架

### 在Godot编辑器中运行测试

1. 打开Godot编辑器
2. 在底部面板中找到"GUT"标签
3. 点击"Run All"按钮运行所有测试
4. 或选择特定的测试文件运行

### 测试文件结构

```gdscript
extends GutTest

# 测试前设置
func before_each():
    # 每个测试方法执行前调用
    pass

# 测试后清理
func after_each():
    # 每个测试方法执行后调用
    pass

# 测试方法（必须以test_开头）
func test_something():
    assert_eq(1, 1, "1应该等于1")
    assert_true(true, "true应该为真")
```

### 常用断言方法

- `assert_eq(expected, actual, message)` - 相等断言
- `assert_ne(expected, actual, message)` - 不等断言
- `assert_true(value, message)` - 真值断言
- `assert_false(value, message)` - 假值断言
- `assert_null(value, message)` - 空值断言
- `assert_not_null(value, message)` - 非空断言

### 现有测试文件

- `test_gut_installation.gd` - GUT框架安装验证测试
- `test_level_manager.gd` - 关卡管理器测试
- `test_resource_manager.gd` - 资源管理器测试

## 注意事项

1. 确保Godot编辑器中已启用GUT插件
2. 测试方法必须以`test_`开头
3. 使用有意义的断言消息来帮助调试
4. 在`before_each()`和`after_each()`中进行适当的设置和清理

## 更多信息

- [GUT官方文档](https://gut.readthedocs.io/en/latest/)
- [GUT GitHub仓库](https://github.com/bitwes/Gut)