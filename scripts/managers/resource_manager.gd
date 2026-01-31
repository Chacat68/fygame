extends Node

# 资源管理器类
# 注意：此类不应使用class_name，因为它被用作AutoLoad单例
# 用于集中管理游戏中的所有资源预加载
# 避免在各个脚本中分散加载资源

# 信号（暂时移除未使用的信号以避免警告）
# signal resource_loaded(resource_name: String, resource_type: String)
# signal resource_load_failed(resource_name: String, error_message: String)
# signal cache_cleared()

# 资源类型枚举
enum ResourceType {
	SOUND,
	MUSIC,
	SPRITE,
	SCENE,
	OTHER
}

# 资源优先级枚举
enum ResourcePriority {
	CRITICAL,  # 游戏启动必需的资源
	HIGH,      # 游戏核心功能资源
	MEDIUM,    # 常用资源
	LOW        # 可延迟加载的资源
}

# 预加载关键资源
var critical_sounds = {
	"jump": preload("res://assets/sounds/jump.wav"),
	"hurt": preload("res://assets/sounds/hurt.wav"),
	"coin": preload("res://assets/sounds/coin.wav"),
	"tap": preload("res://assets/sounds/tap.wav"),
	"power_up": preload("res://assets/sounds/power_up.wav"),
	"explosion": preload("res://assets/sounds/explosion.wav")
}

var critical_sprites = {
	"knight": preload("res://assets/sprites/knight.png"),
	"coin": preload("res://assets/sprites/coin.png"),
	"platforms": preload("res://assets/sprites/platforms.png")
}

# 基本变量
var sounds = {}
var music = {}
var sprites = {}
var scenes = {}

func _ready():
	# 将预加载的资源添加到对应的字典中
	for sound_name in critical_sounds:
		sounds[sound_name] = critical_sounds[sound_name]
	
	for sprite_name in critical_sprites:
		sprites[sprite_name] = critical_sprites[sprite_name]
	
	print("资源管理器初始化完成 - 已加载", sounds.size(), "个音效和", sprites.size(), "个精灵")

# 获取音效资源
func get_sound(sound_name: String) -> AudioStream:
	return sounds.get(sound_name, null)

# 获取音乐资源
func get_music(music_name: String) -> AudioStream:
	return music.get(music_name, null)

# 获取精灵资源
func get_sprite(sprite_name: String) -> Texture2D:
	return sprites.get(sprite_name, null)

# 获取场景资源
func get_scene(scene_name: String) -> PackedScene:
	return scenes.get(scene_name, null)
