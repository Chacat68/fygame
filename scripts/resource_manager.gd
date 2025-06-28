extends Node

# 资源管理器单例
# 用于集中管理游戏中的所有资源预加载
# 避免在各个脚本中分散加载资源

# 音效资源
var sounds = {
	"jump": preload("res://assets/sounds/jump.wav"),
	"hurt": preload("res://assets/sounds/hurt.wav"),
	"coin": preload("res://assets/sounds/coin.wav"),
	"power_up": preload("res://assets/sounds/power_up.wav"),
	"explosion": preload("res://assets/sounds/explosion.wav"),
	"tap": preload("res://assets/sounds/tap.wav")
}

# 音乐资源
var music = {
	"adventure": preload("res://assets/music/time_for_adventure.mp3")
}

# 精灵资源
var sprites = {
	"knight": preload("res://assets/sprites/knight.png"),
	"coin": preload("res://assets/sprites/coin.png"),
	"slime_green": preload("res://assets/sprites/slime_green.png"),
	"slime_purple": preload("res://assets/sprites/slime_purple.png"),
	"platforms": preload("res://assets/sprites/platforms.png"),
	"world_tileset": preload("res://assets/sprites/world_tileset.png"),
	"fruit": preload("res://assets/sprites/fruit.png"),
	"coin_icon": preload("res://assets/sprites/coin_icon.png")
}

# 场景资源
var scenes = {
	"coin": preload("res://scenes/coin.tscn"),
	"slime": preload("res://scenes/slime.tscn"),
	"platform": preload("res://scenes/platform.tscn"),
	"floating_text": preload("res://scenes/floating_text.tscn")
}

# 获取音效资源
func get_sound(sound_name: String) -> AudioStream:
	if sounds.has(sound_name):
		return sounds[sound_name]
	else:
		push_error("Sound not found: " + sound_name)
		return null

# 获取音乐资源
func get_music(music_name: String) -> AudioStream:
	if music.has(music_name):
		return music[music_name]
	else:
		push_error("Music not found: " + music_name)
		return null

# 获取精灵资源
func get_sprite(sprite_name: String) -> Texture2D:
	if sprites.has(sprite_name):
		return sprites[sprite_name]
	else:
		push_error("Sprite not found: " + sprite_name)
		return null

# 获取场景资源
func get_scene(scene_name: String) -> PackedScene:
	if scenes.has(scene_name):
		return scenes[scene_name]
	else:
		push_error("Scene not found: " + scene_name)
		return null

# 播放音效的便捷方法
func play_sound(sound_name: String, parent_node: Node = null, volume_db: float = -10.0) -> AudioStreamPlayer:
	var sound = get_sound(sound_name)
	if sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = sound
		audio_player.volume_db = volume_db
		
		# 如果提供了父节点，添加到父节点
		if parent_node:
			parent_node.add_child(audio_player)
		else:
			# 否则添加到场景树的根节点
			var scene_tree = Engine.get_main_loop() as SceneTree
			if scene_tree:
				scene_tree.current_scene.add_child(audio_player)
		
		# 播放音效
		audio_player.play()
		
		# 设置音频播放完成后自动清理
		audio_player.finished.connect(func(): audio_player.queue_free())
		
		return audio_player
	return null