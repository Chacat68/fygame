# 存档槽位UI组件
# 显示单个存档槽位的信息和操作按钮
extends PanelContainer

# 信号
signal slot_selected(slot: int)
signal slot_deleted(slot: int)
signal new_game_requested(slot: int)

# 槽位索引
@export var slot_index: int = 0

# UI组件引用
@onready var slot_label: Label = $VBoxContainer/Header/SlotLabel
@onready var save_time_label: Label = $VBoxContainer/Info/SaveTimeLabel
@onready var level_label: Label = $VBoxContainer/Info/LevelLabel
@onready var coins_label: Label = $VBoxContainer/Info/CoinsLabel
@onready var play_time_label: Label = $VBoxContainer/Info/PlayTimeLabel
@onready var load_button: Button = $VBoxContainer/Buttons/LoadButton
@onready var delete_button: Button = $VBoxContainer/Buttons/DeleteButton
@onready var new_game_button: Button = $VBoxContainer/Buttons/NewGameButton
@onready var empty_label: Label = $VBoxContainer/EmptyLabel

# 存档数据
var save_data: SaveData = null
var is_empty: bool = true

func _ready() -> void:
	# 连接按钮信号
	load_button.pressed.connect(_on_load_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	
	# 初始化显示
	update_display(null)

# 设置槽位索引
func set_slot_index(index: int) -> void:
	slot_index = index
	if slot_label:
		slot_label.text = "存档槽位 %d" % (index + 1)

# 更新显示
func update_display(data: SaveData) -> void:
	save_data = data
	is_empty = (data == null)
	
	if slot_label:
		slot_label.text = "存档槽位 %d" % (slot_index + 1)
	
	if is_empty:
		# 显示空槽位
		_show_empty_slot()
	else:
		# 显示存档信息
		_show_save_info()

# 显示空槽位
func _show_empty_slot() -> void:
	if empty_label:
		empty_label.visible = true
		empty_label.text = "空存档槽位"
	
	# 隐藏存档信息
	if save_time_label:
		save_time_label.visible = false
	if level_label:
		level_label.visible = false
	if coins_label:
		coins_label.visible = false
	if play_time_label:
		play_time_label.visible = false
	
	# 更新按钮状态
	if load_button:
		load_button.visible = false
	if delete_button:
		delete_button.visible = false
	if new_game_button:
		new_game_button.visible = true
		new_game_button.text = "新游戏"

# 显示存档信息
func _show_save_info() -> void:
	if empty_label:
		empty_label.visible = false
	
	# 显示存档信息
	if save_time_label:
		save_time_label.visible = true
		save_time_label.text = "保存时间: %s" % save_data.get_formatted_save_time()
	
	if level_label:
		level_label.visible = true
		level_label.text = "关卡: %d" % save_data.current_level
	
	if coins_label:
		coins_label.visible = true
		coins_label.text = "金币: %d" % save_data.total_coins
	
	if play_time_label:
		play_time_label.visible = true
		play_time_label.text = "游戏时长: %s" % save_data.get_formatted_play_time()
	
	# 更新按钮状态
	if load_button:
		load_button.visible = true
		load_button.text = "读取存档"
	if delete_button:
		delete_button.visible = true
		delete_button.text = "删除"
	if new_game_button:
		new_game_button.visible = true
		new_game_button.text = "覆盖存档"

# 按钮回调
func _on_load_pressed() -> void:
	if not is_empty:
		slot_selected.emit(slot_index)

func _on_delete_pressed() -> void:
	if not is_empty:
		slot_deleted.emit(slot_index)

func _on_new_game_pressed() -> void:
	new_game_requested.emit(slot_index)
