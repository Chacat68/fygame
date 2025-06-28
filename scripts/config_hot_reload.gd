# 配置热重载系统
extends Node

var config_file_path = "res://resources/game_config.tres"
var last_modified_time: int = 0

func _ready():
    # 开发模式下启用热重载
    if OS.is_debug_build():
        set_process(true)

func _process(_delta):
    check_config_changes()

func check_config_changes():
    var file = FileAccess.open(config_file_path, FileAccess.READ)
    if file:
        var current_time = file.get_modified_time(config_file_path)
        if current_time != last_modified_time:
            last_modified_time = current_time
            reload_config()
        file.close()

func reload_config():
    print("检测到配置文件变化，重新加载...")
    # 通知所有使用配置的对象重新加载
    get_tree().call_group("config_users", "reload_config")