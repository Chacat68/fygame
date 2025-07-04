# 调试覆盖层，实时显示和调整参数
extends Control

var config: GameConfig
var player: Node2D

func _ready():
    config = GameConfig.get_config()
    player = _get_player_node()  # 安全获取玩家节点
    
    # 创建调试UI
    create_debug_sliders()

func create_debug_sliders():
    var vbox = VBoxContainer.new()
    add_child(vbox)
    
    # 跳跃力度滑块
    var jump_slider = create_slider("跳跃力度", -800, -100, config.player_jump_velocity)
    jump_slider.value_changed.connect(_on_jump_changed)
    vbox.add_child(jump_slider)
    
    # 重力滑块
    var gravity_slider = create_slider("重力", 100, 1000, config.player_gravity)
    gravity_slider.value_changed.connect(_on_gravity_changed)
    vbox.add_child(gravity_slider)

func _on_jump_changed(value: float):
    if player:
        player.JUMP_VELOCITY = value
        print("跳跃力度调整为: ", value)

func create_slider(label_text: String, min_val: float, max_val: float, current_val: float) -> HSlider:
    # 创建标签
    var label = Label.new()
    label.text = label_text + ": " + str(current_val)
    
    # 创建滑块
    var slider = HSlider.new()
    slider.min_value = min_val
    slider.max_value = max_val
    slider.value = current_val
    slider.step = 1.0
    
    # 创建容器
    var container = VBoxContainer.new()
    container.add_child(label)
    container.add_child(slider)
    
    # 连接信号以更新标签
    slider.value_changed.connect(func(value): label.text = label_text + ": " + str(value))
    
    return slider

func _on_gravity_changed(value: float):
    if player:
        player.gravity = value
        print("重力调整为: ", value)

# 安全获取玩家节点的辅助方法
func _get_player_node() -> Node2D:
    # 优先从 Game 节点下查找
    var game_root = get_node_or_null("/root/Game")
    if game_root:
        var player_node = game_root.get_node_or_null("Player")
        if player_node:
            return player_node
    
    # 如果 Game 节点不存在，尝试在当前场景中通过组查找
    var players = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        return players[0]
    
    return null