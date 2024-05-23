extends Area2D

@onready var tilmer = $Timer

func _on_body_entered(body):
	print("You Died!")
	Engine.time_scale = 0.5
	body.get_node("CollisionShape2D").qveve_free()
	tilmer.start()


func _on_timer_timeout():
	Engine.time_scale = 1
	get_tree().reload_current_scene()
 
