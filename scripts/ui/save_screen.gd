# 存档界面脚本
# 管理存档的显示、加载、保存和删除操作
extends Control

# 信号
signal save_loaded(slot: int)
signal save_created(slot: int)
signal back_pressed()

# UI组件引用
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleContainer/TitleLabel
@onready var slots_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SlotsContainer
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/BackButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog
@onready var panel: PanelContainer = $Panel
@onready var error_label: Label = $Panel/MarginContainer/VBoxContainer/ErrorLabel

# 存档槽位UI场景
var save_slot_scene: PackedScene = preload("res://scenes/ui/save_slot.tscn")

# 关卡配置
const LEVEL_CONFIG_PATH := "res://resources/level_config.tres"

# 当前操作
var pending_action: String = ""
var pending_slot: int = -1

# 动画相关
var tween: Tween

func _ready() -> void:
	# 连接返回按钮
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# 连接确认对话框
	if confirm_dialog:
		confirm_dialog.confirmed.connect(_on_confirm_dialog_confirmed)
	
	# 刷新存档列表
	refresh_save_list()
	
	# 播放进入动画
	_play_enter_animation()

# 播放进入动画
func _play_enter_animation() -> void:
	if panel:
		panel.modulate.a = 0
		panel.scale = Vector2(0.95, 0.95)
		
		tween = create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.3)

# 刷新存档列表
func refresh_save_list() -> void:
	# 清空现有槽位
	for child in slots_container.get_children():
		child.queue_free()
	
	# 等待一帧确保清理完成
	await get_tree().process_frame
	
	# 获取所有存档信息
	var saves = SaveManager.get_all_save_info()
	
	# 创建槽位UI
	for i in range(SaveManager.MAX_SAVE_SLOTS):
		var slot_ui = save_slot_scene.instantiate()
		slots_container.add_child(slot_ui)
		
		slot_ui.set_slot_index(i)
		
		if i < saves.size():
			slot_ui.update_display(saves[i])
		else:
			slot_ui.update_display(null)
		
		# 连接信号
		slot_ui.slot_selected.connect(_on_slot_selected)
		slot_ui.slot_deleted.connect(_on_slot_deleted)
		slot_ui.new_game_requested.connect(_on_new_game_requested)

# 槽位选择回调
func _on_slot_selected(slot: int) -> void:
	Logger.debug("SaveUI", 选择加载存档槽位: %d" % slot)
	
	# 加载存档
	if SaveManager.load_game(slot):
		save_loaded.emit(slot)
		# 切换到游戏场景
		_start_game_from_save()
	else:
		_show_error("加载存档失败")

# 删除存档回调
func _on_slot_deleted(slot: int) -> void:
	pending_action = "delete"
	pending_slot = slot
	
	if confirm_dialog:
		confirm_dialog.dialog_text = "确定要删除存档槽位 %d 吗？\n此操作无法撤销！" % (slot + 1)
		confirm_dialog.popup_centered()

# 新游戏回调
func _on_new_game_requested(slot: int) -> void:
	# 检查槽位是否有存档
	if SaveManager.has_save(slot):
		pending_action = "overwrite"
		pending_slot = slot
		
		if confirm_dialog:
			confirm_dialog.dialog_text = "存档槽位 %d 已有存档，确定要覆盖吗？" % (slot + 1)
			confirm_dialog.popup_centered()
	else:
		_create_new_game(slot)

# 确认对话框回调
func _on_confirm_dialog_confirmed() -> void:
	match pending_action:
		"delete":
			_delete_save(pending_slot)
		"overwrite":
			_create_new_game(pending_slot)
	
	pending_action = ""
	pending_slot = -1

# 删除存档
func _delete_save(slot: int) -> void:
	if SaveManager.delete_save(slot):
		Logger.debug("SaveUI", 存档已删除: %d" % slot)
		refresh_save_list()
	else:
		_show_error("删除存档失败")

# 创建新游戏
func _create_new_game(slot: int) -> void:
	if SaveManager.create_new_save(slot):
		Logger.debug("SaveUI", 新游戏已创建: %d" % slot)
		save_created.emit(slot)
		_start_new_game()
	else:
		_show_error("创建存档失败")

# 从存档开始游戏
func _start_game_from_save() -> void:
	# 获取当前关卡
	var level = GameState.current_level
	var level_scene_path = _resolve_level_scene_path(level)
	get_tree().change_scene_to_file(level_scene_path)

# 开始新游戏
func _start_new_game() -> void:
	# 从第一关开始（根据配置或文件自动回退）
	var level_scene_path = _resolve_level_scene_path(1)
	Logger.debug("SaveUI", 新游戏场景路径: %s" % level_scene_path)
	get_tree().change_scene_to_file(level_scene_path)

# 返回按钮回调
func _on_back_pressed() -> void:
	back_pressed.emit()
	# 返回主菜单
	get_tree().change_scene_to_file("res://scenes/ui/game_start_screen.tscn")

# 显示错误信息
func _show_error(message: String) -> void:
	push_error("[SaveUI] %s" % message)
	if not error_label:
		return
	
	error_label.text = "✗ %s" % message
	error_label.visible = true
	
	await get_tree().create_timer(2.0).timeout
	if error_label:
		error_label.visible = false

# 解析关卡场景路径
func _resolve_level_scene_path(level: int) -> String:
	# 优先使用关卡配置资源
	if ResourceLoader.exists(LEVEL_CONFIG_PATH):
		var config = load(LEVEL_CONFIG_PATH)
		if config and config is LevelConfig:
			var configured_path = config.get_level_scene_path(level)
			if configured_path != "" and ResourceLoader.exists(configured_path):
				return configured_path

	# 回退到约定命名
	var fallback_path = "res://scenes/levels/lv%d.tscn" % level
	if ResourceLoader.exists(fallback_path):
		return fallback_path

	# 最后回退到第一关
	return "res://scenes/levels/lv1.tscn"
