@tool
extends EditorPlugin

# 传送系统配置编辑器插件
# 提供可视化的传送配置编辑界面

class_name TeleportConfigEditor

const TeleportConfigInspector = preload("res://addons/teleport_system/teleport_config_inspector.gd")

func _enter_tree():
	# 添加自定义类型
	add_custom_type(
		"TeleportManager",
		"Node2D",
		preload("res://scripts/teleport_manager.gd"),
		preload("res://addons/teleport_system/icons/teleport_manager.svg")
	)
	
	add_custom_type(
		"TeleportConfig",
		"Resource",
		preload("res://scripts/teleport_config.gd"),
		preload("res://addons/teleport_system/icons/teleport_config.svg")
	)
	
	# 添加自定义检查器
	add_inspector_plugin(TeleportConfigInspector.new())
	
	print("[TeleportConfigEditor] 传送系统编辑器插件已加载")

func _exit_tree():
	# 移除自定义类型
	remove_custom_type("TeleportManager")
	remove_custom_type("TeleportConfig")
	
	print("[TeleportConfigEditor] 传送系统编辑器插件已卸载")

func get_plugin_name():
	return "传送系统配置编辑器"