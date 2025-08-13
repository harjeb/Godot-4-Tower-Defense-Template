extends TestFramework
class_name GemEffectSystemOptimizationTest

## 宝石效果系统优化测试
## 验证新实现的性能优化和错误处理功能

func run_all_tests() -> Dictionary:
	var tests = [
		{"name": "test_effect_pool_performance", "func": test_effect_pool_performance},
		{"name": "test_enemy_cache_efficiency", "func": test_enemy_cache_efficiency},
		{"name": "test_memory_monitoring", "func": test_memory_monitoring},
		{"name": "test_error_logging", "func": test_error_logging},
		{"name": "test_performance_monitoring", "func": test_performance_monitoring},
		{"name": "test_optimization_suggestions", "func": test_optimization_suggestions}
	]
	
	return run_test_suite("GemEffectSystem Optimization Tests", tests)

# 测试效果池性能
func test_effect_pool_performance():
	var gem_effect_system = GemEffectSystem.new()
	add_child(gem_effect_system)
	
	# 测试大量效果创建和回收
	var start_time = Time.get_time_dict_from_system()
	
	var test_targets = []
	for i in range(50):
		var target = Node2D.new()
		target.name = "TestTarget_%d" % i
		add_child(target)
		test_targets.append(target)
	
	# 批量应用效果
	for i in range(100):
		var target = test_targets[i % test_targets.size()]
		gem_effect_system.apply_effect(target, "burn", 5.0, 1)
	
	var end_time = Time.get_time_dict_from_system()
	var duration_ms = (end_time.second * 1000 + end_time.millisecond) - (start_time.second * 1000 + start_time.millisecond)
	
	# 验证性能在可接受范围内（100个效果应该在10ms内完成）
	assert_true(duration_ms < 10.0, "Effect creation should be fast: %.2f ms" % duration_ms)
	
	# 验证效果池统计
	var pool_stats = gem_effect_system.effect_pool.get_debug_info()
	assert_true(pool_stats.total_allocated > 0, "Effect pool should have allocated effects")
	
	# 清理
	for target in test_targets:
		target.queue_free()
	gem_effect_system.queue_free()

# 测试敌人缓存效率
func test_enemy_cache_efficiency():
	var gem_effect_system = GemEffectSystem.new()
	add_child(gem_effect_system)
	
	# 创建测试敌人
	var enemies = []
	for i in range(20):
		var enemy = Node2D.new()
		enemy.name = "TestEnemy_%d" % i
		enemy.position = Vector2(i * 50, 0)
		enemy.add_to_group("enemy")
		add_child(enemy)
		enemies.append(enemy)
	
	# 测试缓存查找性能
	var start_time = Time.get_time_dict_from_system()
	
	for i in range(100):
		var found_enemies = gem_effect_system.get_enemies_in_area(Vector2(500, 0), 300.0)
		assert_true(found_enemies.size() > 0, "Should find enemies in area")
	
	var end_time = Time.get_time_dict_from_system()
	var duration_ms = (end_time.second * 1000 + end_time.millisecond) - (start_time.second * 1000 + start_time.millisecond)
	
	# 验证缓存查找比直接查找快
	assert_true(duration_ms < 5.0, "Cached enemy lookup should be fast: %.2f ms" % duration_ms)
	
	# 验证缓存统计
	var stats = gem_effect_system.get_performance_stats()
	assert_true(stats.cache_stats.enemy_cache_size > 0, "Enemy cache should contain enemies")
	
	# 清理
	for enemy in enemies:
		enemy.queue_free()
	gem_effect_system.queue_free()

# 测试内存监控
func test_memory_monitoring():
	var gem_effect_system = GemEffectSystem.new()
	add_child(gem_effect_system)
	
	# 启用调试模式
	gem_effect_system.set_debug_mode(true)
	
	# 创建大量效果来测试内存监控
	var targets = []
	for i in range(10):
		var target = Node2D.new()
		add_child(target)
		targets.append(target)
	
	# 应用效果
	for target in targets:
		gem_effect_system.apply_effect(target, "burn", 10.0, 5)
		gem_effect_system.apply_effect(target, "frost", 8.0, 3)
	
	# 强制创建内存快照
	var snapshot = gem_effect_system._create_memory_snapshot()
	
	assert_true(snapshot.has("total_effects"), "Memory snapshot should contain effect count")
	assert_true(snapshot.has("pool_memory_mb"), "Memory snapshot should contain memory usage")
	assert_true(snapshot.total_effects > 0, "Should have active effects")
	
	# 测试内存报告生成
	var memory_report = gem_effect_system.generate_memory_report()
	assert_true(memory_report.has("health_score"), "Memory report should contain health score")
	assert_true(memory_report.health_score >= 0 and memory_report.health_score <= 100, "Health score should be 0-100")
	
	# 清理
	for target in targets:
		target.queue_free()
	gem_effect_system.queue_free()

# 测试错误日志
func test_error_logging():
	var gem_effect_system = GemEffectSystem.new()
	add_child(gem_effect_system)
	
	gem_effect_system.set_debug_mode(true)
	
	# 测试各种错误情况
	gem_effect_system.apply_effect(null, "burn", 5.0, 1)  # 无效目标
	gem_effect_system.apply_effect(Node2D.new(), "", 5.0, 1)  # 空效果类型
	gem_effect_system.apply_effect(Node2D.new(), "burn", -1.0, 1)  # 负持续时间
	gem_effect_system.apply_effect(Node2D.new(), "burn", 5.0, 0)  # 无效层数
	
	# 验证错误日志
	var stats = gem_effect_system.get_performance_stats()
	assert_true(stats.error_count > 0, "Should have logged errors")
	assert_true(stats.warning_count > 0, "Should have logged warnings")
	
	gem_effect_system.queue_free()

# 测试性能监控
func test_performance_monitoring():
	var gem_effect_system = GemEffectSystem.new()
	add_child(gem_effect_system)
	
	gem_effect_system.set_debug_mode(true)
	
	# 创建一些目标并应用效果
	var targets = []
	for i in range(5):
		var target = Node2D.new()
		add_child(target)
		targets.append(target)
		gem_effect_system.apply_effect(target, "burn", 5.0, 1)
	
	# 运行几帧来收集性能数据
	for i in range(10):
		gem_effect_system._process(0.016)  # 模拟60FPS
	
	var stats = gem_effect_system.get_performance_stats()
	
	# 验证性能统计
	assert_true(stats.has("total_effects"), "Should track total effects")
	assert_true(stats.has("performance_issues"), "Should track performance issues")
	
	# 清理
	for target in targets:
		target.queue_free()
	gem_effect_system.queue_free()

# 测试优化建议
func test_optimization_suggestions():
	var gem_effect_system = GemEffectSystem.new()
	add_child(gem_effect_system)
	
	# 获取优化建议
	var suggestions = gem_effect_system.get_memory_optimization_suggestions()
	
	# 验证建议格式
	for suggestion in suggestions:
		assert_true(suggestion.has("type"), "Suggestion should have type")
		assert_true(suggestion.has("message"), "Suggestion should have message")
		assert_true(suggestion.has("priority"), "Suggestion should have priority")
		
		var valid_priorities = ["low", "medium", "high", "critical"]
		assert_true(suggestion.priority in valid_priorities, "Priority should be valid")
	
	gem_effect_system.queue_free()

# 辅助方法
func create_mock_target() -> Node2D:
	var target = Node2D.new()
	target.name = "MockTarget"
	return target