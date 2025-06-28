class_name DeathState
extends PlayerState

# 死亡状态计时器
var death_timer = 0.0
var scene_reload_triggered = false

func enter():
    player.animated_sprite.play("death")
    death_timer = 0.0
    scene_reload_triggered = false
    
    # 禁用碰撞体，防止与其他物体交互
    if player.has_node("CollisionShape2D"):
        player.get_node("CollisionShape2D").set_deferred("disabled", true)

func physics_process(delta: float):
    # 应用重力（如果需要的话）
    player.velocity.y += player.gravity * delta
    
    # 停止水平移动
    player.velocity.x = 0
    
    # 更新死亡计时器
    death_timer += delta
    
    # 死亡动画播放一段时间后重新加载场景
    if death_timer >= 1.5 and not scene_reload_triggered:  # 死亡动画持续1.5秒
        scene_reload_triggered = true
        
        # 设置GameState中的复活标志
        if Engine.has_singleton("GameState"):
            Engine.get_singleton("GameState").set_player_respawning(true)
        
        # 使用call_deferred延迟重新加载场景，确保在物理处理完成后执行
        player.get_tree().call_deferred("reload_current_scene")
    
    return null