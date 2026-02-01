# 统计界面脚本
# 显示游戏统计数据
extends Control

# 信号
signal back_pressed()

# UI组件引用
@onready var stats_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/StatsContainer
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel

func _ready() -> void:
	_connect_signals()
	_populate_stats()
	_play_enter_animation()

## 连接信号
func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

## 填充统计数据
func _populate_stats() -> void:
	if not stats_container:
		return
	
	# 清除现有内容
	for child in stats_container.get_children():
		child.queue_free()
	
	# 获取统计数据
	var stats = {}
	var stats_mgr = get_node_or_null("/root/GameStatsManager")
	if stats_mgr:
		stats = stats_mgr.get_stats_summary()
	
	# 创建统计项
	_add_stat_section("游戏进度")
	_add_stat_item("游戏时间", stats.get("play_time", "0小时 0分 0秒"))
	_add_stat_item("游戏次数", str(stats.get("games_played", 0)))
	_add_stat_item("关卡完成", str(stats.get("levels_completed", 0)))
	_add_stat_item("完美通关", str(stats.get("perfect_levels", 0)))
	
	_add_stat_section("战斗统计")
	_add_stat_item("总击杀数", str(stats.get("total_kills", 0)))
	_add_stat_item("总死亡数", str(stats.get("total_deaths", 0)))
	_add_stat_item("最高连击", str(stats.get("best_combo", 0)))
	
	_add_stat_section("收集统计")
	_add_stat_item("总金币", str(stats.get("total_coins", 0)))
	_add_stat_item("移动距离", stats.get("distance_km", "0.00 km"))
	
	# 成就进度
	var achievement_mgr = get_node_or_null("/root/AchievementManager")
	if achievement_mgr:
		var progress = achievement_mgr.get_unlock_progress()
		_add_stat_section("成就")
		_add_stat_item("已解锁", "%d / %d (%.1f%%)" % [progress["unlocked"], progress["total"], progress["percentage"]])

## 添加统计分类标题
func _add_stat_section(title: String) -> void:
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 10
	stats_container.add_child(separator)
	
	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	stats_container.add_child(label)

## 添加统计项
func _add_stat_item(stat_name: String, value: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label_item = Label.new()
	name_label_item.text = stat_name
	name_label_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label_item.add_theme_font_size_override("font_size", 16)
	hbox.add_child(name_label_item)
	
	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox.add_child(value_label)
	
	stats_container.add_child(hbox)

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
