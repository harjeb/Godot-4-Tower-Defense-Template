extends Node2D

## Direct Grass Map Launcher
## 直接启动Grass Map的场景

func _ready():
	print("=== Direct Grass Map Launcher ===")
	print("正在直接启动Grass Map...")
	
	# 设置选中的地图
	Globals.selected_map = "map1"
	print("已选择地图: Grass Map")
	
	# 等待一帧确保设置完成
	await get_tree().process_frame
	
	# 直接加载主场景
	print("加载主游戏场景...")
	var main_scene = preload("res://Scenes/main/main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	
	# 移除启动器
	queue_free()
	
	print("✅ Grass Map启动完成！")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("取消启动")
		get_tree().quit()