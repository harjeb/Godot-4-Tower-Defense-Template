extends Node2D

## Error Dialog Test - 测试错误对话框功能

func _ready():
	print("=== 错误对话框测试开始 ===")
	await get_tree().create_timer(1.0).timeout
	
	# 测试不同类型的错误消息
	test_error_dialogs()

func test_error_dialogs():
	# 测试1: 基本错误
	await get_tree().create_timer(0.5).timeout
	ErrorHandler.show_error("这是一个测试错误消息", "测试错误")
	
	# 测试2: 警告消息
	await get_tree().create_timer(3.0).timeout
	ErrorHandler.show_warning("这是一个测试警告消息", "测试警告")
	
	# 测试3: 信息消息
	await get_tree().create_timer(3.0).timeout
	ErrorHandler.show_info("这是一个测试信息消息", "测试信息")
	
	# 测试4: 空值检查
	await get_tree().create_timer(3.0).timeout
	var null_object = null
	ErrorHandler.check_null(null_object, "测试对象")
	
	# 测试5: 文件检查
	await get_tree().create_timer(3.0).timeout
	ErrorHandler.check_file_exists("res://nonexistent_file.txt")
	
	# 测试完成
	await get_tree().create_timer(3.0).timeout
	print("=== 错误对话框测试完成 ===")
	get_tree().quit()