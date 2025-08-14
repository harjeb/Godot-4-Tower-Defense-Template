extends Node

## Error Handler Utility
## 统一错误处理，防止debug日志刷屏

## 全局错误处理函数
## 替换 push_error 和 print 错误输出

## 错误次数统计，防止弹框刷屏
var error_counts = {}
var max_error_shown = 3
var error_cooldown = 5.0  # 5秒冷却时间

## 编译时错误检测
var known_compilation_errors = {
	"is_visible()": "ErrorDialog.gd 中的 is_visible() 方法重写了父类方法",
	"overrides a method": "方法重写错误，请检查脚本中是否有重写父类方法的情况",
	"Parser Error": "语法解析错误，请检查脚本语法"
}

func show_error(message: String, title: String = "错误") -> void:
	"""显示错误对话框（带防刷屏机制）"""
	var error_key = message.hash()
	var time_dict = Time.get_time_dict_from_system()
	var current_time = float(time_dict.get("unix", Time.get_ticks_msec() / 1000.0))
	
	# 检查错误是否已经显示过多次
	if error_key in error_counts:
		var error_info = error_counts[error_key]
		if error_info.count >= max_error_shown:
			if current_time - error_info.last_time < error_cooldown:
				# 错误显示太频繁，只打印到控制台
				print("错误(已屏蔽): ", message)
				return
			else:
				# 冷却时间已过，重置计数
				error_info.count = 0
	
	# 更新错误计数
	if error_key not in error_counts:
		error_counts[error_key] = {"count": 0, "last_time": current_time}
	
	error_counts[error_key].count += 1
	error_counts[error_key].last_time = current_time
	
	# 显示错误对话框
	if has_node("/root/Globals") and get_node("/root/Globals").has_method("show_error_dialog"):
		get_node("/root/Globals").show_error_dialog(message, title)
	else:
		# 回退到控制台输出
		print("错误: ", message)

func show_warning(message: String, title: String = "警告") -> void:
	"""显示警告对话框"""
	if has_node("/root/Globals") and get_node("/root/Globals").has_method("show_error_dialog"):
		get_node("/root/Globals").show_error_dialog(message, title)
	else:
		# 回退到控制台输出
		print("警告: ", message)

func show_info(message: String, title: String = "信息") -> void:
	"""显示信息对话框"""
	if has_node("/root/Globals") and get_node("/root/Globals").has_method("show_error_dialog"):
		get_node("/root/Globals").show_error_dialog(message, title)
	else:
		# 回退到控制台输出
		print("信息: ", message)

## 安全的错误处理，用于替换 push_error
func safe_error(message: String) -> void:
	"""安全的错误输出，不会造成日志刷屏"""
	show_error(message)

## 安全的警告处理
func safe_warning(message: String) -> void:
	"""安全的警告输出"""
	show_warning(message)

## 错误检查助手
func check_null(object: Object, object_name: String) -> bool:
	"""检查对象是否为null"""
	if not is_instance_valid(object):
		safe_error("%s 为空或无效" % object_name)
		return false
	return true

func check_file_exists(file_path: String) -> bool:
	"""检查文件是否存在"""
	if not FileAccess.file_exists(file_path):
		safe_error("文件不存在: %s" % file_path)
		return false
	return true

func check_node_exists(node_path: String) -> bool:
	"""检查节点是否存在"""
	# 需要在特定的节点上下文中调用
	var current_scene = get_tree().current_scene if get_tree() else null
	if not current_scene:
		safe_error("无法检查节点 - 没有当前场景")
		return false
	
	var node = current_scene.get_node_or_null(node_path)
	if not node:
		safe_error("节点不存在: %s" % node_path)
		return false
	return true

## 错误恢复助手
func safe_call(object: Object, method_name: String, args: Array = []) -> Variant:
	"""安全调用对象方法"""
	if not check_null(object, "对象"):
		return null
	
	if not object.has_method(method_name):
		safe_error("对象没有方法: %s" % method_name)
		return null
	
	return object.callv(method_name, args)

func safe_load_resource(resource_path: String, type_hint: String = "") -> Variant:
	"""安全加载资源"""
	if not check_file_exists(resource_path):
		return null
	
	var resource = load(resource_path)
	if not resource:
		safe_error("无法加载资源: %s" % resource_path)
		return null
	
	if type_hint != "" and not ClassDB.is_parent_class(resource.get_class(), type_hint):
		safe_error("资源类型不匹配: %s (期望: %s)" % [resource_path, type_hint])
		return null
	
	return resource

## 游戏特定错误处理
func handle_missing_system(system_name: String, node: Node = null) -> void:
	"""处理缺失的系统"""
	var message = "系统 '%s' 未找到，相关功能将不可用" % system_name
	safe_error(message)

func handle_missing_node(node_path: String, context: String = "") -> void:
	"""处理缺失的节点"""
	var message = "节点 '%s' 未找到" % node_path
	if context != "":
		message += " (上下文: %s)" % context
	safe_error(message)

func handle_resource_load_error(resource_path: String, resource_type: String = "") -> void:
	"""处理资源加载错误"""
	var message = "无法加载资源: %s" % resource_path
	if resource_type != "":
		message += " (类型: %s)" % resource_type
	safe_error(message)

func handle_script_error(script_path: String, error_message: String) -> void:
	"""处理脚本错误"""
	var message = "脚本错误 '%s': %s" % [script_path, error_message]
	safe_error(message)

## 自动错误监控
func monitor_node_for_errors(node: Node) -> void:
	"""监控节点的错误"""
	if not node:
		return
	
	# 监控常见的错误情况
	if node.has_signal("script_changed"):
		node.script_changed.connect(_on_node_script_changed.bind(node))
	
	# 添加到监控列表
	if not has_meta("monitored_nodes"):
		set_meta("monitored_nodes", [])
	
	var monitored_nodes = get_meta("monitored_nodes")
	if not monitored_nodes.has(node):
		monitored_nodes.append(node)

func _on_node_script_changed(node: Node):
	"""节点脚本改变时的处理"""
	if node and node.get_script():
		var script_path = node.get_script().resource_path
		print("节点脚本已改变: %s" % script_path)

## 全局编译时错误拦截
func intercept_compilation_errors():
	"""拦截编译时错误"""
	# 设置全局错误处理器
	if Engine.has_singleton("Engine"):
		# 尝试设置自定义错误处理
		print("全局编译时错误拦截器已启动")
		
		# 检查常见的编译时错误
		check_common_compilation_errors()

func check_common_compilation_errors():
	"""检查常见的编译时错误"""
	var errors_found = []
	
	# 检查ErrorDialog.gd中的is_visible()问题
	var error_dialog_path = "res://Scenes/ui/ErrorDialog.gd"
	if FileAccess.file_exists(error_dialog_path):
		var file = FileAccess.open(error_dialog_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			if "func is_visible()" in content:
				errors_found.append("检测到 ErrorDialog.gd 中的 is_visible() 方法重写问题")
				# 尝试自动修复
				attempt_auto_fix_error_dialog()
	
	# 显示发现的错误
	if not errors_found.is_empty():
		for error in errors_found:
			safe_error(error)

func attempt_auto_fix_error_dialog():
	"""尝试自动修复ErrorDialog中的问题"""
	var error_dialog_path = "res://Scenes/ui/ErrorDialog.gd"
	if not FileAccess.file_exists(error_dialog_path):
		return
	
	var file = FileAccess.open(error_dialog_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	# 检查是否需要修复
	if "func is_visible()" in content:
		var fixed_content = content.replace("func is_visible()", "func is_dialog_visible()")
		
		# 写入修复后的内容
		var write_file = FileAccess.open(error_dialog_path, FileAccess.WRITE)
		if write_file:
			write_file.store_string(fixed_content)
			write_file.close()
			show_info("已自动修复 ErrorDialog.gd 中的 is_visible() 方法问题")
		else:
			safe_error("无法自动修复 ErrorDialog.gd，请手动修复")

## 设置全局错误监控
func setup_global_error_monitoring():
	"""设置全局错误监控"""
	print("设置全局错误监控...")
	
	# 尝试连接引擎错误信号（如果可用）
	# 注意：Godot 4.4 中可能没有这些信号
	if Engine.has_method("connect") and Engine.has_signal("script_error"):
		Engine.connect("script_error", _on_engine_script_error)
	
	# 启动编译时错误检查
	call_deferred("intercept_compilation_errors")

func _on_engine_script_error(script_path: String, error_message: String, line: int):
	"""处理引擎脚本错误"""
	var full_error = "脚本错误: %s\n位置: %s:%d\n错误: %s" % [script_path.get_file(), script_path, line, error_message]
	
	# 检查是否是已知的编译时错误
	for error_pattern in known_compilation_errors:
		if error_message.contains(error_pattern):
			full_error += "\n\n这是已知的编译时错误: " + known_compilation_errors[error_pattern]
			break
	
	show_error(full_error, "脚本错误")

## 脚本预加载检查
func preload_script_check(script_path: String) -> bool:
	"""预加载检查脚本是否有错误"""
	if not FileAccess.file_exists(script_path):
		safe_error("脚本文件不存在: " + script_path)
		return false
	
	# 尝试加载脚本
	var script = ResourceLoader.load(script_path)
	if not script:
		safe_error("无法加载脚本: " + script_path)
		return false
	
	return true

## 项目启动前的全面检查
func perform_startup_checks():
	"""执行启动前的全面检查"""
	print("执行启动前错误检查...")
	
	var checks_passed = 0
	var total_checks = 0
	
	# 检查关键文件
	total_checks += 1
	if check_critical_files():
		checks_passed += 1
	
	# 检查脚本语法
	total_checks += 1
	if check_script_syntax():
		checks_passed += 1
	
	# 检查场景文件
	total_checks += 1
	if check_scene_files():
		checks_passed += 1
	
	var result = "启动检查完成: %d/%d 通过" % [checks_passed, total_checks]
	if checks_passed == total_checks:
		show_info(result)
	else:
		safe_warning(result)
	
	return checks_passed == total_checks

func check_critical_files() -> bool:
	"""检查关键文件"""
	var critical_files = [
		"res://project.godot",
		"res://Scenes/main/Globals.gd",
		"res://Scenes/utils/ErrorHandler.gd",
		"res://Scenes/ui/ErrorDialog.gd"
	]
	
	for file_path in critical_files:
		if not FileAccess.file_exists(file_path):
			safe_error("关键文件缺失: " + file_path)
			return false
	
	return true

func check_script_syntax() -> bool:
	"""检查脚本语法"""
	var script_files = [
		"res://Scenes/main/Globals.gd",
		"res://Scenes/utils/ErrorHandler.gd",
		"res://Scenes/ui/ErrorDialog.gd"
	]
	
	for script_path in script_files:
		if not preload_script_check(script_path):
			return false
	
	return true

func check_scene_files() -> bool:
	"""检查场景文件"""
	var scene_files = [
		"res://Scenes/boot/boot.tscn",
		"res://Scenes/main/main.tscn"
	]
	
	for scene_path in scene_files:
		if not FileAccess.file_exists(scene_path):
			safe_error("场景文件缺失: " + scene_path)
			return false
	
	return true