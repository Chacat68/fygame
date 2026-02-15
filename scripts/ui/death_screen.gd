# 死亡/重生画面
# 玩家死亡后显示叙事性的死亡提示 + 重试/返回按钮
extends CanvasLayer

signal retry_pressed
signal menu_pressed

# 每章的死亡提示语
const DEATH_MESSAGES := {
	1: "倒在了翠风草原…\n风中传来精灵之树的叹息",
	2: "被深林的黑暗吞噬…\n紫色的光芒渐渐远去",
	3: "坠入了矿洞深渊…\n水晶的光芒在头顶闪烁",
	4: "虚空的力量将你击碎…\n但碎片仍在闪耀",
	5: "虚空守卫的咆哮回荡在地牢中…\n这不是终点"
}

const DEFAULT_MESSAGE := "黑暗笼罩了一切…\n但光芒从未真正消失"

# UI 节点
var _overlay: ColorRect
var _message_label: Label
var _hint_label: Label
var _retry_button: Button
var _menu_button: Button
var _vbox: VBoxContainer

# 状态
var _is_active: bool = false
var _current_chapter: int = 0

func _ready():
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS # 暂停时也能响应
	_build_ui()
	visible = false

# ── 公开接口 ──────────────────────────────────────────

## 显示死亡画面
func show_death(chapter: int = 0):
	if _is_active:
		return
	_is_active = true
	_current_chapter = chapter

	# 设置死亡提示文字
	_message_label.text = DEATH_MESSAGES.get(chapter, DEFAULT_MESSAGE)

	# 重置并显示
	_overlay.modulate.a = 0
	_retry_button.visible = false
	_menu_button.visible = false
	_hint_label.visible = false
	visible = true

	# 动画：红色闪烁 → 暗下来 → 显示文字和按钮
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.5)
	tween.tween_callback(_show_buttons)

	# 暂停游戏
	get_tree().paused = true

## 隐藏死亡画面
func hide_death():
	_is_active = false
	visible = false
	get_tree().paused = false

# ── 内部方法 ──────────────────────────────────────────

func _show_buttons():
	_retry_button.visible = true
	_menu_button.visible = true
	_hint_label.visible = true

	# 按钮淡入
	_retry_button.modulate.a = 0
	_menu_button.modulate.a = 0
	_hint_label.modulate.a = 0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_retry_button, "modulate:a", 1.0, 0.3)
	tween.tween_property(_menu_button, "modulate:a", 1.0, 0.3)
	tween.tween_property(_hint_label, "modulate:a", 1.0, 0.3)

func _on_retry():
	hide_death()
	retry_pressed.emit()
	get_tree().reload_current_scene()

func _on_menu():
	hide_death()
	menu_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/ui/level_select_screen.tscn")

func _build_ui():
	# 暗红色半透明遮罩
	_overlay = ColorRect.new()
	_overlay.name = "DeathOverlay"
	_overlay.color = Color(0.12, 0.02, 0.02, 0.92)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# 垂直布局
	_vbox = VBoxContainer.new()
	_vbox.name = "Content"
	_vbox.set_anchors_preset(Control.PRESET_CENTER)
	_vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 20)
	_vbox.custom_minimum_size = Vector2(500, 300)
	_vbox.position = Vector2(-250, -150)
	_overlay.add_child(_vbox)

	# 死亡标题
	var death_title = Label.new()
	death_title.text = "陨落"
	death_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_title.add_theme_font_size_override("font_size", 32)
	death_title.add_theme_color_override("font_color", Color(0.8, 0.2, 0.15))
	_vbox.add_child(death_title)

	# 死亡提示文字
	_message_label = Label.new()
	_message_label.name = "MessageLabel"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 18)
	_message_label.add_theme_color_override("font_color", Color(0.75, 0.65, 0.55))
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox.add_child(_message_label)

	# 分隔
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	_vbox.add_child(spacer)

	# 提示
	_hint_label = Label.new()
	_hint_label.text = "碎片仍在等待被收集…"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.35))
	_vbox.add_child(_hint_label)

	# 按钮容器
	var btn_box = HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 30)
	_vbox.add_child(btn_box)

	# 重试按钮
	_retry_button = Button.new()
	_retry_button.text = "再次挑战"
	_retry_button.custom_minimum_size = Vector2(140, 40)
	_retry_button.pressed.connect(_on_retry)
	_apply_button_style(_retry_button, Color(0.6, 0.2, 0.15))
	btn_box.add_child(_retry_button)

	# 返回按钮
	_menu_button = Button.new()
	_menu_button.text = "关卡选择"
	_menu_button.custom_minimum_size = Vector2(140, 40)
	_menu_button.pressed.connect(_on_menu)
	_apply_button_style(_menu_button, Color(0.3, 0.3, 0.4))
	btn_box.add_child(_menu_button)

func _apply_button_style(btn: Button, color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
