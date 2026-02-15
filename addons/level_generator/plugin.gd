@tool
extends EditorPlugin

# 关卡生成器编辑器插件
# 在编辑器底部面板中提供 JSON → 场景 的关卡生成工具

const PANEL_TITLE := "关卡生成器"

var dock: Control

func _enter_tree():
	dock = preload("res://addons/level_generator/level_generator_dock.gd").new()
	dock.name = "LevelGeneratorDock"
	dock.editor_interface = get_editor_interface()
	add_control_to_bottom_panel(dock, PANEL_TITLE)
	print("[关卡生成器插件] 已加载")

func _exit_tree():
	if dock:
		remove_control_from_bottom_panel(dock)
		dock.queue_free()
	print("[关卡生成器插件] 已卸载")
