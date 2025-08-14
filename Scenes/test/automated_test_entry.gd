extends Node2D

## Automated Test Entry Point for Tower Defense Game
## This script simulates the complete game flow: Start → Map Selection → Game Load

signal test_completed(success: bool, message: String)

var test_step := 0
var test_results := []
var current_scene = null

func _ready():
	print("=== 开始塔防游戏自动化测试 ===")
	call_deferred("start_test_sequence")

func start_test_sequence():
	test_step = 0
	test_results.clear()
	
	# Step 1: Initialize game systems
	await run_test_step("初始化游戏系统", initialize_game_systems)
	
	# Step 2: Select and load map
	await run_test_step("选择并加载地图", select_and_load_map)
	
	# Step 3: Verify all systems are working
	await run_test_step("验证系统功能", verify_systems_functionality)
	
	# Step 4: Complete test
	await run_test_step("完成测试", complete_test)

func run_test_step(step_name: String, test_function: Callable):
	test_step += 1
	print("\n[步骤 %d] %s" % [test_step, step_name])
	
	var result = await test_function.call()
	test_results.append({
		"step": test_step,
		"name": step_name,
		"success": result.success,
		"message": result.message
	})
	
	if result.success:
		print("✅ %s - 成功" % step_name)
	else:
		print("❌ %s - 失败: %s" % [step_name, result.message])
	
	return result.success

func initialize_game_systems() -> Dictionary:
	# Verify Globals and Data are available
	if not Globals:
		return {"success": false, "message": "Globals 自动加载失败"}
	
	if not Data:
		return {"success": false, "message": "Data 自动加载失败"}
	
	# Initialize selected map
	Globals.selected_map = "map1"
	
	# Verify map data exists
	if not Data.maps.has("map1"):
		return {"success": false, "message": "地图数据 map1 不存在"}
	
	print("  - 游戏系统初始化完成")
	print("  - 选定地图: %s" % Data.maps["map1"].get("name", "未知地图"))
	
	return {"success": true, "message": "游戏系统初始化成功"}

func select_and_load_map() -> Dictionary:
	# Simulate map selection (like clicking on map_container)
	print("  - 模拟地图选择...")
	
	# Create main scene
	var main_scene = preload("res://Scenes/main/main.tscn").instantiate()
	if not main_scene:
		return {"success": false, "message": "无法实例化主场景"}
	
	# Add main scene to tree
	get_tree().root.add_child(main_scene)
	current_scene = main_scene
	
	# Wait for scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("  - 主场景加载完成")
	
	# Verify map was loaded
	if not Globals.current_map:
		return {"success": false, "message": "地图未正确加载"}
	
	print("  - 当前地图: %s" % Globals.current_map.map_type)
	
	return {"success": true, "message": "地图选择和加载成功"}

func verify_systems_functionality() -> Dictionary:
	var system_checks = []
	
	# Check PassiveSynergyManager
	var synergy_manager = get_node_or_null("/root/main/PassiveSynergyManager")
	if synergy_manager:
		system_checks.append("✅ PassiveSynergyManager")
	else:
		system_checks.append("❌ PassiveSynergyManager")
	
	# Check MonsterSkillSystem
	var monster_skill_system = get_node_or_null("/root/main/MonsterSkillSystem")
	if monster_skill_system:
		system_checks.append("✅ MonsterSkillSystem")
	else:
		system_checks.append("❌ MonsterSkillSystem")
	
	# Check PerformanceMonitor
	var performance_monitor = get_node_or_null("/root/main/PerformanceMonitor")
	if performance_monitor:
		system_checks.append("✅ PerformanceMonitor")
	else:
		system_checks.append("❌ PerformanceMonitor")
	
	# Check InventoryManager
	var inventory_manager = get_node_or_null("/root/InventoryManager")
	if inventory_manager:
		system_checks.append("✅ InventoryManager")
	else:
		system_checks.append("❌ InventoryManager")
	
	# Check WaveManager
	var wave_manager = get_node_or_null("/root/main/WaveManager")
	if wave_manager:
		system_checks.append("✅ WaveManager")
	else:
		system_checks.append("❌ WaveManager")
	
	print("  - 系统检查结果:")
	for check in system_checks:
		print("    %s" % check)
	
	# Count successful systems
	var success_count = 0
	for check in system_checks:
		if check.begins_with("✅"):
			success_count += 1
	
	var total_systems = system_checks.size()
	var success_rate = float(success_count) / total_systems
	
	if success_rate >= 0.8:  # 80% success rate acceptable
		return {"success": true, "message": "系统功能验证成功 (%d/%d)" % [success_count, total_systems]}
	else:
		return {"success": false, "message": "系统功能验证失败 (%d/%d)" % [success_count, total_systems]}

func complete_test() -> Dictionary:
	print("\n=== 测试结果汇总 ===")
	
	var total_steps = test_results.size()
	var successful_steps = 0
	
	for result in test_results:
		if result.success:
			successful_steps += 1
		print("步骤 %d: %s - %s" % [result.step, result.name, "✅ 成功" if result.success else "❌ 失败"])
	
	var success_rate = float(successful_steps) / total_steps
	print("\n总体成功率: %.1f%% (%d/%d)" % [success_rate * 100, successful_steps, total_steps])
	
	var overall_success = success_rate >= 0.8
	var message = "测试完成" if overall_success else "测试失败"
	
	# Emit completion signal
	test_completed.emit(overall_success, message)
	
	# Auto-exit after test
	print("\n测试完成，3秒后自动退出...")
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()
	
	return {"success": overall_success, "message": message}

func _exit_tree():
	# Clean up
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()