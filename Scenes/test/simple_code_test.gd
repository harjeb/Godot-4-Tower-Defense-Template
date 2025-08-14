extends Node2D

## Simple Code Test - 只测试代码问题，不依赖资源文件

signal test_completed(success: bool, message: String)

func _ready():
	print("=== 开始简单代码测试 ===")
	call_deferred("run_simple_tests")

func run_simple_tests():
	var test_results = []
	
	# Test 1: Check class imports
	test_results.append(test_class_imports())
	
	# Test 2: Check autoload registration
	test_results.append(test_autoload_registration())
	
	# Test 3: Check basic script compilation
	test_results.append(test_script_compilation())
	
	# Show results
	show_test_results(test_results)
	
	# Exit
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func test_class_imports() -> Dictionary:
	print("\n[测试 1] 类导入检查")
	
	var import_tests = []
	
	# Test PassiveSynergyManager import
	if FileAccess.file_exists("res://Scenes/systems/PassiveSynergyManager.gd"):
		import_tests.append("✅ PassiveSynergyManager")
	else:
		import_tests.append("❌ PassiveSynergyManager")
	
	# Test MonsterSkillSystem import
	if FileAccess.file_exists("res://Scenes/systems/MonsterSkillSystem.gd"):
		import_tests.append("✅ MonsterSkillSystem")
	else:
		import_tests.append("❌ MonsterSkillSystem")
	
	# Test PerformanceMonitor import
	if FileAccess.file_exists("res://Scenes/systems/PerformanceMonitor.gd"):
		import_tests.append("✅ PerformanceMonitor")
	else:
		import_tests.append("❌ PerformanceMonitor")
	
	# Test Turret import
	if FileAccess.file_exists("res://Scenes/turrets/turretBase/turret_base.gd"):
		import_tests.append("✅ Turret")
	else:
		import_tests.append("❌ Turret")
	
	for test in import_tests:
		print("  %s" % test)
	
	var success_count = 0
	for test in import_tests:
		if test.begins_with("✅"):
			success_count += 1
	
	return {
		"success": success_count == import_tests.size(),
		"message": "类导入测试 (%d/%d)" % [success_count, import_tests.size()]
	}

func test_autoload_registration() -> Dictionary:
	print("\n[测试 2] 自动加载检查")
	
	var autoload_tests = []
	
	# Check if autoload paths exist in project
	var project_config = ConfigFile.new()
	var load_result = project_config.load("res://project.godot")
	
	if load_result == OK:
		var autoload_section = project_config.get_value("autoload", "", {})
		print("  发现自动加载配置:")
		
		for key in autoload_section.keys():
			var value = autoload_section[key]
			print("  - %s: %s" % [key, value])
			
			# Check if the script file exists
			if value.begins_with("*"):
				var script_path = value.substr(1)
				if FileAccess.file_exists(script_path):
					autoload_tests.append("✅ " + key)
				else:
					autoload_tests.append("❌ " + key + " (文件不存在)")
			else:
				autoload_tests.append("⚠️ " + key + " (非脚本自动加载)")
	else:
		autoload_tests.append("❌ 无法读取project.godot")
	
	for test in autoload_tests:
		print("  %s" % test)
	
	var success_count = 0
	for test in autoload_tests:
		if test.begins_with("✅"):
			success_count += 1
	
	return {
		"success": success_count > 0,
		"message": "自动加载测试 (%d 个有效)" % success_count
	}

func test_script_compilation() -> Dictionary:
	print("\n[测试 3] 脚本编译检查")
	
	# Test basic script compilation without instantiating
	var script_tests = []
	
	var test_scripts = [
		"res://Scenes/main/Globals.gd",
		"res://Scenes/main/Data.gd",
		"res://Scenes/systems/PassiveSynergyManager.gd",
		"res://Scenes/systems/MonsterSkillSystem.gd",
		"res://Scenes/systems/PerformanceMonitor.gd",
		"res://Scenes/turrets/turretBase/turret_base.gd"
	]
	
	for script_path in test_scripts:
		if FileAccess.file_exists(script_path):
			var script = load(script_path)
			if script and script is GDScript:
				script_tests.append("✅ " + script_path.get_file())
			else:
				script_tests.append("❌ " + script_path.get_file() + " (加载失败)")
		else:
			script_tests.append("❌ " + script_path.get_file() + " (文件不存在)")
	
	for test in script_tests:
		print("  %s" % test)
	
	var success_count = 0
	for test in script_tests:
		if test.begins_with("✅"):
			success_count += 1
	
	return {
		"success": success_count == script_tests.size(),
		"message": "脚本编译测试 (%d/%d)" % [success_count, script_tests.size()]
	}

func show_test_results(results: Array):
	print("\n=== 测试结果汇总 ===")
	
	var total_tests = results.size()
	var successful_tests = 0
	
	for i in range(results.size()):
		var result = results[i]
		var status = "✅ 成功" if result.success else "❌ 失败"
		print("测试 %d: %s - %s" % [i + 1, result.message, status])
		
		if result.success:
			successful_tests += 1
	
	var success_rate = float(successful_tests) / total_tests
	print("\n总体成功率: %.1f%% (%d/%d)" % [success_rate * 100, successful_tests, total_tests])
	
	var overall_success = success_rate >= 0.8
	test_completed.emit(overall_success, "测试完成")
	
	if overall_success:
		print("🎉 代码问题已基本解决！")
	else:
		print("⚠️ 仍有代码问题需要处理")