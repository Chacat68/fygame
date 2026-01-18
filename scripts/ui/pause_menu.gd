# 暂停菜单脚本
# 游戏暂停时显示，提供保存、设置、返回主菜单等功能
extends Control

# 信号
signal game_resumed()
signal game_saved()
signal return_to_menu()

# UI组件引用
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton
@onready var save_status_label: Label = $Panel/VBoxContainer/SaveStatusLabel
@onready var panel: PanelContainer = $Panel

# 设置界面
var settings_scene: PackedScene = preload("res://scenes/ui/settings_screen.tscn")
var settings_screen: Control

# 暂停状态
var is_paused: bool = false

func _ready() -> void:
	# 初始隐藏
	visible = false
	
	# 连接按钮信号
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	
	# 隐藏保存状态标签
	if save_status_label:
		save_status_label.visible = false

func _input(event: InputEvent) -> void:
	# ESC键切换暂停状态
	if event.is_action_pressed("ui_cancel"):
		if settings_screen and is_instance_valid(settings_screen):
			_on_settings_back()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()

# 切换暂停状态
func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

# 暂停游戏
func pause_game() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true
	
	# 设置焦点到继续按钮
	if resume_button:
		resume_button.grab_focus()

# 恢复游戏
func resume_game() -> void:
	is_paused = false
	visible = false
	get_tree().paused = false
	game_resumed.emit()

# 继续按钮回调
func _on_resume_pressed() -> void:
	resume_game()

# 保存按钮回调
func _on_save_pressed() -> void:
	if SaveManager:
		var success = SaveManager.save_game()
		_show_save_status(success)
		if success:
			game_saved.emit()

# 显示保存状态
func _show_save_status(success: bool) -> void:
	if not save_status_label:
		return
	
	save_status_label.visible = true
	
	if success:
		save_status_label.text = "✓ 保存成功"
		save_status_label.modulate = Color(0.2, 0.8, 0.2)
	else:
		save_status_label.text = "✗ 保存失败"
		save_status_label.modulate = Color(0.8, 0.2, 0.2)
	
	# 2秒后隐藏
	await get_tree().create_timer(2.0).timeout
	if save_status_label:
		save_status_label.visible = false

# 设置按钮回调
func _on_settings_pressed() -> void:
	if settings_screen and is_instance_valid(settings_screen):
		return
	
	settings_screen = settings_scene.instantiate()
	settings_screen.set("return_to_main_menu_on_back", false)
	add_child(settings_screen)
	
	if panel:
		panel.visible = false
	
	if settings_screen.has_signal("back_pressed"):
		settings_screen.back_pressed.connect(_on_settings_back)

# 返回主菜单按钮回调
func _on_menu_pressed() -> void:
	# 先保存游戏
	if SaveManager:
		SaveManager.save_game()
	
	# 恢复游戏时间
	get_tree().paused = false
	is_paused = false
	
	return_to_menu.emit()
	
	# 切换到主菜单
	get_tree().change_scene_to_file("res://scenes/ui/game_start_screen.tscn")

# 关闭设置界面
func _on_settings_back() -> void:
	if settings_screen and is_instance_valid(settings_screen):
		settings_screen.queue_free()
		settings_screen = null

	if panel:
		panel.visible = true
