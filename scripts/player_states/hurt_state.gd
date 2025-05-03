class_name HurtState
extends PlayerState

# 预加载ResourceManager类
const ResourceManagerClass = preload("res://scripts/resource_manager.gd")

# 受伤状态计时器
var hurt_timer = 0.0

func enter():
    player.animated_sprite.play("death")  # 使用死亡动画表示受伤状态
    hurt_timer = 0.0
    
    # 播放受伤音效
    # 使用资源管理器播放音效
    if Engine.has_singleton("ResourceManager"):
        Engine.get_singleton("ResourceManager").play_sound("hurt", player)
    else:
        # 兼容旧代码
        if player.hurt_sound:
            var audio_player = AudioStreamPlayer.new()
            audio_player.stream = player.hurt_sound
            audio_player.volume_db = -10.0  # 降低音量
            player.add_child(audio_player)
            audio_player.play()
            # 设置音频播放完成后自动清理
            audio_player.finished.connect(func(): audio_player.queue_free())

func physics_process(delta: float):
    # 应用重力
    player.velocity.y += player.gravity * delta
    
    # 减缓水平移动
    player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED * 2 * delta)
    
    # 更新受伤计时器
    hurt_timer += delta
    
    # 受伤状态持续一段时间后恢复
    if hurt_timer >= 0.5:  # 受伤状态持续0.5秒
        # 检查是否应该死亡
        if player.current_health <= 0:
            return "Death"
        
        # 根据玩家状态返回到适当的状态
        if player.is_on_floor():
            if abs(player.velocity.x) > 0.1:
                return "Run"
            else:
                return "Idle"
        else:
            return "Fall"
    
    return null