@tool
extends Control

# 关卡生成器编辑器面板
# 双模式：加载 JSON / 随机生成

var editor_interface: EditorInterface

# ── UI 节点 ───────────────────────────────────────────

var _tab_bar: TabBar
var _json_page: VBoxContainer
var _random_page: ScrollContainer
var _preview_button: Button
var _generate_button: Button
var _clear_button: Button
var _output_path_edit: LineEdit
var _output_browse_button: Button
var _status_label: RichTextLabel
var _info_panel: RichTextLabel
var _preview_container: SubViewportContainer
var _preview_viewport: SubViewport

# JSON 模式
var _json_path_edit: LineEdit
var _browse_button: Button

# 随机模式控件
var _rand_level_name: LineEdit
var _rand_chapter: SpinBox
var _rand_difficulty: OptionButton
var _rand_theme_color: ColorPickerButton
var _rand_ground_segments: SpinBox
var _rand_coin_count: SpinBox
var _rand_enemy_count: SpinBox
var _rand_platform_count: SpinBox
var _rand_hazard_count: SpinBox
var _rand_checkpoint_count: SpinBox
var _rand_map_width: SpinBox
var _rand_map_height: SpinBox
var _rand_has_portal: CheckBox
var _rand_seed_input: SpinBox
var _randomize_button: Button

# 数据
var _current_data: Dictionary = {}
var _preview_root: Node2D = null
var _file_dialog: FileDialog
var _save_dialog: FileDialog
var _current_mode: int = 0 # 0 = JSON, 1 = 随机

func _ready():
	custom_minimum_size = Vector2(0, 400)
	_build_ui()

# ── UI 构建 ───────────────────────────────────────────

func _build_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 4)
	add_child(main_vbox)

	# ── 模式切换 Tab ──
	_tab_bar = TabBar.new()
	_tab_bar.add_tab("📂 加载 JSON")
	_tab_bar.add_tab("🎲 随机生成")
	_tab_bar.tab_changed.connect(_on_tab_changed)
	main_vbox.add_child(_tab_bar)

	# ── 模式页面容器 ──
	var page_container = MarginContainer.new()
	page_container.custom_minimum_size = Vector2(0, 120)
	main_vbox.add_child(page_container)

	# JSON 模式页
	_json_page = VBoxContainer.new()
	_json_page.add_theme_constant_override("separation", 4)
	page_container.add_child(_json_page)
	_build_json_page()

	# 随机模式页
	_random_page = ScrollContainer.new()
	_random_page.visible = false
	_random_page.custom_minimum_size = Vector2(0, 120)
	page_container.add_child(_random_page)
	_build_random_page()

	# ── 输出路径 + 操作按钮 ──
	var export_bar = HBoxContainer.new()
	export_bar.add_theme_constant_override("separation", 4)
	main_vbox.add_child(export_bar)

	var out_label = Label.new()
	out_label.text = "输出："
	export_bar.add_child(out_label)

	_output_path_edit = LineEdit.new()
	_output_path_edit.placeholder_text = "自动生成路径..."
	_output_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_bar.add_child(_output_path_edit)

	_output_browse_button = Button.new()
	_output_browse_button.text = "📂"
	_output_browse_button.pressed.connect(_on_output_browse_pressed)
	export_bar.add_child(_output_browse_button)

	var btn_bar = HBoxContainer.new()
	btn_bar.add_theme_constant_override("separation", 4)
	main_vbox.add_child(btn_bar)

	# 随机模式专用按钮（仅随机模式可见）
	_randomize_button = Button.new()
	_randomize_button.text = "🎲 随机生成"
	_randomize_button.pressed.connect(_on_randomize_pressed)
	_randomize_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_randomize_button.visible = false
	_apply_accent_style(_randomize_button)
	btn_bar.add_child(_randomize_button)

	_preview_button = Button.new()
	_preview_button.text = "👁 预览"
	_preview_button.disabled = true
	_preview_button.pressed.connect(_on_preview_pressed)
	_preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.add_child(_preview_button)

	_clear_button = Button.new()
	_clear_button.text = "🗑 清除"
	_clear_button.pressed.connect(_on_clear_pressed)
	_clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_bar.add_child(_clear_button)

	_generate_button = Button.new()
	_generate_button.text = "🔨 生成场景"
	_generate_button.disabled = true
	_generate_button.pressed.connect(_on_generate_pressed)
	_generate_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_accent_style(_generate_button)
	btn_bar.add_child(_generate_button)

	# ── 内容区域（左信息 + 右预览）──
	var content_split = HSplitContainer.new()
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_split)

	_info_panel = RichTextLabel.new()
	_info_panel.custom_minimum_size = Vector2(260, 0)
	_info_panel.bbcode_enabled = true
	_info_panel.text = "[color=gray]选择模式开始...[/color]"
	_info_panel.fit_content = false
	_info_panel.scroll_following = true
	content_split.add_child(_info_panel)

	_preview_container = SubViewportContainer.new()
	_preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_container.stretch = true
	content_split.add_child(_preview_container)

	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2(600, 400)
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_preview_viewport.transparent_bg = false
	_preview_container.add_child(_preview_viewport)

	var placeholder = ColorRect.new()
	placeholder.color = Color(0.1, 0.1, 0.12)
	placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_viewport.add_child(placeholder)

	var placeholder_text = Label.new()
	placeholder_text.text = "点击「预览」查看生成结果"
	placeholder_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	placeholder_text.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	_preview_viewport.add_child(placeholder_text)

	# ── 底部状态栏 ──
	_status_label = RichTextLabel.new()
	_status_label.custom_minimum_size = Vector2(0, 24)
	_status_label.bbcode_enabled = true
	_status_label.fit_content = true
	_status_label.text = "[color=gray]就绪[/color]"
	main_vbox.add_child(_status_label)

# ── JSON 模式页面 ─────────────────────────────────────

func _build_json_page():
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	_json_page.add_child(hbox)

	var label = Label.new()
	label.text = "JSON 文件："
	hbox.add_child(label)

	_json_path_edit = LineEdit.new()
	_json_path_edit.placeholder_text = "选择关卡 JSON 数据文件..."
	_json_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_json_path_edit.editable = false
	hbox.add_child(_json_path_edit)

	_browse_button = Button.new()
	_browse_button.text = "📂 浏览"
	_browse_button.pressed.connect(_on_browse_pressed)
	hbox.add_child(_browse_button)

# ── 随机模式页面 ──────────────────────────────────────

func _build_random_page():
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_random_page.add_child(vbox)

	# ── 基本信息行 ──
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	vbox.add_child(info_row)

	# 关卡名
	info_row.add_child(_make_label("名称："))
	_rand_level_name = LineEdit.new()
	_rand_level_name.text = "随机关卡"
	_rand_level_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(_rand_level_name)

	# 章节号
	info_row.add_child(_make_label("章："))
	_rand_chapter = SpinBox.new()
	_rand_chapter.min_value = 1
	_rand_chapter.max_value = 10
	_rand_chapter.value = 1
	info_row.add_child(_rand_chapter)

	# 难度
	info_row.add_child(_make_label("难度："))
	_rand_difficulty = OptionButton.new()
	_rand_difficulty.add_item("简单", 0)
	_rand_difficulty.add_item("普通", 1)
	_rand_difficulty.add_item("困难", 2)
	_rand_difficulty.add_item("噩梦", 3)
	_rand_difficulty.selected = 1
	info_row.add_child(_rand_difficulty)

	# ── 地形参数行 ──
	var terrain_row = HBoxContainer.new()
	terrain_row.add_theme_constant_override("separation", 8)
	vbox.add_child(terrain_row)

	terrain_row.add_child(_make_label("地形色："))
	_rand_theme_color = ColorPickerButton.new()
	_rand_theme_color.color = Color(0.3, 0.5, 0.25)
	_rand_theme_color.custom_minimum_size = Vector2(40, 24)
	terrain_row.add_child(_rand_theme_color)

	terrain_row.add_child(_make_label("地块数："))
	_rand_ground_segments = SpinBox.new()
	_rand_ground_segments.min_value = 1
	_rand_ground_segments.max_value = 20
	_rand_ground_segments.value = 4
	terrain_row.add_child(_rand_ground_segments)

	terrain_row.add_child(_make_label("宽："))
	_rand_map_width = SpinBox.new()
	_rand_map_width.min_value = 400
	_rand_map_width.max_value = 5000
	_rand_map_width.step = 100
	_rand_map_width.value = 1600
	terrain_row.add_child(_rand_map_width)

	terrain_row.add_child(_make_label("高："))
	_rand_map_height = SpinBox.new()
	_rand_map_height.min_value = 200
	_rand_map_height.max_value = 2000
	_rand_map_height.step = 50
	_rand_map_height.value = 400
	terrain_row.add_child(_rand_map_height)

	# ── 实体数量行 ──
	var entity_row = HBoxContainer.new()
	entity_row.add_theme_constant_override("separation", 8)
	vbox.add_child(entity_row)

	entity_row.add_child(_make_label("💰："))
	_rand_coin_count = SpinBox.new()
	_rand_coin_count.min_value = 0
	_rand_coin_count.max_value = 50
	_rand_coin_count.value = 8
	entity_row.add_child(_rand_coin_count)

	entity_row.add_child(_make_label("👾："))
	_rand_enemy_count = SpinBox.new()
	_rand_enemy_count.min_value = 0
	_rand_enemy_count.max_value = 20
	_rand_enemy_count.value = 3
	entity_row.add_child(_rand_enemy_count)

	entity_row.add_child(_make_label("🟫："))
	_rand_platform_count = SpinBox.new()
	_rand_platform_count.min_value = 0
	_rand_platform_count.max_value = 30
	_rand_platform_count.value = 5
	entity_row.add_child(_rand_platform_count)

	entity_row.add_child(_make_label("⚠️："))
	_rand_hazard_count = SpinBox.new()
	_rand_hazard_count.min_value = 0
	_rand_hazard_count.max_value = 15
	_rand_hazard_count.value = 2
	entity_row.add_child(_rand_hazard_count)

	entity_row.add_child(_make_label("🚩："))
	_rand_checkpoint_count = SpinBox.new()
	_rand_checkpoint_count.min_value = 0
	_rand_checkpoint_count.max_value = 10
	_rand_checkpoint_count.value = 1
	entity_row.add_child(_rand_checkpoint_count)

	# ── 杂项行 ──
	var misc_row = HBoxContainer.new()
	misc_row.add_theme_constant_override("separation", 8)
	vbox.add_child(misc_row)

	_rand_has_portal = CheckBox.new()
	_rand_has_portal.text = "生成传送门"
	_rand_has_portal.button_pressed = true
	misc_row.add_child(_rand_has_portal)

	misc_row.add_child(_make_label("种子："))
	_rand_seed_input = SpinBox.new()
	_rand_seed_input.min_value = 0
	_rand_seed_input.max_value = 99999
	_rand_seed_input.value = 0
	_rand_seed_input.tooltip_text = "0 = 真随机"
	misc_row.add_child(_rand_seed_input)

# ── 模式切换 ──────────────────────────────────────────

func _on_tab_changed(tab: int):
	_current_mode = tab
	_json_page.visible = (tab == 0)
	_random_page.visible = (tab == 1)
	_randomize_button.visible = (tab == 1)
	if tab == 0:
		_info_panel.text = "[color=gray]选择一个 JSON 文件开始...[/color]"
	else:
		_info_panel.text = "[color=gray]配置参数后点击「🎲 随机生成」...[/color]"

# ── JSON 模式事件 ─────────────────────────────────────

func _on_browse_pressed():
	if _file_dialog and is_instance_valid(_file_dialog):
		_file_dialog.queue_free()
		_file_dialog = null
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.filters = PackedStringArray(["*.json ; JSON 关卡数据"])
	_file_dialog.current_dir = "res://resources/level_data"
	_file_dialog.title = "选择关卡 JSON"
	_file_dialog.size = Vector2(700, 500)
	_file_dialog.file_selected.connect(_on_json_selected)
	_file_dialog.canceled.connect(_on_dialog_canceled.bind("file"))
	add_child(_file_dialog)
	_file_dialog.popup_centered()

func _on_json_selected(path: String):
	_json_path_edit.text = path
	_load_json(path)
	_cleanup_file_dialog()

func _load_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		_set_status("❌ 无法打开文件: " + path, "red")
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		_set_status("❌ JSON 解析失败: " + json.get_error_message(), "red")
		return
	_current_data = json.data
	_display_info()
	var level_id = _current_data.get("level_id", 0)
	if level_id > 0:
		_output_path_edit.text = "res://scenes/levels/lv%d_generated.tscn" % level_id
	_preview_button.disabled = false
	_generate_button.disabled = false
	_set_status("✅ 已加载: " + path, "green")

# ── 随机生成事件 ──────────────────────────────────────

func _on_randomize_pressed():
	var seed_val = int(_rand_seed_input.value)
	if seed_val > 0:
		seed(seed_val)
	else:
		randomize()

	var map_w = _rand_map_width.value
	var map_h = _rand_map_height.value
	var difficulty_names = ["简单", "普通", "困难", "噩梦"]
	var diff_idx = _rand_difficulty.selected

	_current_data = {
		"level_id": int(_rand_chapter.value) * 100 + randi() % 99,
		"level_name": _rand_level_name.text,
		"chapter": int(_rand_chapter.value),
		"difficulty": difficulty_names[diff_idx],
		"theme": "随机",
	}

	# ── 地形 ──
	var color = _rand_theme_color.color
	var segments = []
	var seg_count = int(_rand_ground_segments.value)
	var seg_width = map_w / seg_count
	var gap_chance = 0.15 + diff_idx * 0.1 # 难度越高间隙越多
	var base_y = map_h * 0.7

	for i in range(seg_count):
		if i > 0 and i < seg_count - 1 and randf() < gap_chance:
			continue # 跳过 = 间隙
		var x = i * seg_width + randf_range(-20, 20)
		var y = base_y + randf_range(-40, 40)
		var w = seg_width * randf_range(0.7, 0.95)
		var h = randf_range(28, 48)
		segments.append({"x": x, "y": y, "width": w, "height": h})

	# 确保至少有起点和终点地块
	if segments.is_empty():
		segments.append({"x": 0, "y": base_y, "width": seg_width, "height": 36})
	if segments.size() == 1:
		segments.append({"x": map_w - seg_width, "y": base_y, "width": seg_width, "height": 36})

	_current_data["ground"] = {
		"color": [color.r, color.g, color.b],
		"border_color": [color.darkened(0.3).r, color.darkened(0.3).g, color.darkened(0.3).b],
		"segments": segments
	}

	# ── 玩家 ──
	var first_seg = segments[0]
	_current_data["player"] = {
		"position": [first_seg["x"] + 50, first_seg["y"] - 60]
	}

	# ── 相机 ──
	_current_data["camera"] = {
		"position": [map_w / 2, map_h / 2 - 50],
		"zoom": [2.5, 2.5],
		"limit_left": int(-100),
		"limit_bottom": int(map_h + 100),
		"smooth": true
	}

	# ── Killzone ──
	_current_data["killzone"] = {"y_position": int(map_h + 50)}

	# ── 金币 ──
	var coins = []
	for i in range(int(_rand_coin_count.value)):
		var seg = segments[randi() % segments.size()]
		var cx = seg["x"] + randf_range(10, seg["width"] - 10)
		var cy = seg["y"] - randf_range(30, 80)
		coins.append({"position": [int(cx), int(cy)]})
	if not coins.is_empty():
		_current_data["coins"] = coins

	# ── 敌人 ──
	var enemies = []
	for i in range(int(_rand_enemy_count.value)):
		var seg = segments[randi() % segments.size()]
		var ex = seg["x"] + randf_range(20, seg["width"] - 20)
		var ey = seg["y"] - 20
		enemies.append({"type": "slime", "position": [int(ex), int(ey)]})
	if not enemies.is_empty():
		_current_data["enemies"] = enemies

	# ── 平台 ──
	var platforms = []
	for i in range(int(_rand_platform_count.value)):
		var px = randf_range(0, map_w)
		var py = randf_range(base_y - 150, base_y - 40)
		var is_moving = randf() < 0.3
		var pd = {"position": [int(px), int(py)], "is_moving": is_moving}
		if is_moving:
			pd["move_distance"] = int(randf_range(40, 120))
			pd["move_direction"] = "horizontal" if randf() < 0.7 else "vertical"
			pd["move_duration"] = snappedf(randf_range(1.5, 4.0), 0.5)
		platforms.append(pd)
	if not platforms.is_empty():
		_current_data["platforms"] = platforms

	# ── 陷阱 ──
	var hazards = []
	var hazard_types = ["spikes", "saw_blade", "springboard"]
	for i in range(int(_rand_hazard_count.value)):
		var seg = segments[randi() % segments.size()]
		var hx = seg["x"] + randf_range(20, seg["width"] - 20)
		var hy = seg["y"] - 10
		var htype = hazard_types[randi() % hazard_types.size()]
		hazards.append({"type": htype, "position": [int(hx), int(hy)]})
	if not hazards.is_empty():
		_current_data["hazards"] = hazards

	# ── 检查点 ──
	var checkpoints = []
	for i in range(int(_rand_checkpoint_count.value)):
		var seg = segments[clampi(int(segments.size() * (i + 1.0) / (_rand_checkpoint_count.value + 1)), 0, segments.size() - 1)]
		var cpx = seg["x"] + seg["width"] / 2
		var cpy = seg["y"] - 30
		checkpoints.append({"position": [int(cpx), int(cpy)]})
	if not checkpoints.is_empty():
		_current_data["checkpoints"] = checkpoints

	# ── 传送门 ──
	if _rand_has_portal.button_pressed:
		var last_seg = segments[segments.size() - 1]
		_current_data["portal"] = {
			"position": [int(last_seg["x"] + last_seg["width"] - 30), int(last_seg["y"] - 40)],
			"destination_scene": "res://scenes/ui/game_start_screen.tscn"
		}

	# 更新 UI
	_display_info()
	_output_path_edit.text = "res://scenes/levels/lv_random_%d.tscn" % _current_data["level_id"]
	_preview_button.disabled = false
	_generate_button.disabled = false
	_set_status("🎲 随机数据已生成 (种子: %s)" % ("真随机" if seed_val == 0 else str(seed_val)), "green")

# ── 共享事件 ──────────────────────────────────────────

func _on_output_browse_pressed():
	if _save_dialog and is_instance_valid(_save_dialog):
		_save_dialog.queue_free()
		_save_dialog = null
	_save_dialog = FileDialog.new()
	_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = FileDialog.ACCESS_RESOURCES
	_save_dialog.filters = PackedStringArray(["*.tscn ; Godot 场景"])
	_save_dialog.current_dir = "res://scenes/levels"
	_save_dialog.title = "保存生成的场景"
	_save_dialog.size = Vector2(700, 500)
	_save_dialog.file_selected.connect(func(p): _output_path_edit.text = p; _cleanup_save_dialog())
	_save_dialog.canceled.connect(_on_dialog_canceled.bind("save"))
	add_child(_save_dialog)
	_save_dialog.popup_centered()

func _on_dialog_canceled(dialog_type: String):
	if dialog_type == "file":
		_cleanup_file_dialog()
	elif dialog_type == "save":
		_cleanup_save_dialog()

func _cleanup_file_dialog():
	if _file_dialog and is_instance_valid(_file_dialog):
		_file_dialog.queue_free()
		_file_dialog = null

func _cleanup_save_dialog():
	if _save_dialog and is_instance_valid(_save_dialog):
		_save_dialog.queue_free()
		_save_dialog = null

func _on_preview_pressed():
	if _current_data.is_empty():
		return
	_generate_preview()

func _on_clear_pressed():
	_clear_preview()
	_current_data.clear()
	if _current_mode == 0:
		_json_path_edit.text = ""
	_output_path_edit.text = ""
	_preview_button.disabled = true
	_generate_button.disabled = true
	_info_panel.text = "[color=gray]已清除[/color]"
	_set_status("已清除", "gray")

func _on_generate_pressed():
	if _current_data.is_empty():
		return
	_generate_scene()

# ── 信息显示 ──────────────────────────────────────────

func _display_info():
	var d = _current_data
	var text := ""

	text += "[b][color=white]%s[/color][/b]\n" % d.get("level_name", "未命名")
	text += "[color=gray]━━━━━━━━━━━━━━━━━━━━[/color]\n"

	if d.has("chapter_quote"):
		text += "[i][color=#b0a080]「%s」[/color][/i]\n\n" % d["chapter_quote"]

	text += "[color=yellow]难度:[/color] %s\n" % d.get("difficulty", "未知")
	text += "[color=yellow]主题:[/color] %s\n\n" % d.get("theme", "未知")

	text += "[b][color=#88aacc]实体统计[/color][/b]\n"
	text += "[color=gray]────────────────────[/color]\n"

	var stats = {
		"coins": "💰 金币",
		"platforms": "🟫 平台",
		"enemies": "👾 敌人",
		"hazards": "⚠️ 陷阱",
		"labels": "📝 标签",
		"checkpoints": "🚩 检查点"
	}
	for key in stats:
		if d.has(key) and d[key] is Array:
			text += "%s: [color=white]%d[/color]\n" % [stats[key], d[key].size()]

	if d.has("boss"):
		text += "👹 Boss: [color=red]%s[/color]\n" % d["boss"].get("type", "未知")

	if d.has("ground"):
		var segs = d["ground"].get("segments", [])
		text += "🟫 地块: [color=white]%d 段[/color]\n" % segs.size()

	if d.has("player"):
		var pos = d["player"].get("position", [0, 0])
		text += "\n[color=yellow]出生点:[/color] (%d, %d)\n" % [pos[0], pos[1]]

	if d.has("portal"):
		text += "[color=yellow]传送:[/color] %s\n" % d["portal"].get("destination_scene", "未设置")

	_info_panel.text = text

# ── 生成与预览 ────────────────────────────────────────

func _generate_preview():
	_clear_preview()
	_set_status("⏳ 正在生成预览...", "yellow")

	var generator = LevelGenerator.new()
	_preview_viewport.add_child(generator)
	await get_tree().process_frame

	_preview_root = generator.generate_level(_current_data)
	if _preview_root:
		_preview_viewport.add_child(_preview_root)
		var camera = Camera2D.new()
		camera.name = "PreviewCamera"
		camera.zoom = Vector2(1.5, 1.5)
		if _current_data.has("player"):
			var pos = _current_data["player"].get("position", [0, 0])
			camera.position = Vector2(pos[0], pos[1])
		camera.make_current()
		_preview_root.add_child(camera)
		_set_status("✅ 预览已生成 — %d 个子节点" % _preview_root.get_child_count(), "green")
	else:
		_set_status("❌ 预览生成失败", "red")
	generator.queue_free()

func _clear_preview():
	if _preview_root and is_instance_valid(_preview_root):
		_preview_root.queue_free()
		_preview_root = null

func _generate_scene():
	var output_path = _output_path_edit.text.strip_edges()
	if output_path.is_empty():
		_set_status("❌ 请设置输出路径", "red")
		return

	_set_status("⏳ 正在生成...", "yellow")

	# 1. 保存 JSON 数据文件
	var json_path = output_path.replace(".tscn", ".json")
	var json_str = JSON.stringify(_current_data, "\t")
	var json_file = FileAccess.open(json_path, FileAccess.WRITE)
	if not json_file:
		_set_status("❌ 无法写入 JSON: " + json_path, "red")
		return
	json_file.store_string(json_str)
	json_file.close()

	# 2. 生成最小 .tscn 文件（仅引用脚本 + JSON 路径）
	# 这样完全不会有内联子场景的问题
	var level_name = _current_data.get("level_name", "Level")
	var tscn_content = '[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/systems/level_runtime.gd" id="1"]

[node name="%s" type="Node2D"]
script = ExtResource("1")
json_data_path = "%s"
' % [level_name, json_path]

	var tscn_file = FileAccess.open(output_path, FileAccess.WRITE)
	if not tscn_file:
		_set_status("❌ 无法写入场景: " + output_path, "red")
		return
	tscn_file.store_string(tscn_content)
	tscn_file.close()

	# 3. 刷新编辑器
	if editor_interface:
		editor_interface.get_resource_filesystem().scan()

	_set_status("✅ 已保存: %s + %s" % [output_path.get_file(), json_path.get_file()], "green")

func _save_json(path: String):
	var json_str = JSON.stringify(_current_data, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		_set_status("✅ 已保存: .tscn + .json", "green")

func _set_owner_recursive(node: Node, owner: Node):
	for child in node.get_children():
		child.owner = owner
		# 如果子节点是从 .tscn 实例化的（有 scene_file_path），
		# 不要递归设置其内部子节点的 owner，
		# 这样 PackedScene.pack() 会保存为场景引用而非内联展开
		if child.scene_file_path.is_empty():
			_set_owner_recursive(child, owner)

# ── 工具方法 ──────────────────────────────────────────

func _make_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	return l

func _set_status(text: String, color: String = "white"):
	if _status_label:
		_status_label.text = "[color=%s]%s[/color]" % [color, text]

func _apply_accent_style(btn: Button):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.45, 0.7)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.25, 0.5, 0.8)
	btn.add_theme_stylebox_override("hover", hover)
