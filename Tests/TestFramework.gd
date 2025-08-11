extends Node
class_name TestFramework

## 塔防游戏测试框架
## 提供单元测试、集成测试和验收测试的基础设施

signal test_started(test_name: String)
signal test_completed(test_name: String, passed: bool, message: String)
signal all_tests_completed(results: Dictionary)

var test_results: Dictionary = {}
var current_test_name: String = ""
var test_count: int = 0
var passed_count: int = 0
var failed_count: int = 0

# 断言方法
func assert_equal(actual, expected, message: String = ""):
	var test_message = message if message != "" else "Expected %s, got %s" % [expected, actual]
	if actual == expected:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_not_equal(actual, expected, message: String = ""):
	var test_message = message if message != "" else "Expected not %s, got %s" % [expected, actual]
	if actual != expected:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_true(condition: bool, message: String = ""):
	var test_message = message if message != "" else "Expected true, got false"
	if condition:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_false(condition: bool, message: String = ""):
	var test_message = message if message != "" else "Expected false, got true"
	if not condition:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_null(value, message: String = ""):
	var test_message = message if message != "" else "Expected null, got %s" % [value]
	if value == null:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_not_null(value, message: String = ""):
	var test_message = message if message != "" else "Expected not null, got null"
	if value != null:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_approximately(actual: float, expected: float, tolerance: float = 0.001, message: String = ""):
	var test_message = message if message != "" else "Expected approximately %s, got %s (tolerance: %s)" % [expected, actual, tolerance]
	if abs(actual - expected) <= tolerance:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_in_range(value: float, min_val: float, max_val: float, message: String = ""):
	var test_message = message if message != "" else "Expected %s to be between %s and %s" % [value, min_val, max_val]
	if value >= min_val and value <= max_val:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_has_key(dict: Dictionary, key: String, message: String = ""):
	var test_message = message if message != "" else "Expected dictionary to have key '%s'" % [key]
	if dict.has(key):
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

func assert_array_size(array: Array, expected_size: int, message: String = ""):
	var test_message = message if message != "" else "Expected array size %s, got %s" % [expected_size, array.size()]
	if array.size() == expected_size:
		_log_pass(test_message)
		return true
	else:
		_log_fail(test_message)
		return false

# 测试运行方法
func run_test(test_name: String, test_func: Callable) -> bool:
	current_test_name = test_name
	test_count += 1
	
	test_started.emit(test_name)
	print("[TEST START] %s" % test_name)
	
	var start_time = Time.get_time_dict_from_system()
	var success = true
	var error_message = ""
	
	try:
		test_func.call()
	except:
		success = false
		error_message = "Test threw an exception"
		_log_fail(error_message)
	
	var end_time = Time.get_time_dict_from_system()
	var duration = _calculate_duration(start_time, end_time)
	
	if success:
		passed_count += 1
		print("[TEST PASS] %s (%.2fms)" % [test_name, duration])
	else:
		failed_count += 1
		print("[TEST FAIL] %s (%.2fms): %s" % [test_name, duration, error_message])
	
	test_results[test_name] = {
		"passed": success,
		"duration": duration,
		"message": error_message
	}
	
	test_completed.emit(test_name, success, error_message)
	current_test_name = ""
	
	return success

func run_test_suite(test_suite_name: String, tests: Array) -> Dictionary:
	print("\n=== RUNNING TEST SUITE: %s ===" % test_suite_name)
	test_results.clear()
	test_count = 0
	passed_count = 0
	failed_count = 0
	
	var start_time = Time.get_time_dict_from_system()
	
	for test in tests:
		if test is Dictionary and test.has("name") and test.has("func"):
			run_test(test.name, test.func)
		else:
			print("[ERROR] Invalid test format: %s" % test)
	
	var end_time = Time.get_time_dict_from_system()
	var total_duration = _calculate_duration(start_time, end_time)
	
	var results = {
		"suite_name": test_suite_name,
		"total_tests": test_count,
		"passed": passed_count,
		"failed": failed_count,
		"total_duration": total_duration,
		"test_results": test_results.duplicate()
	}
	
	_print_summary(results)
	all_tests_completed.emit(results)
	
	return results

# 私有方法
func _log_pass(message: String):
	print("  ✓ %s" % message)

func _log_fail(message: String):
	print("  ✗ %s" % message)

func _calculate_duration(start_time: Dictionary, end_time: Dictionary) -> float:
	var start_ms = start_time.hour * 3600000 + start_time.minute * 60000 + start_time.second * 1000
	var end_ms = end_time.hour * 3600000 + end_time.minute * 60000 + end_time.second * 1000
	return float(end_ms - start_ms)

func _print_summary(results: Dictionary):
	print("\n=== TEST SUITE SUMMARY ===")
	print("Suite: %s" % results.suite_name)
	print("Total Tests: %d" % results.total_tests)
	print("Passed: %d" % results.passed)
	print("Failed: %d" % results.failed)
	print("Success Rate: %.1f%%" % (float(results.passed) / results.total_tests * 100))
	print("Duration: %.2fms" % results.total_duration)
	print("===========================\n")

# 测试数据生成工具
func create_mock_enemy_data(element: String = "neutral", abilities: Array = []) -> Dictionary:
	return {
		"stats": {
			"hp": 100.0,
			"speed": 1.0,
			"baseDamage": 10.0,
			"goldYield": 15.0
		},
		"element": element,
		"special_abilities": abilities,
		"drop_table": {
			"base_chance": 0.1,
			"items": ["fire_basic", "ice_basic"]
		}
	}

func create_mock_gem_data(element: String, level: int) -> Dictionary:
	var level_names = ["", "basic", "intermediate", "advanced"]
	var damage_bonuses = [0.0, 0.10, 0.20, 0.35]
	
	return {
		"name": "%s %s宝石" % [element, level_names[level] if level < level_names.size() else "unknown"],
		"element": element,
		"level": level,
		"damage_bonus": damage_bonuses[level] if level < damage_bonuses.size() else 0.0,
		"sprite": "res://Assets/gems/%s_%s.png" % [element, level_names[level] if level < level_names.size() else "unknown"]
	}

func create_mock_turret_data(turret_type: String, element: String = "neutral") -> Dictionary:
	return {
		"stats": {
			"damage": 10.0,
			"attack_speed": 1.0,
			"attack_range": 200.0
		},
		"element": element,
		"turret_category": "projectile",
		"gem_slot": null
	}

# 性能测试工具
func benchmark_function(func_name: String, func: Callable, iterations: int = 1000) -> Dictionary:
	print("[BENCHMARK] Running %s for %d iterations..." % [func_name, iterations])
	
	var start_time = Time.get_time_dict_from_system()
	
	for i in range(iterations):
		func.call()
	
	var end_time = Time.get_time_dict_from_system()
	var total_duration = _calculate_duration(start_time, end_time)
	var avg_duration = total_duration / iterations
	
	var result = {
		"function_name": func_name,
		"iterations": iterations,
		"total_duration": total_duration,
		"average_duration": avg_duration
	}
	
	print("[BENCHMARK] %s: %.4fms average (%.2fms total)" % [func_name, avg_duration, total_duration])
	
	return result