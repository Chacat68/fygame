extends Node

# 资源管理器自动加载脚本
# 将此脚本添加到项目设置的AutoLoad中，命名为"ResourceManager"

# 预加载ResourceManager类
const ResourceManagerClass = preload("res://scripts/resource_manager.gd")

# 在游戏启动时初始化资源管理器
func _ready():
	# 确保资源管理器实例已创建
	var _rm = ResourceManagerClass.instance()
	print("资源管理器已初始化")