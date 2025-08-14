extends Node2D

## Command Line Argument Processor
## Handles different launch modes based on command line arguments

func _ready():
	var args = OS.get_cmdline_args()
	print("命令行参数: ", args)
	
	# 首先进行启动错误检查
	var startup_checker = preload("res://Scenes/utils/StartupErrorChecker.gd").new()
	add_child(startup_checker)
	startup_checker.check_startup_errors()
	
	# 等待一帧让错误检查完成
	await get_tree().process_frame
	
	# 检查是否有严重错误阻止启动
	if startup_checker.get_project_startup_errors().size() > 0:
		print("发现严重启动错误，停止启动流程")
		return
	
	# Check for test mode
	if "--simple-test" in args:
		print("启动简单代码测试模式...")
		start_simple_test()
	elif "--test" in args or "--automated-test" in args:
		print("启动自动化测试模式...")
		start_automated_test()
	elif "--quick-test" in args:
		print("启动快速测试模式...")
		start_quick_test()
	else:
		print("启动正常游戏模式...")
		start_normal_game()

func start_simple_test():
	var test_scene = preload("res://Scenes/test/simple_code_test.tscn").instantiate()
	get_tree().root.add_child(test_scene)
	
	# Remove this node
	queue_free()

func start_automated_test():
	var test_scene = preload("res://Scenes/test/automated_test_entry.tscn").instantiate()
	get_tree().root.add_child(test_scene)
	
	# Remove this node
	queue_free()

func start_quick_test():
	print("快速测试模式 - 直接跳转到主游戏场景")
	Globals.selected_map = "map1"
	
	var main_scene = preload("res://Scenes/main/main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	
	# Remove this node
	queue_free()


func start_normal_game():
	print("正常游戏模式 - 直接进入Grass Map")
	
	# 设置选中的地图为grass map (map1)
	Globals.selected_map = "map1"
	print("已选择地图: Grass Map")
	
	# 直接加载主游戏场景
	var main_scene = preload("res://Scenes/main/main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	
	# Remove this node
	queue_free()