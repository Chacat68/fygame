# 关卡选择界面脚本
# 显示所有关卡章节并允许玩家选择
extends Control

# 信号
signal level_selected(level_id: int)
signal back_pressed()

# UI组件引用
@onready var level_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/LevelContainer
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var stats_label: Label = $MarginContainer/VBoxContainer/StatsLabel

# 关卡数据
var level_data: Array[Dictionary] = []
var max_unlocked_level: int = 1

# 章节颜色
const CHAPTER_COLORS := {
	1: Color(0.3, 0.6, 0.3), # 翠风草原 - 绿色
	2: Color(0.25, 0.2, 0.4), # 幽暗深林 - 暗紫
	3: Color(0.3, 0.45, 0.6), # 水晶矿洞 - 蓝色
	4: Color(0.5, 0.15, 0.15), # 虚空地牢 - 暗红
	5: Color(0.4, 0.1, 0.5) # 终章 - 深紫
}

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
	var level_config = load("res://resources/level_config.tres") as LevelConfig if ResourceLoader.exists("res://resources/level_config.tres") else null

	if level_config and level_config.levels.size() > 0:
		level_data = []
		for lv in level_config.levels:
			level_data.append(lv.duplicate())
	else:
		# 回退数据（与故事对齐）
		level_data = [
			{"id": 1, "name": "第一章 · 翠风草原", "scene_path": "res://scenes/levels/lv1.tscn", "description": "踏出废墟的第一步，就是冒险的开始。", "stars": 0, "best_time": 0.0},
			{"id": 2, "name": "第二章 · 幽暗深林", "scene_path": "res://scenes/levels/lv2.tscn", "description": "树影之间，紫色的眼睛正在注视你。", "stars": 0, "best_time": 0.0},
			{"id": 3, "name": "第三章 · 水晶矿洞", "scene_path": "res://scenes/levels/lv3.tscn", "description": "矿洞深处的光芒，来自水晶，还是陷阱？", "stars": 0, "best_time": 0.0},
			{"id": 4, "name": "第四章 · 虚空地牢", "scene_path": "res://scenes/levels/lv4.tscn", "description": "每一步都可能是最后一步。", "stars": 0, "best_time": 0.0},
			{"id": 5, "name": "终章 · 封印虚空", "scene_path": "res://scenes/levels/lv5.tscn", "description": "光芒重聚，大地新生。", "stars": 0, "best_time": 0.0}
		]

	# 从存档加载解锁进度
	_load_progress_from_save()

## 从存档加载进度
func _load_progress_from_save() -> void:
	if SaveManager and SaveManager.current_save:
		max_unlocked_level = SaveManager.current_save.max_unlocked_level

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
	for child in level_container.get_children():
		child.queue_free()

	for level in level_data:
		var button = _create_level_button(level)
		level_container.add_child(button)

## 创建单个关卡按钮（带故事元素）
func _create_level_button(level: Dictionary) -> Control:
	var level_id = level.get("id", 0)
	var is_unlocked = level_id <= max_unlocked_level
	var chapter_color = CHAPTER_COLORS.get(level_id, Color(0.3, 0.3, 0.3))

	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(160, 200)

	# 面板样式（章节主题色）
	var style = StyleBoxFlat.new()
	style.bg_color = chapter_color.darkened(0.6) if is_unlocked else Color(0.12, 0.12, 0.15, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = chapter_color if is_unlocked else Color(0.25, 0.25, 0.3)
	container.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# 章节编号
	var chapter_num = Label.new()
	chapter_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_num.add_theme_font_size_override("font_size", 14)

	if is_unlocked:
		chapter_num.text = "第%d章" % level_id if level_id < 5 else "终章"
		chapter_num.add_theme_color_override("font_color", chapter_color.lightened(0.3))
	else:
		chapter_num.text = "🔒"
		chapter_num.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(chapter_num)

	# 关卡名称
	var level_name = Label.new()
	level_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_name.add_theme_font_size_override("font_size", 16)
	level_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if is_unlocked:
		# 只显示章节名（去掉"第X章 · "）
		var name_text = level.get("name", "")
		if "·" in name_text:
			name_text = name_text.split("·")[1].strip_edges()
		level_name.text = name_text
		level_name.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8))
	else:
		level_name.text = "？？？"
		level_name.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(level_name)

	# 星星评级
	var stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stars_container)

	if is_unlocked:
		var stars = level.get("stars", 0)
		for i in range(3):
			var star = Label.new()
			star.text = "★" if i < stars else "☆"
			star.add_theme_font_size_override("font_size", 18)
			star.add_theme_color_override("font_color", Color(1, 0.8, 0) if i < stars else Color(0.4, 0.4, 0.4))
			stars_container.add_child(star)

	# 章节引语
	var desc = Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 10)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(140, 0)

	if is_unlocked:
		desc.text = level.get("description", "")
		desc.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
	else:
		desc.text = ""
	vbox.add_child(desc)

	# 锁定视觉
	if not is_unlocked:
		container.modulate = Color(0.6, 0.6, 0.6, 0.8)
	else:
		# 添加点击按钮
		var button = Button.new()
		button.flat = true
		button.custom_minimum_size = container.custom_minimum_size
		button.pressed.connect(_on_level_button_pressed.bind(level_id))
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

	stats_label.text = "已完成: %d/%d | 碎片: %d/%d" % [completed, level_data.size(), total_stars, level_data.size() * 3]

## 播放进入动画
func _play_enter_animation() -> void:
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

## 按钮悬停动画
func _on_button_hover(container: Control) -> void:
	var tween = create_tween()
	tween.tween_property(container, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_unhover(container: Control) -> void:
	var tween = create_tween()
	tween.tween_property(container, "scale", Vector2.ONE, 0.1)

## 关卡按钮点击 — 先章节过渡再加载
func _on_level_button_pressed(level_id: int) -> void:
	level_selected.emit(level_id)

	var level = level_data.filter(func(l): return l["id"] == level_id)
	if level.is_empty():
		return

	var lv = level[0]
	var scene_path = lv.get("scene_path", "")

	if not ResourceLoader.exists(scene_path):
		push_error("关卡场景不存在: %s" % scene_path)
		return

	# 获取章节过渡数据
	var data_path = lv.get("data_path", "")
	var chapter_data := {}

	if not data_path.is_empty() and FileAccess.file_exists(data_path):
		var file = FileAccess.open(data_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				chapter_data = json.data
			file.close()

	# 如果有 ChapterTransition AutoLoad，先播放过渡
	var transition = get_node_or_null("/root/ChapterTransition")
	if transition and not chapter_data.is_empty():
		transition.show_from_level_data(chapter_data, func(): get_tree().change_scene_to_file(scene_path))
	else:
		# 回退：直接加载
		get_tree().change_scene_to_file(scene_path)

## 返回按钮点击
func _on_back_pressed() -> void:
	back_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/ui/game_start_screen.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
