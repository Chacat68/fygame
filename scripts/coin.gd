extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

func _on_body_shape_entered(body_id, body, body_shape, local_shape):
	game_manager.add_point()
	animation_player.play("pickup")
