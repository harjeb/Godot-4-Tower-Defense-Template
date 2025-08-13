extends Node

## GemEffectSystem 使用示例
## 展示如何使用改进后的宝石效果系统

func _ready():
	print("=== GemEffectSystem Usage Example ===")
	
	# 获取效果系统
	var gem_effect_system = get_gem_effect_system()
	if not gem_effect_system:
		print("Error: GemEffectSystem not found!")
		return
	
	# 启用调试模式查看详细信息
	gem_effect_system.set_debug_mode(true)
	
	# 示例1：基本效果应用
	demonstrate_basic_effects(gem_effect_system)
	
	# 示例2：区域效果应用
	demonstrate_area_effects(gem_effect_system)
	
	# 示例3：性能监控
	demonstrate_performance_monitoring(gem_effect_system)
	
	# 示例4：内存监控
	demonstrate_memory_monitoring(gem_effect_system)

func get_gem_effect_system() -> GemEffectSystem:
	# 尝试从场景树中获取
	var effect_system = get_tree().current_scene.get_node_or_null("GemEffectSystem")
	if not effect_system:
		# 如果不存在，创建一个新的
		effect_system = GemEffectSystem.new()
		get_tree().current_scene.add_child(effect_system)
		print("Created new GemEffectSystem instance")
	return effect_system

func demonstrate_basic_effects(gem_effect_system: GemEffectSystem):
	print("\n--- Basic Effects Demo ---")
	
	# 创建测试目标
	var enemy = Node2D.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	
	# 应用不同类型的效果
	gem_effect_system.apply_effect(enemy, "burn", 5.0, 3)
	gem_effect_system.apply_effect(enemy, "frost", 8.0, 2)
	gem_effect_system.apply_effect(enemy, "armor_break", 10.0, 1)
	
	print("Applied burn, frost, and armor_break effects to enemy")
	
	# 检查效果状态
	var effects = gem_effect_system.get_effects_on_target(enemy)
	print("Target has %d active effects" % effects.size())
	
	for effect in effects:
		print("  - %s: %d stacks, %.1fs remaining" % [
			effect.effect_type, effect.stacks, effect.duration
		])
	
	# 移除特定效果
	gem_effect_system.remove_effect(enemy, "frost")
	print("Removed frost effect")
	
	enemy.queue_free()

func demonstrate_area_effects(gem_effect_system: GemEffectSystem):
	print("\n--- Area Effects Demo ---")
	
	# 创建多个敌人
	var enemies = []
	for i in range(5):
		var enemy = Node2D.new()
		enemy.name = "Enemy_%d" % i
		enemy.position = Vector2(i * 50, 0)
		enemy.add_to_group("enemy")
		add_child(enemy)
		enemies.append(enemy)
	
	# 应用区域冰霜效果
	gem_effect_system.apply_frost_area(Vector2(100, 0), 150.0, 2, 6.0)
	print("Applied frost area effect at (100, 0) with radius 150")
	
	# 检查受影响的敌人
	var affected_enemies = gem_effect_system.get_enemies_in_area(Vector2(100, 0), 150.0)
	print("Found %d enemies in area" % affected_enemies.size())
	
	# 应用重压区域效果
	gem_effect_system.apply_weight_area(Vector2(100, 0), 200.0, 1, 4.0)
	print("Applied weight area effect")
	
	# 清理
	for enemy in enemies:
		enemy.queue_free()

func demonstrate_performance_monitoring(gem_effect_system: GemEffectSystem):
	print("\n--- Performance Monitoring Demo ---")
	
	# 获取性能统计
	var stats = gem_effect_system.get_performance_stats()
	
	print("Current Performance Stats:")
	print("  Total Effects: %d" % stats.total_effects)
	print("  Memory Usage: %.2f MB" % stats.memory_stats.effect_pool_memory_mb)
	print("  Enemy Cache Size: %d" % stats.cache_stats.enemy_cache_size)
	print("  Errors: %d, Warnings: %d" % [stats.error_count, stats.warning_count])
	
	# 测试性能（创建大量效果）
	print("\nCreating 50 effects for performance test...")
	var test_targets = []
	
	for i in range(10):
		var target = Node2D.new()
		add_child(target)
		test_targets.append(target)
	
	var start_time = Time.get_time_dict_from_system()
	
	for i in range(50):
		var target = test_targets[i % test_targets.size()]
		var effect_types = ["burn", "frost", "shock", "corruption", "slow"]
		var effect_type = effect_types[i % effect_types.size()]
		gem_effect_system.apply_effect(target, effect_type, 3.0, 1)
	
	var end_time = Time.get_time_dict_from_system()
	var duration_ms = (end_time.second * 1000 + end_time.millisecond) - (start_time.second * 1000 + start_time.millisecond)
	
	print("Created 50 effects in %.2f ms" % duration_ms)
	
	# 清理
	for target in test_targets:
		target.queue_free()

func demonstrate_memory_monitoring(gem_effect_system: GemEffectSystem):
	print("\n--- Memory Monitoring Demo ---")
	
	# 生成内存报告
	var memory_report = gem_effect_system.generate_memory_report()
	
	print("System Health Score: %d/100" % memory_report.health_score)
	
	if memory_report.health_score < 80:
		print("System health is below optimal!")
		
		var suggestions = memory_report.optimization_suggestions
		if not suggestions.is_empty():
			print("Optimization suggestions:")
			for suggestion in suggestions:
				print("  [%s] %s" % [suggestion.priority.to_upper(), suggestion.message])
	else:
		print("System health is good!")
	
	# 显示内存趋势
	if memory_report.memory_trend.slope > 0:
		print("Memory usage is increasing (slope: %.3f)" % memory_report.memory_trend.slope)
	elif memory_report.memory_trend.slope < 0:
		print("Memory usage is decreasing (slope: %.3f)" % memory_report.memory_trend.slope)
	else:
		print("Memory usage is stable")
	
	# 打印完整调试信息
	gem_effect_system.print_debug_info()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("\n=== Running GemEffectSystem demonstration again ===")
		_ready()
	elif event.is_action_pressed("ui_cancel"):
		# 打印效果池性能报告
		var gem_effect_system = get_gem_effect_system()
		if gem_effect_system and gem_effect_system.effect_pool:
			gem_effect_system.effect_pool.print_performance_report()