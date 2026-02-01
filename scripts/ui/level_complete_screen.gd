# 关卡完成界面脚本
# 显示关卡完成后的统计和评分
extends Control

# 信号
signal continue_pressed()
signal retry_pressed()
signal menu_pressed()

# UI组件引用
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var stars_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/StarsContainer
@onready var time_label: Label = $Panel/MarginContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var score_label: Label = $Panel/MarginContainer/VBoxContainer/StatsContainer/ScoreLabel
@onready var kills_label: Label = $Panel/MarginContainer/VBoxContainer/StatsContainer/KillsLabel
@onready var coins_label: Label = $Panel/MarginContainer/VBoxContainer/StatsContainer/CoinsLabel
@onready var bonus_label: Label = $Panel/MarginContainer/VBoxContainer/BonusLabel
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/ContinueButton
@onready var retry_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/RetryButton
@onready var menu_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsContainer/MenuButton

# 关卡数据
var score_data: Dictionary = {}
var next_level_id: int = 0

func _ready() -> void:
	_connect_signals()
	visible = false

## 连接信号
func _connect_signals() -> void:
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

## 显示关卡完成界面
func show_completion(data: Dictionary, next_level: int = 0) -> void:
	score_data = data
	next_level_id = next_level
	
	_update_display()
	_play_enter_animation()
	
	visible = true
	get_tree().paused = true

## 更新显示内容
func _update_display() -> void:
	# 标题
	if title_label:
		title_label.text = "关卡完成!"
	
	# 星星
	_display_stars(score_data.get("stars", 0))
	
	# 时间
	if time_label:
		time_label.text = "用时: %s" % score_data.get("formatted_time", "00:00.00")
	
	# 分数
	if score_label:
		score_label.text = "总分: %d" % score_data.get("total_score", 0)
	
	# 击杀
	if kills_label:
		kills_label.text = "击杀: %d" % score_data.get("enemies_killed", 0)
	
	# 金币
	if coins_label:
		coins_label.text = "金币: %d" % score_data.get("coins_collected", 0)
	
	# 奖励
	if bonus_label:
		var bonuses: Array[String] = []
		if score_data.get("is_no_damage", false):
			bonuses.append("无伤通关 +%d" % score_data.get("no_damage_bonus", 0))
		if score_data.get("secrets_found", 0) > 0:
			bonuses.append("发现秘密 +%d" % score_data.get("secret_bonus", 0))
		
		if bonuses.size() > 0:
			bonus_label.text = "奖励: " + ", ".join(bonuses)
			bonus_label.visible = true
		else:
			bonus_label.visible = false
	
	# 继续按钮（检查是否有下一关）
	if continue_button:
		continue_button.visible = next_level_id > 0
		continue_button.text = "继续 (关卡 %d)" % next_level_id if next_level_id > 0 else ""

## 显示星星
func _display_stars(count: int) -> void:
	if not stars_container:
		return
	
	# 清除现有星星
	for child in stars_container.get_children():
		child.queue_free()
	
	# 添加新星星
	for i in range(3):
		var star = Label.new()
		star.text = "★" if i < count else "☆"
		star.add_theme_font_size_override("font_size", 48)
		star.add_theme_color_override("font_color", Color(1, 0.8, 0) if i < count else Color(0.4, 0.4, 0.4))
		
		# 初始隐藏，用于动画
		star.modulate.a = 0
		star.scale = Vector2.ZERO
		
		stars_container.add_child(star)

## 播放进入动画
func _play_enter_animation() -> void:
	# 面板动画
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# 星星逐个显示
	await get_tree().create_timer(0.5).timeout
	
	var stars = stars_container.get_children() if stars_container else []
	for i in range(stars.size()):
		var star = stars[i]
		var star_tween = create_tween()
		star_tween.set_parallel(true)
		star_tween.tween_property(star, "modulate:a", 1.0, 0.3)
		star_tween.tween_property(star, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
		# 播放音效
		if AudioManager and i < score_data.get("stars", 0):
			AudioManager.play_sfx("coin")
		
		await get_tree().create_timer(0.3).timeout

## 继续按钮回调
func _on_continue_pressed() -> void:
	get_tree().paused = false
	continue_pressed.emit()
	
	if next_level_id > 0:
		var scene_path = "res://scenes/levels/lv%d.tscn" % next_level_id
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)

## 重试按钮回调
func _on_retry_pressed() -> void:
	get_tree().paused = false
	retry_pressed.emit()
	get_tree().reload_current_scene()

## 菜单按钮回调
func _on_menu_pressed() -> void:
	get_tree().paused = false
	menu_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/ui/level_select_screen.tscn")
