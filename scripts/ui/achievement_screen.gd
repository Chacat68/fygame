# 成就列表界面
# 显示所有成就及其解锁状态
extends Control

# 信号
signal back_pressed()

# UI组件引用
@onready var achievement_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/AchievementContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var progress_label: Label = $MarginContainer/VBoxContainer/ProgressLabel

func _ready() -> void:
	_connect_signals()
	_populate_achievements()
	_update_progress()
	_play_enter_animation()

## 连接信号
func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

## 填充成就列表
func _populate_achievements() -> void:
	if not achievement_container:
		return
	
	# 清除现有内容
	for child in achievement_container.get_children():
		child.queue_free()
	
	# 获取所有成就
	var achievements: Array[Dictionary] = []
	if AchievementManager:
		achievements = AchievementManager.get_all_achievements()
	
	# 创建成就项
	for achievement in achievements:
		var item = _create_achievement_item(achievement)
		achievement_container.add_child(item)

## 创建单个成就项
func _create_achievement_item(achievement: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	# 设置面板样式
	var style = StyleBoxFlat.new()
	if achievement.get("unlocked", false):
		style.bg_color = Color(0.15, 0.25, 0.15, 0.9)
		style.border_color = Color(0.3, 0.6, 0.3)
	else:
		style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		style.border_color = Color(0.3, 0.3, 0.3)
	
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)
	
	# 成就图标
	var icon = Label.new()
	icon.text = "🏆" if achievement.get("unlocked", false) else "🔒"
	icon.add_theme_font_size_override("font_size", 32)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)
	
	# 成就信息
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# 成就名称
	var name_label = Label.new()
	name_label.text = achievement.get("name", "未知成就")
	name_label.add_theme_font_size_override("font_size", 18)
	if achievement.get("unlocked", false):
		name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	else:
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_vbox.add_child(name_label)
	
	# 成就描述
	var desc_label = Label.new()
	desc_label.text = achievement.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info_vbox.add_child(desc_label)
	
	# 进度条（如果未解锁）
	if not achievement.get("unlocked", false):
		var progress = achievement.get("progress", 0)
		var target = achievement.get("target", 1)
		
		var progress_container = HBoxContainer.new()
		info_vbox.add_child(progress_container)
		
		var progress_bar = ProgressBar.new()
		progress_bar.custom_minimum_size = Vector2(150, 10)
		progress_bar.max_value = target
		progress_bar.value = progress
		progress_bar.show_percentage = false
		progress_container.add_child(progress_bar)
		
		var progress_text = Label.new()
		progress_text.text = " %d/%d" % [progress, target]
		progress_text.add_theme_font_size_override("font_size", 12)
		progress_text.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		progress_container.add_child(progress_text)
	
	# 奖励信息
	var reward = achievement.get("reward_coins", 0)
	if reward > 0:
		var reward_label = Label.new()
		reward_label.text = "🪙 %d" % reward
		reward_label.add_theme_font_size_override("font_size", 16)
		if achievement.get("unlocked", false):
			reward_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			reward_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		reward_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(reward_label)
	
	return panel

## 更新进度显示
func _update_progress() -> void:
	if not progress_label or not AchievementManager:
		return
	
	var progress = AchievementManager.get_unlock_progress()
	progress_label.text = "已解锁: %d / %d (%.1f%%)" % [progress["unlocked"], progress["total"], progress["percentage"]]

## 播放进入动画
func _play_enter_animation() -> void:
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

## 返回按钮回调
func _on_back_pressed() -> void:
	back_pressed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
