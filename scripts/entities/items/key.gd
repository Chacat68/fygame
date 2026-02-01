# 钥匙收集品
# 用于开启门或宝箱
class_name Key
extends CollectibleBase

@export_group("钥匙属性")
@export var key_id: String = "default"  # 钥匙ID，用于匹配特定的门
@export_enum("Bronze", "Silver", "Gold", "Master") var key_type: int = 0

# 钥匙颜色
var key_colors: Array[Color] = [
	Color(0.8, 0.5, 0.2),   # Bronze - 铜色
	Color(0.8, 0.8, 0.8),   # Silver - 银色
	Color(1.0, 0.85, 0.0),  # Gold - 金色
	Color(0.5, 0.0, 1.0)    # Master - 紫色
]

func _ready() -> void:
	value = 1
	bob_speed = 1.0
	rotate_enabled = true
	rotate_speed = 1.0
	
	super._ready()
	
	# 应用钥匙颜色
	_apply_key_color()

func _register_to_manager() -> void:
	if CollectibleManager:
		CollectibleManager.register_collectible(self, CollectibleManager.CollectibleType.KEY)

func _apply_key_color() -> void:
	var color = key_colors[key_type] if key_type < key_colors.size() else Color.WHITE
	
	if sprite:
		sprite.modulate = color
	elif animated_sprite:
		animated_sprite.modulate = color

func _apply_collection_effect(_player: Node) -> void:
	# 添加钥匙到游戏状态
	if GameState and GameState.has_method("add_key"):
		GameState.add_key(key_id)
	
	# 或者通过信号通知
	# 可以在外部监听 collected 信号并处理钥匙逻辑

func _play_collect_sound() -> void:
	if AudioManager:
		AudioManager.play_sfx("power_up")

func _show_collect_text() -> void:
	if FloatingTextManager:
		var key_names = ["铜钥匙", "银钥匙", "金钥匙", "万能钥匙"]
		var key_name = key_names[key_type] if key_type < key_names.size() else "钥匙"
		var color = key_colors[key_type] if key_type < key_colors.size() else Color.WHITE
		FloatingTextManager.show_text(global_position + Vector2(0, -20), "获得 " + key_name, color)
