extends Node
class_name TestRunner

## 自动化测试运行器
## 管理和执行所有测试套件，生成测试报告

signal all_tests_completed(summary: Dictionary)

var test_suites: Array[TestFramework] = []
var total_results: Dictionary = {}
var current_suite_index: int = 0
var is_running: bool = false

func _ready():
	name = "TestRunner"
	print("塔防游戏测试运行器已初始化")

# 注册测试套件
func register_test_suite(suite: TestFramework):
	test_suites.append(suite)
	print("已注册测试套件: %s" % suite.get_script().get_global_name())

# 运行所有测试套件
func run_all_tests() -> Dictionary:
	if is_running:
		print("测试已在运行中...")
		return {}
	
	is_running = true
	total_results.clear()
	current_suite_index = 0
	
	print("\n" + "="*60)
	print("开始运行塔防游戏增强系统测试")
	print("="*60)
	
	var start_time = Time.get_time_dict_from_system()
	
	# 运行所有注册的测试套件
	for suite in test_suites:
		var suite_result = suite.run_all_tests()
		total_results[suite_result.suite_name] = suite_result
	
	var end_time = Time.get_time_dict_from_system()
	var total_duration = _calculate_duration(start_time, end_time)
	
	# 生成总体摘要
	var summary = _generate_summary(total_duration)
	_print_final_report(summary)
	
	is_running = false
	all_tests_completed.emit(summary)
	
	return summary

# 运行单个测试套件
func run_test_suite(suite_name: String) -> Dictionary:
	for suite in test_suites:
		if suite.get_script().get_global_name() == suite_name:
			return suite.run_all_tests()
	
	print("未找到测试套件: %s" % suite_name)
	return {}

# 获取可用的测试套件列表
func get_available_test_suites() -> Array[String]:
	var suite_names: Array[String] = []
	for suite in test_suites:
		suite_names.append(suite.get_script().get_global_name())
	return suite_names

# 生成测试报告文件
func generate_test_report(file_path: String = "test_report.txt") -> bool:
	if total_results.is_empty():
		print("没有测试结果，请先运行测试")
		return false
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("无法创建测试报告文件: %s" % file_path)
		return false
	
	file.store_string(_generate_detailed_report())
	file.close()
	
	print("测试报告已生成: %s" % file_path)
	return true

# 验证所有核心功能
func validate_core_functionality() -> Dictionary:
	print("\n" + "="*50)
	print("验证塔防游戏核心功能")
	print("="*50)
	
	var validation_results = {
		"element_system": false,
		"enemy_abilities": false,
		"gem_system": false,
		"inventory_ui": false,
		"combat_integration": false,
		"overall_status": false
	}
	
	# 运行验证测试
	var element_suite = ElementSystemTests.new()
	var element_result = element_suite.run_all_tests()
	validation_results.element_system = (element_result.failed == 0)
	element_suite.queue_free()
	
	var enemy_suite = EnemyAbilitiesTests.new()
	var enemy_result = enemy_suite.run_all_tests()
	validation_results.enemy_abilities = (enemy_result.failed == 0)
	enemy_suite.queue_free()
	
	var gem_suite = GemSystemTests.new()
	var gem_result = gem_suite.run_all_tests()
	validation_results.gem_system = (gem_result.failed == 0)
	gem_suite.queue_free()
	
	var inventory_suite = InventoryUISystemTests.new()
	var inventory_result = inventory_suite.run_all_tests()
	validation_results.inventory_ui = (inventory_result.failed == 0)
	inventory_suite.queue_free()
	
	var combat_suite = CombatIntegrationTests.new()
	var combat_result = combat_suite.run_all_tests()
	validation_results.combat_integration = (combat_result.failed == 0)
	combat_suite.queue_free()
	
	# 判断整体状态
	validation_results.overall_status = (
		validation_results.element_system and
		validation_results.enemy_abilities and
		validation_results.gem_system and
		validation_results.inventory_ui and
		validation_results.combat_integration
	)
	
	_print_validation_results(validation_results)
	
	return validation_results

# 私有方法
func _calculate_duration(start_time: Dictionary, end_time: Dictionary) -> float:
	var start_ms = start_time.hour * 3600000 + start_time.minute * 60000 + start_time.second * 1000
	var end_ms = end_time.hour * 3600000 + end_time.minute * 60000 + end_time.second * 1000
	return float(end_ms - start_ms)

func _generate_summary(total_duration: float) -> Dictionary:
	var total_tests = 0
	var total_passed = 0
	var total_failed = 0
	var suite_count = total_results.size()
	
	for suite_name in total_results.keys():
		var result = total_results[suite_name]
		total_tests += result.total_tests
		total_passed += result.passed
		total_failed += result.failed
	
	return {
		"total_suites": suite_count,
		"total_tests": total_tests,
		"total_passed": total_passed,
		"total_failed": total_failed,
		"success_rate": float(total_passed) / total_tests * 100.0 if total_tests > 0 else 0.0,
		"total_duration": total_duration,
		"suite_results": total_results
	}

func _print_final_report(summary: Dictionary):
	print("\n" + "="*60)
	print("塔防游戏测试总体报告")
	print("="*60)
	print("测试套件数量: %d" % summary.total_suites)
	print("测试用例总数: %d" % summary.total_tests)
	print("通过测试: %d" % summary.total_passed)
	print("失败测试: %d" % summary.total_failed)
	print("成功率: %.1f%%" % summary.success_rate)
	print("总耗时: %.2fms" % summary.total_duration)
	
	if summary.total_failed == 0:
		print("\n🎉 所有测试通过！塔防游戏增强系统功能正常！")
	else:
		print("\n⚠️  有 %d 个测试失败，请检查相关功能实现" % summary.total_failed)
	
	print("="*60 + "\n")

func _generate_detailed_report() -> String:
	var report = "塔防游戏增强系统测试报告\n"
	report += "生成时间: " + Time.get_datetime_string_from_system() + "\n\n"
	
	var summary = _generate_summary(0.0)  # Duration already calculated
	
	report += "=== 总体摘要 ===\n"
	report += "测试套件数量: %d\n" % summary.total_suites
	report += "测试用例总数: %d\n" % summary.total_tests
	report += "通过测试: %d\n" % summary.total_passed
	report += "失败测试: %d\n" % summary.total_failed
	report += "成功率: %.1f%%\n" % summary.success_rate
	report += "总耗时: %.2fms\n\n" % summary.total_duration
	
	report += "=== 详细结果 ===\n"
	for suite_name in total_results.keys():
		var result = total_results[suite_name]
		report += "\n【%s】\n" % suite_name
		report += "测试数量: %d\n" % result.total_tests
		report += "通过: %d\n" % result.passed
		report += "失败: %d\n" % result.failed
		report += "耗时: %.2fms\n" % result.total_duration
		
		if result.failed > 0:
			report += "失败的测试:\n"
			for test_name in result.test_results.keys():
				var test_result = result.test_results[test_name]
				if not test_result.passed:
					report += "  - %s: %s\n" % [test_name, test_result.message]
	
	return report

func _print_validation_results(results: Dictionary):
	print("\n=== 核心功能验证结果 ===")
	print("元素系统: %s" % ("✓ 通过" if results.element_system else "✗ 失败"))
	print("敌人特殊能力: %s" % ("✓ 通过" if results.enemy_abilities else "✗ 失败"))
	print("宝石系统: %s" % ("✓ 通过" if results.gem_system else "✗ 失败"))
	print("背包UI系统: %s" % ("✓ 通过" if results.inventory_ui else "✗ 失败"))
	print("战斗集成: %s" % ("✓ 通过" if results.combat_integration else "✗ 失败"))
	print("整体状态: %s" % ("✅ 系统正常" if results.overall_status else "❌ 存在问题"))
	print("========================\n")

# 静态方法：快速运行所有测试
static func run_quick_validation() -> bool:
	var runner = TestRunner.new()
	
	# 注册所有测试套件
	runner.register_test_suite(ElementSystemTests.new())
	runner.register_test_suite(EnemyAbilitiesTests.new())
	runner.register_test_suite(GemSystemTests.new())
	runner.register_test_suite(InventoryUISystemTests.new())
	runner.register_test_suite(CombatIntegrationTests.new())
	
	var summary = runner.run_all_tests()
	var success = summary.total_failed == 0
	
	runner.queue_free()
	return success