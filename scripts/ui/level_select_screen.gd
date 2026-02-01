# 关卡选择界面脚本
# 显示所有关卡并允许玩家选择
extends Control

# 信号
signal level_selected(level_id: int)
signal back_pressed()

# UI组件引用
@onready var level_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/LevelContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var stats_label: Label = $MarginContainer/VBoxContainer/StatsLabel

# 关卡按钮场景
var level_button_scene: PackedScene

# 关卡数据
var level_data: Array[Dictionary] = []
var max_unlocked_level: int = 1

func _ready() -> void:
	_connect_signals()
	_load_level_data()
	_create_level_buttons()
	_update_stats()
	_play_enter_animation()

## 连接信号
func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

## 加载关卡数据
func _load_level_data() -> void:
	# 从关卡配置加载
	var level_config = load("res://resources/level_config.tres") as LevelConfig if ResourceLoader.exists("res://resources/level_config.tres") else null
	
	if level_config and level_config.has_method("get_all_levels"):
		level_data = level_config.get_all_levels()
	else:
		# 使用默认关卡数据
		level_data = [
			{"id": 1, "name": "关卡 1", "scene_path": "res://scenes/levels/lv1.tscn", "stars": 0, "best_time": 0.0},
			{"id": 2, "name": "关卡 2", "scene_path": "res://scenes/levels/lv2.tscn", "stars": 0, "best_time": 0.0},
			{"id": 3, "name": "关卡 3", "scene_path": "res://scenes/levels/lv3.tscn", "stars": 0, "best_time": 0.0},
			{"id": 4, "name": "关卡 4", "scene_path": "res://scenes/levels/lv4.tscn", "stars": 0, "best_time": 0.0}
		]
	
	# 从存档加载解锁进度
	_load_progress_from_save()

## 从存档加载进度
func _load_progress_from_save() -> void:
	if SaveManager and SaveManager.current_save:
		max_unlocked_level = SaveManager.current_save.max_unlocked_level
		
		# 加载关卡完成数据
		if SaveManager.current_save.has("completed_levels"):
			for level in level_data:
				var level_id = str(level["id"])
				if SaveManager.current_save.completed_levels.has(level_id):
					var completed_data = SaveManager.current_save.completed_levels[level_id]
					level["stars"] = completed_data.get("stars", 0)
					level["best_time"] = completed_data.get("best_time", 0.0)
	else:
		max_unlocked_level = 1

## 创建关卡按钮
func _create_level_buttons() -> void:
	# 清除现有按钮
	for child in level_container.get_children():
		child.queue_free()
	
	# 创建每个关卡的按钮
	for level in level_data:
		var button = _create_level_button(level)
		level_container.add_child(button)

## 创建单个关卡按钮
func _create_level_button(level: Dictionary) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(150, 180)
	
	# 设置面板样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.4)
	container.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)
	
	# 关卡编号
	var level_number = Label.new()
	level_number.text = str(level["id"])
	level_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_number.add_theme_font_size_override("font_size", 48)
	vbox.add_child(level_number)
	
	# 关卡名称
	var level_name = Label.new()
	level_name.text = level.get("name", "关卡 %d" % level["id"])
	level_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_name.add_theme_font_size_override("font_size", 14)
	vbox.add_child(level_name)
	
	# 星星评级
	var stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stars_container)
	
	var stars = level.get("stars", 0)
	for i in range(3):
		var star = Label.new()
		star.text = "★" if i < stars else "☆"
		star.add_theme_font_size_override("font_size", 20)
		star.add_theme_color_override("font_color", Color(1, 0.8, 0) if i < stars else Color(0.5, 0.5, 0.5))
		stars_container.add_child(star)
	
	# 最佳时间
	var best_time = level.get("best_time", 0.0)
	if best_time > 0:
		var time_label = Label.new()
		time_label.text = _format_time(best_time)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_label.add_theme_font_size_override("font_size", 12)
		time_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(time_label)
	
	# 检查是否解锁
	var is_unlocked = level["id"] <= max_unlocked_level
	
	if not is_unlocked:
		# 显示锁定状态
		container.modulate = Color(0.5, 0.5, 0.5, 0.8)
		level_number.text = "🔒"
	else:
		# 添加按钮功能
		var button = Button.new()
		button.flat = true
		button.custom_minimum_size = container.custom_minimum_size
		button.pressed.connect(_on_level_button_pressed.bind(level["id"]))
		button.mouse_entered.connect(_on_button_hover.bind(container))
		button.mouse_exited.connect(_on_button_unhover.bind(container))
		container.add_child(button)
	
	return container

## 格式化时间
func _format_time(seconds: float) -> String:
	@warning_ignore("integer_division")
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	var ms = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, secs, ms]

## 更新统计信息
func _update_stats() -> void:
	if not stats_label:
		return
	
	var completed = 0
	var total_stars = 0
	
	for level in level_data:
		if level.get("stars", 0) > 0:
			completed += 1
		total_stars += level.get("stars", 0)
	
	stats_label.text = "已完成: %d/%d | 总星数: %d/%d" % [completed, level_data.size(), total_stars, level_data.size() * 3]

## 播放进入动画
func _play_enter_animation() -> void:
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

## 按钮悬停效果
func _on_button_hover(container: Control) -> void:
	var tween = create_tween()
	tween.tween_property(container, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(container: Control) -> void:
	var tween = create_tween()
	tween.tween_property(container, "scale", Vector2.ONE, 0.1)

## 关卡按钮点击
func _on_level_button_pressed(level_id: int) -> void:
	level_selected.emit(level_id)
	
	# 加载关卡
	var level = level_data.filter(func(l): return l["id"] == level_id)
	if level.size() > 0 and level[0].has("scene_path"):
		var scene_path = level[0]["scene_path"]
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
		else:
			push_error("关卡场景不存在: %s" % scene_path)

## 返回按钮点击
func _on_back_pressed() -> void:
	back_pressed.emit()
	
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/ui/game_start_screen.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
