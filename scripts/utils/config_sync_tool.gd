# 开发工具：同步脚本默认值到资源文件
@tool
extends EditorScript

func _run():
    var script_config = GameConfig.new()  # 使用脚本默认值
    var resource_path = "res://resources/game_config.tres"
    
    # 保存为资源文件
    ResourceSaver.save(script_config, resource_path)
    print("配置已同步到资源文件")