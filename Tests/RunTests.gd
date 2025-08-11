@tool
extends SceneTree

## 测试执行器
## 可以从命令行或代码直接运行所有测试的工具

func _init():
	print("塔防游戏增强系统测试执行器")
	print("==================================================")  # 替换字符串重复操作符
	
	# 运行所有测试
	run_complete_test_suite()
	
	# 等待一帧确保所有输出完成
	await process_frame
	
	# 退出
	quit()

func run_complete_test_suite():
	print("开始运行完整测试套件...\n")
	
	var start_time = Time.get_time_dict_from_system()
	var overall_success = true
	var detailed_results = {}
	
	# 1. 运行元素系统测试
	print(">>> 运行元素系统测试")
	var element_suite = ElementSystemTests.new()
	var element_result = element_suite.run_all_tests()
	detailed_results["ElementSystem"] = element_result
	if element_result.failed > 0:
		overall_success = false
	element_suite.queue_free()
	
	# 2. 运行敌人能力测试
	print("\n>>> 运行敌人特殊能力测试")
	var enemy_suite = EnemyAbilitiesTests.new()
	var enemy_result = enemy_suite.run_all_tests()
	detailed_results["EnemyAbilities"] = enemy_result
	if enemy_result.failed > 0:
		overall_success = false
	enemy_suite.queue_free()
	
	# 3. 运行宝石系统测试
	print("\n>>> 运行宝石系统测试")
	var gem_suite = GemSystemTests.new()
	var gem_result = gem_suite.run_all_tests()
	detailed_results["GemSystem"] = gem_result
	if gem_result.failed > 0:
		overall_success = false
	gem_suite.queue_free()
	
	# 4. 运行背包UI系统测试
	print("\n>>> 运行背包UI系统测试")
	var inventory_suite = InventoryUISystemTests.new()
	var inventory_result = inventory_suite.run_all_tests()
	detailed_results["InventoryUI"] = inventory_result
	if inventory_result.failed > 0:
		overall_success = false
	inventory_suite.queue_free()
	
	# 5. 运行战斗集成测试
	print("\n>>> 运行战斗集成测试")
	var combat_suite = CombatIntegrationTests.new()
	var combat_result = combat_suite.run_all_tests()
	detailed_results["CombatIntegration"] = combat_result
	if combat_result.failed > 0:
		overall_success = false
	combat_suite.queue_free()
	
	var end_time = Time.get_time_dict_from_system()
	var total_duration = _calculate_duration(start_time, end_time)
	
	# 生成最终报告
	_generate_final_report(detailed_results, total_duration, overall_success)

func _generate_final_report(results: Dictionary, duration: float, success: bool):
	var total_tests = 0
	var total_passed = 0
	var total_failed = 0
	
	print("\n" + "="*70)
	print("塔防游戏增强系统 - 完整测试报告")
	print("="*70)
	
	for suite_name in results.keys():
		var result = results[suite_name]
		total_tests += result.total_tests
		total_passed += result.passed
		total_failed += result.failed
		
		print("\n【%s】" % suite_name)
		print("  测试数量: %d" % result.total_tests)
		print("  通过: %d" % result.passed)
		print("  失败: %d" % result.failed)
		print("  成功率: %.1f%%" % (float(result.passed) / result.total_tests * 100))
		print("  耗时: %.2fms" % result.total_duration)
		
		if result.failed > 0:
			print("  失败的测试:")
			for test_name in result.test_results.keys():
				var test_result = result.test_results[test_name]
				if not test_result.passed:
					print("    - %s" % test_name)
	
	print("\n" + "="*70)
	print("总体统计:")
	print("  测试套件: %d" % results.size())
	print("  测试总数: %d" % total_tests)
	print("  通过: %d" % total_passed)
	print("  失败: %d" % total_failed)
	print("  成功率: %.1f%%" % (float(total_passed) / total_tests * 100 if total_tests > 0 else 0))
	print("  总耗时: %.2fms" % duration)
	
	if success:
		print("\n🎉 所有测试通过！塔防游戏增强系统功能完整且正确！")
	else:
		print("\n❌ 存在失败的测试，请检查并修复相关功能")
	
	print("="*70)
	
	# 生成文件报告
	_save_report_to_file(results, duration, success)

func _save_report_to_file(results: Dictionary, duration: float, success: bool):
	var file_path = "user://test_execution_report.txt"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		print("警告: 无法创建测试报告文件")
		return
	
	file.store_string("塔防游戏增强系统测试报告\n")
	file.store_string("执行时间: %s\n\n" % Time.get_datetime_string_from_system())
	
	var total_tests = 0
	var total_passed = 0
	var total_failed = 0
	
	for suite_name in results.keys():
		var result = results[suite_name]
		total_tests += result.total_tests
		total_passed += result.passed
		total_failed += result.failed
		
		file.store_string("=== %s ===\n" % suite_name)
		file.store_string("测试数量: %d\n" % result.total_tests)
		file.store_string("通过: %d\n" % result.passed)
		file.store_string("失败: %d\n" % result.failed)
		file.store_string("成功率: %.1f%%\n" % (float(result.passed) / result.total_tests * 100))
		file.store_string("耗时: %.2fms\n" % result.total_duration)
		
		if result.failed > 0:
			file.store_string("\n失败的测试:\n")
			for test_name in result.test_results.keys():
				var test_result = result.test_results[test_name]
				if not test_result.passed:
					file.store_string("- %s: %s\n" % [test_name, test_result.message])
		
		file.store_string("\n")
	
	file.store_string("=== 总体统计 ===\n")
	file.store_string("测试套件: %d\n" % results.size())
	file.store_string("测试总数: %d\n" % total_tests)
	file.store_string("通过: %d\n" % total_passed)
	file.store_string("失败: %d\n" % total_failed)
	file.store_string("成功率: %.1f%%\n" % (float(total_passed) / total_tests * 100 if total_tests > 0 else 0))
	file.store_string("总耗时: %.2fms\n" % duration)
	file.store_string("整体状态: %s\n" % ("通过" if success else "失败"))
	
	file.close()
	print("\n详细测试报告已保存至: %s" % file_path)

func _calculate_duration(start_time: Dictionary, end_time: Dictionary) -> float:
	var start_ms = start_time.hour * 3600000 + start_time.minute * 60000 + start_time.second * 1000
	var end_ms = end_time.hour * 3600000 + end_time.minute * 60000 + end_time.second * 1000
	return float(end_ms - start_ms)

# 静态方法：快速验证所有功能
static func quick_validation() -> bool:
	print("快速验证塔防游戏增强系统...")
	
	var success = true
	var failures = []
	
	# 元素系统快速检查
	var fire_vs_wind = ElementSystem.get_effectiveness_multiplier("fire", "wind")
	if not _approximately_equal(fire_vs_wind, 1.5):
		success = false
		failures.append("火克制风的伤害倍率不正确")
	
	var light_vs_dark = ElementSystem.get_effectiveness_multiplier("light", "dark")
	if not _approximately_equal(light_vs_dark, 1.5):
		success = false
		failures.append("光克制暗的伤害倍率不正确")
	
	# 数据完整性检查
	if Data.gems.size() != 21:
		success = false
		failures.append("宝石数据不完整，期望21种，实际%d种" % Data.gems.size())
	
	var expected_elements = ["fire", "ice", "wind", "earth", "light", "dark", "neutral"]
	for element in expected_elements:
		if not element in Data.elements:
			success = false
			failures.append("缺少元素定义: %s" % element)
	
	# 输出结果
	if success:
		print("✅ 快速验证通过！")
	else:
		print("❌ 快速验证失败:")
		for failure in failures:
			print("  - %s" % failure)
	
	return success

static func _approximately_equal(a: float, b: float, tolerance: float = 0.001) -> bool:
	return abs(a - b) <= tolerance

# 在Godot编辑器中运行的工具函数
static func run_from_editor():
	if not Engine.is_editor_hint():
		return
	
	print("从编辑器运行测试...")
	
	# 创建测试执行器实例
	var executor = TestExecutor.new()
	# 注意：在编辑器中运行时需要特殊处理