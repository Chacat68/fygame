# 设置界面脚本
# 管理画面和音量设置
extends Control

# 信号
signal settings_changed()
signal back_pressed()

# 返回行为控制
@export var return_to_main_menu_on_back: bool = true

# UI组件引用 - 画面设置
@onready var window_mode_option: OptionButton = $CenterContainer/MainVBox/DisplaySection/DisplayMargin/DisplayContent/WindowModeContainer/WindowModeOption
@onready var resolution_option: OptionButton = $CenterContainer/MainVBox/DisplaySection/DisplayMargin/DisplayContent/ResolutionContainer/ResolutionOption

# UI组件引用 - 音量设置
@onready var master_volume_slider: HSlider = $CenterContainer/MainVBox/AudioSection/AudioMargin/AudioContent/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value: Label = $CenterContainer/MainVBox/AudioSection/AudioMargin/AudioContent/MasterVolumeContainer/MasterVolumeValue
@onready var music_volume_slider: HSlider = $CenterContainer/MainVBox/AudioSection/AudioMargin/AudioContent/MusicVolumeContainer/MusicVolumeSlider
@onready var music_volume_value: Label = $CenterContainer/MainVBox/AudioSection/AudioMargin/AudioContent/MusicVolumeContainer/MusicVolumeValue
@onready var sfx_volume_slider: HSlider = $CenterContainer/MainVBox/AudioSection/AudioMargin/AudioContent/SFXVolumeContainer/SFXVolumeSlider
@onready var sfx_volume_value: Label = $CenterContainer/MainVBox/AudioSection/AudioMargin/AudioContent/SFXVolumeContainer/SFXVolumeValue

# UI组件引用 - 按钮
@onready var apply_button: Button = $CenterContainer/MainVBox/ButtonsContainer/ApplyButton
@onready var back_button: Button = $CenterContainer/MainVBox/ButtonsContainer/BackButton
@onready var main_vbox: VBoxContainer = $CenterContainer/MainVBox

# 分辨率列表
var resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

# 设置数据
var settings_data: Dictionary = {
	"window_mode": 0,
	"resolution_index": 0,
	"master_volume": 0.8,
	"music_volume": 0.8,
	"sfx_volume": 1.0
}

# 设置文件路径
const SETTINGS_FILE_PATH = "user://settings.cfg"

# 动画
var tween: Tween

func _ready() -> void:
	# 连接信号
	_connect_signals()
	
	# 加载设置
	load_settings()
	
	# 应用当前设置到UI
	_apply_settings_to_ui()
	
	# 播放进入动画
	_play_enter_animation()

# 连接UI信号
func _connect_signals() -> void:
	if window_mode_option:
		window_mode_option.item_selected.connect(_on_window_mode_changed)
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_changed)
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

# 播放进入动画
func _play_enter_animation() -> void:
	if main_vbox:
		main_vbox.modulate.a = 0
		
		tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(main_vbox, "modulate:a", 1.0, 0.4)

# 应用设置到UI
func _apply_settings_to_ui() -> void:
	if window_mode_option:
		window_mode_option.selected = settings_data["window_mode"]
	
	if resolution_option:
		resolution_option.selected = settings_data["resolution_index"]
	
	if master_volume_slider:
		master_volume_slider.value = settings_data["master_volume"] * 100
		_update_volume_label(master_volume_value, settings_data["master_volume"])
	
	if music_volume_slider:
		music_volume_slider.value = settings_data["music_volume"] * 100
		_update_volume_label(music_volume_value, settings_data["music_volume"])
	
	if sfx_volume_slider:
		sfx_volume_slider.value = settings_data["sfx_volume"] * 100
		_update_volume_label(sfx_volume_value, settings_data["sfx_volume"])

# 更新音量标签
func _update_volume_label(label: Label, value: float) -> void:
	if label:
		label.text = "%d%%" % int(value * 100)

# 窗口模式改变
func _on_window_mode_changed(index: int) -> void:
	settings_data["window_mode"] = index
	_apply_window_mode(index)

# 分辨率改变
func _on_resolution_changed(index: int) -> void:
	settings_data["resolution_index"] = index
	_apply_resolution(index)

# 主音量改变
func _on_master_volume_changed(value: float) -> void:
	var volume = value / 100.0
	settings_data["master_volume"] = volume
	_update_volume_label(master_volume_value, volume)
	_apply_master_volume(volume)

# 音乐音量改变
func _on_music_volume_changed(value: float) -> void:
	var volume = value / 100.0
	settings_data["music_volume"] = volume
	_update_volume_label(music_volume_value, volume)
	_apply_music_volume(volume)

# 音效音量改变
func _on_sfx_volume_changed(value: float) -> void:
	var volume = value / 100.0
	settings_data["sfx_volume"] = volume
	_update_volume_label(sfx_volume_value, volume)
	_apply_sfx_volume(volume)

# 应用窗口模式
func _apply_window_mode(mode: int) -> void:
	match mode:
		0: # 窗口化
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: # 全屏
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: # 无边框窗口
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

# 应用分辨率
func _apply_resolution(index: int) -> void:
	if index >= 0 and index < resolutions.size():
		var resolution = resolutions[index]
		
		# 检查是否在编辑器嵌入模式下运行
		if OS.has_feature("editor"):
			var window_flags = DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED)
			if window_flags:
				print("[设置] 编辑器嵌入模式下无法调整窗口大小，请导出游戏或使用独立窗口测试")
				return
		
		# 检查当前窗口模式
		var current_mode = DisplayServer.window_get_mode()
		
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			# 全屏模式下不需要改变窗口大小
			print("[设置] 全屏模式下无法更改分辨率")
			return
		
		# 窗口模式下只改变窗口大小，不改变视口缩放
		# 这样 canvas_items 拉伸模式会自动处理UI缩放
		DisplayServer.window_set_size(resolution)
		
		# 居中窗口
		var screen_size = DisplayServer.screen_get_size()
		@warning_ignore("integer_division")
		var window_pos = (screen_size - resolution) / 2
		DisplayServer.window_set_position(window_pos)
		
		print("[设置] 窗口大小已设置为: %dx%d" % [resolution.x, resolution.y])

# 应用主音量
func _apply_master_volume(volume: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
	
	# 如果有音频管理器，也更新它
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_bus_volume"):
		audio_manager.set_bus_volume(0, volume) # 0 = MASTER

# 应用音乐音量
func _apply_music_volume(volume: float) -> void:
	var bus_index = AudioServer.get_bus_index("Music")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
	
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_bus_volume"):
		audio_manager.set_bus_volume(1, volume) # 1 = MUSIC

# 应用音效音量
func _apply_sfx_volume(volume: float) -> void:
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
	
	var audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("set_bus_volume"):
		audio_manager.set_bus_volume(2, volume) # 2 = SFX

# 应用按钮点击
func _on_apply_pressed() -> void:
	save_settings()
	settings_changed.emit()
	print("[设置] 设置已保存")

# 返回按钮点击
func _on_back_pressed() -> void:
	save_settings()
	back_pressed.emit()
	if return_to_main_menu_on_back:
		get_tree().change_scene_to_file("res://scenes/ui/game_start_screen.tscn")

# 保存设置
func save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("display", "window_mode", settings_data["window_mode"])
	config.set_value("display", "resolution_index", settings_data["resolution_index"])
	config.set_value("audio", "master_volume", settings_data["master_volume"])
	config.set_value("audio", "music_volume", settings_data["music_volume"])
	config.set_value("audio", "sfx_volume", settings_data["sfx_volume"])
	
	var error = config.save(SETTINGS_FILE_PATH)
	if error != OK:
		push_error("[设置] 保存设置失败: %d" % error)

# 加载设置
func load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE_PATH)
	
	if error == OK:
		settings_data["window_mode"] = config.get_value("display", "window_mode", 0)
		settings_data["resolution_index"] = config.get_value("display", "resolution_index", 0)
		settings_data["master_volume"] = config.get_value("audio", "master_volume", 0.8)
		settings_data["music_volume"] = config.get_value("audio", "music_volume", 0.8)
		settings_data["sfx_volume"] = config.get_value("audio", "sfx_volume", 1.0)
		
		# 应用加载的设置
		_apply_all_settings()
	else:
		print("[设置] 未找到设置文件，使用默认设置")

# 应用所有设置
func _apply_all_settings() -> void:
	_apply_window_mode(settings_data["window_mode"])
	_apply_resolution(settings_data["resolution_index"])
	_apply_master_volume(settings_data["master_volume"])
	_apply_music_volume(settings_data["music_volume"])
	_apply_sfx_volume(settings_data["sfx_volume"])

# ESC键返回
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
