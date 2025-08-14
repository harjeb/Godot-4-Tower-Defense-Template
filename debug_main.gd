extends Node

## Debug Main Scene
## 快速测试游戏启动和地图加载流程

func _ready():
	print("=== 调试开始 ===")
	
	# 等待一帧确保所有系统初始化
	await get_tree().process_frame
	
	# 模拟选择第一张地图
	print("设置地图为 map1")
	Globals.selected_map = "map1"
	
	# 等待一帧
	await get_tree().process_frame
	
	# 直接加载主游戏场景
	print("加载主游戏场景...")
	var main_scene = load("res://Scenes/main/main.tscn")
	if main_scene:
		print("主场景加载成功，切换到游戏场景")
		get_tree().change_scene_to_packed(main_scene)
	else:
		print("错误：无法加载主场景")
		get_tree().quit()

func _input(event):
	# 按ESC退出
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("=== 调试结束 ===")
		get_tree().quit()