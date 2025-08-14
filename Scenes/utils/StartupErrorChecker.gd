extends Node

## Startup Error Checker
## 在游戏启动前检查常见的编译时错误

const ERROR_DIALOG_PATH = "res://Scenes/ui/ErrorDialog.gd"
const ERROR_UI_PATH = "res://Scenes/ui/ErrorDialogUI.gd"

func _ready():
	# 延迟一帧确保所有资源加载完成
	call_deferred("check_startup_errors")

func check_startup_errors():
	"""检查启动时的编译时错误"""
	print("正在检查启动时错误...")
	
	var errors_found = []
	
	# 检查ErrorDialog脚本
	if check_error_dialog_script(errors_found):
		print("✅ ErrorDialog脚本检查通过")
	
	# 检查其他关键脚本
	if check_other_critical_scripts(errors_found):
		print("✅ 其他关键脚本检查通过")
	
	# 如果发现错误，显示错误信息
	if not errors_found.is_empty():
		show_startup_errors(errors_found)
	else:
		print("✅ 所有启动检查通过")

func check_error_dialog_script(errors_found: Array) -> bool:
	"""检查ErrorDialog脚本是否有编译错误"""
	if not FileAccess.file_exists(ERROR_DIALOG_PATH):
		errors_found.append("ErrorDialog脚本文件不存在: " + ERROR_DIALOG_PATH)
		return false
	
	# 读取脚本内容
	var file = FileAccess.open(ERROR_DIALOG_PATH, FileAccess.READ)
	if not file:
		errors_found.append("无法读取ErrorDialog脚本: " + ERROR_DIALOG_PATH)
		return false
	
	var script_content = file.get_as_text()
	file.close()
	
	# 检查是否有is_visible()方法重写
	if script_content.contains("func is_visible()"):
		errors_found.append("ErrorDialog.gd 包含重写的is_visible()方法，这会导致编译错误")
		return false
	
	# 检查语法错误（简单检查）
	if script_content.contains("extends ") and not script_content.contains("extends Control"):
		errors_found.append("ErrorDialog.gd 继承类型可能不正确")
		return false
	
	return true

func check_other_critical_scripts(errors_found: Array) -> bool:
	"""检查其他关键脚本"""
	var critical_scripts = [
		"res://Scenes/main/Globals.gd",
		"res://Scenes/utils/ErrorHandler.gd",
		"res://Scenes/systems/PerformanceMonitor.gd"
	]
	
	var all_ok = true
	
	for script_path in critical_scripts:
		if not FileAccess.file_exists(script_path):
			errors_found.append("关键脚本文件不存在: " + script_path)
			all_ok = false
			continue
		
		# 检查文件大小
		var file = FileAccess.open(script_path, FileAccess.READ)
		if not file:
			errors_found.append("无法读取脚本文件: " + script_path)
			all_ok = false
			continue
		
		var content = file.get_as_text()
		file.close()
		
		# 检查基本语法
		if content.length() < 10:
			errors_found.append("脚本文件可能为空: " + script_path)
			all_ok = false
	
	return all_ok

func show_startup_errors(errors: Array):
	"""显示启动时错误"""
	print("=== 启动时错误检查发现以下问题 ===")
	for error in errors:
		print("❌ " + error)
	print("=======================================")
	
	# 尝试显示错误对话框
	call_deferred("show_error_dialog_safe", errors)

func show_error_dialog_safe(errors: Array):
	"""安全地显示错误对话框"""
	var error_message = "启动时检查发现以下问题：\n\n"
	for i in range(errors.size()):
		error_message += str(i + 1) + ". " + errors[i] + "\n"
	
	error_message += "\n请修复这些问题后重新启动游戏。"
	
	# 尝试通过Globals显示错误
	if has_node("/root/Globals") and get_node("/root/Globals").has_method("show_error_dialog"):
		get_node("/root/Globals").show_error_dialog(error_message, "启动错误")
	else:
		# 回退到控制台输出
		print(error_message)
		# 显示OS级别的错误对话框
		OS.alert(error_message, "启动错误")

func check_file_syntax(file_path: String) -> bool:
	"""检查文件语法（简化版）"""
	if not FileAccess.file_exists(file_path):
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	# 基本语法检查
	var lines = content.split("\n")
	for line_num in range(lines.size()):
		var line = lines[line_num].strip_edges()
		
		# 检查未闭合的括号
		if line.count("(") != line.count(")"):
			print("语法警告: %s:%d 括号不匹配" % [file_path.get_file(), line_num + 1])
		
		# 检查未闭合的引号
		if line.count("\"") % 2 != 0:
			print("语法警告: %s:%d 引号不匹配" % [file_path.get_file(), line_num + 1])
	
	return true

func get_project_startup_errors() -> Array:
	"""获取项目启动时的所有错误"""
	var errors = []
	
	# 检查关键文件
	var key_files = [
		"res://project.godot",
		"res://Scenes/main/Globals.gd",
		"res://Scenes/utils/ErrorHandler.gd",
		"res://Scenes/ui/ErrorDialog.gd",
		"res://Scenes/boot/boot.gd"
	]
	
	for file_path in key_files:
		if not FileAccess.file_exists(file_path):
			errors.append("关键文件缺失: " + file_path)
		elif not check_file_syntax(file_path):
			errors.append("文件语法错误: " + file_path)
	
	return errors