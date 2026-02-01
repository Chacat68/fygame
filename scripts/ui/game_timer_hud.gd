# 游戏内计时器HUD
# 显示当前关卡的计时和效果状态
extends Control

# UI组件引用
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var effects_container: HBoxContainer = $MarginContainer/VBoxContainer/EffectsContainer

# 关卡计时器引用
var level_timer: Node

# 效果图标
var effect_icons: Dictionary = {}

func _ready() -> void:
	# 查找关卡计时器
	level_timer = get_tree().get_first_node_in_group("level_timer")
	
	if level_timer:
		level_timer.time_updated.connect(_on_time_updated)
	
	# 连接道具管理器信号
	var item_mgr = get_node_or_null("/root/ItemManager")
	if item_mgr:
		item_mgr.effect_applied.connect(_on_effect_applied)
		item_mgr.effect_expired.connect(_on_effect_expired)

func _process(_delta: float) -> void:
	# 更新效果剩余时间
	_update_effect_timers()

## 时间更新回调
func _on_time_updated(time: float) -> void:
	if time_label:
		time_label.text = _format_time(time)

## 格式化时间
func _format_time(seconds: float) -> String:
	@warning_ignore("integer_division")
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	var ms = int((seconds - int(seconds)) * 100)
	return "%02d:%02d.%02d" % [minutes, secs, ms]

## 效果应用回调
func _on_effect_applied(effect_type: String, duration: float) -> void:
	_add_effect_icon(effect_type, duration)

## 效果过期回调
func _on_effect_expired(effect_type: String) -> void:
	_remove_effect_icon(effect_type)

## 添加效果图标
func _add_effect_icon(effect_type: String, _duration: float) -> void:
	if not effects_container:
		return
	
	if effect_icons.has(effect_type):
		return
	
	# 创建效果图标容器
	var icon_container = VBoxContainer.new()
	icon_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# 效果图标
	var icon = Label.new()
	icon.add_theme_font_size_override("font_size", 24)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 根据效果类型设置图标
	match effect_type:
		"speed_boost":
			icon.text = "⚡"
			icon.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
		"jump_boost":
			icon.text = "🦘"
			icon.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		"invincibility":
			icon.text = "🛡️"
			icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		"double_coins":
			icon.text = "💰"
			icon.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		_:
			icon.text = "✨"
	
	icon_container.add_child(icon)
	
	# 剩余时间标签
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_font_size_override("font_size", 10)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_container.add_child(timer_label)
	
	effects_container.add_child(icon_container)
	effect_icons[effect_type] = icon_container
	
	# 进入动画
	icon_container.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(icon_container, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 移除效果图标
func _remove_effect_icon(effect_type: String) -> void:
	if not effect_icons.has(effect_type):
		return
	
	var icon_container = effect_icons[effect_type]
	
	# 退出动画
	var tween = create_tween()
	tween.tween_property(icon_container, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(icon_container.queue_free)
	
	effect_icons.erase(effect_type)

## 更新效果计时器
func _update_effect_timers() -> void:
	var item_mgr = get_node_or_null("/root/ItemManager")
	if not item_mgr:
		return
	
	for effect_type in effect_icons.keys():
		var remaining = item_mgr.get_effect_remaining_time(effect_type)
		var icon_container = effect_icons[effect_type]
		var timer_label = icon_container.get_node_or_null("TimerLabel")
		
		if timer_label:
			timer_label.text = "%.1f" % remaining
			
			# 当时间少于3秒时闪烁
			if remaining < 3.0:
				timer_label.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 100.0)
			else:
				timer_label.modulate.a = 1.0
