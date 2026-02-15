# 章节过渡画面
# AutoLoad 单例 - 在关卡切换时显示章节标题卡
# 用法: ChapterTransition.show_transition("翠风草原", "踏出废墟的第一步...", callable_after)
extends CanvasLayer

signal transition_finished

# UI 节点
var _overlay: ColorRect
var _title_label: Label
var _quote_label: Label
var _chapter_label: Label

# 状态
var _is_active: bool = false

func _ready():
	layer = 100 # 最顶层
	_build_ui()
	visible = false

# ── 公开接口 ──────────────────────────────────────────

## 显示章节过渡（标题 + 引语），完成后执行回调
func show_transition(title: String, quote: String, callback: Callable = Callable(), chapter_num: int = 0):
	if _is_active:
		return
	_is_active = true

	# 设置文字
	_title_label.text = title
	_quote_label.text = "「%s」" % quote if not quote.is_empty() else ""
	_chapter_label.text = "第%s章" % _num_to_chinese(chapter_num) if chapter_num > 0 else ""

	# 重置透明度
	_overlay.modulate.a = 0
	visible = true

	# 动画：淡入 → 停留 → 淡出
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.5)
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_on_transition_done.bind(callback))

## 仅淡入黑屏（用于场景切换前）
func fade_to_black(duration: float = 0.4) -> void:
	_overlay.modulate.a = 0
	_title_label.text = ""
	_quote_label.text = ""
	_chapter_label.text = ""
	visible = true
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, duration)
	await tween.finished

## 仅淡出黑屏（用于场景切换后）
func fade_from_black(duration: float = 0.4) -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, duration)
	await tween.finished
	visible = false

## 从 JSON 数据自动提取章节信息并显示
func show_from_level_data(data: Dictionary, callback: Callable = Callable()):
	var title = data.get("chapter_title", data.get("level_name", ""))
	var quote = data.get("chapter_quote", "")
	var chapter = data.get("chapter", 0)
	show_transition(title, quote, callback, chapter)

# ── 内部方法 ──────────────────────────────────────────

func _on_transition_done(callback: Callable):
	_is_active = false
	visible = false
	transition_finished.emit()
	if callback.is_valid():
		callback.call()

func _num_to_chinese(n: int) -> String:
	var map = {1: "一", 2: "二", 3: "三", 4: "四", 5: "五",
	           6: "六", 7: "七", 8: "八", 9: "九", 10: "十"}
	return map.get(n, str(n))

func _build_ui():
	# 全屏黑色遮罩
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0.02, 0.02, 0.05, 1.0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# 垂直布局容器
	var vbox = VBoxContainer.new()
	vbox.name = "Content"
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	vbox.custom_minimum_size = Vector2(600, 200)
	vbox.position = Vector2(-300, -100)
	_overlay.add_child(vbox)

	# 「第X章」小标
	_chapter_label = Label.new()
	_chapter_label.name = "ChapterLabel"
	_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_label.add_theme_font_size_override("font_size", 18)
	_chapter_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
	vbox.add_child(_chapter_label)

	# 章节标题
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	vbox.add_child(_title_label)

	# 分隔线
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(200, 2)
	sep.add_theme_stylebox_override("separator", StyleBoxFlat.new())
	var sep_style = sep.get_theme_stylebox("separator") as StyleBoxFlat
	if sep_style:
		sep_style.bg_color = Color(0.5, 0.45, 0.3, 0.6)
		sep_style.content_margin_top = 1
		sep_style.content_margin_bottom = 1
	vbox.add_child(sep)

	# 章节引语
	_quote_label = Label.new()
	_quote_label.name = "QuoteLabel"
	_quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quote_label.add_theme_font_size_override("font_size", 16)
	_quote_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_quote_label)
