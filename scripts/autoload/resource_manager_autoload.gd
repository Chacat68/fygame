extends Node

# 资源管理器自动加载脚本
# 将此脚本添加到项目设置的AutoLoad中，命名为"ResourceManager"

# 预加载ResourceManager脚本
const ResourceManagerScript = preload("res://scripts/resource_manager.gd")

# 资源管理器实例
var _resource_manager_instance: Node

# 在游戏启动时初始化资源管理器
func _ready():
	# 创建资源管理器实例
	_resource_manager_instance = ResourceManagerScript.new()
	print("资源管理器已初始化")

# 获取音效资源
func get_sound(sound_name: String) -> AudioStream:
	return _resource_manager_instance.get_sound(sound_name)

# 获取音乐资源
func get_music(music_name: String) -> AudioStream:
	return _resource_manager_instance.get_music(music_name)

# 获取精灵资源
func get_sprite(sprite_name: String) -> Texture2D:
	return _resource_manager_instance.get_sprite(sprite_name)

# 获取场景资源
func get_scene(scene_name: String) -> PackedScene:
	return _resource_manager_instance.get_scene(scene_name)

# 播放音效的便捷方法
func play_sound(sound_name: String, parent_node: Node = null, volume_db: float = -10.0) -> AudioStreamPlayer:
	return _resource_manager_instance.play_sound(sound_name, parent_node, volume_db)