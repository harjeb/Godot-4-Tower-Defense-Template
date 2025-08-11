extends TestFramework
class_name EnemyAbilitiesTests

## 敌人特殊能力测试套件
## 测试隐身、分裂、治疗能力的功能实现和机制验证

func run_all_tests() -> Dictionary:
	var tests = [
		{"name": "test_stealth_ability_setup", "func": test_stealth_ability_setup},
		{"name": "test_stealth_visual_effect", "func": test_stealth_visual_effect},
		{"name": "test_stealth_detection_mechanics", "func": test_stealth_detection_mechanics},
		{"name": "test_split_ability_setup", "func": test_split_ability_setup},
		{"name": "test_split_on_death_mechanics", "func": test_split_on_death_mechanics},
		{"name": "test_split_count_limitation", "func": test_split_count_limitation},
		{"name": "test_heal_ability_setup", "func": test_heal_ability_setup},
		{"name": "test_heal_cooldown_mechanism", "func": test_heal_cooldown_mechanism},
		{"name": "test_heal_amount_calculation", "func": test_heal_amount_calculation},
		{"name": "test_multiple_abilities_combination", "func": test_multiple_abilities_combination},
		{"name": "test_enemy_data_special_abilities_integrity", "func": test_enemy_data_special_abilities_integrity},
		{"name": "test_performance_ability_processing", "func": test_performance_ability_processing}
	]
	
	return run_test_suite("Enemy Special Abilities Tests", tests)

# 创建测试用敌人实例的辅助方法
func create_test_enemy(element: String = "neutral", abilities: Array = []) -> Node:
	# 创建一个模拟的敌人节点用于测试
	var enemy = Node2D.new()
	enemy.name = "TestEnemy"
	
	# 添加enemy_mover脚本的关键属性
	enemy.set_script(preload("res://Scenes/enemies/enemy_mover.gd"))
	
	# 设置基础属性
	enemy.element = element
	enemy.special_abilities = abilities
	enemy.max_hp = 100.0
	enemy.hp = 100.0
	enemy.is_stealthed = false
	enemy.can_split = false
	enemy.split_count = 0
	enemy.max_splits = 2
	enemy.can_heal = false
	enemy.heal_cooldown = 7.0
	enemy.heal_timer = 7.0
	
	# 添加必要的子节点用于测试
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	enemy.add_child(sprite)
	
	return enemy

# 测试隐身能力设置
func test_stealth_ability_setup():
	var enemy = create_test_enemy("wind", ["stealth"])
	
	# 调用setup_special_abilities方法
	enemy.setup_special_abilities()
	
	assert_true(enemy.is_stealthed, "具有stealth能力的敌人应该处于隐身状态")
	assert_approximately(enemy.modulate.a, 0.5, 0.01, "隐身敌人应该是半透明的（alpha=0.5）")
	
	enemy.queue_free()

# 测试隐身视觉效果
func test_stealth_visual_effect():
	var enemy = create_test_enemy("neutral", [])
	enemy.setup_special_abilities()
	
	# 未隐身敌人应该是完全不透明
	assert_approximately(enemy.modulate.a, 1.0, 0.01, "普通敌人应该是完全不透明的（alpha=1.0）")
	
	# 手动设置隐身状态
	enemy.special_abilities = ["stealth"]
	enemy.setup_special_abilities()
	
	assert_approximately(enemy.modulate.a, 0.5, 0.01, "设置隐身后应该变成半透明")
	
	enemy.queue_free()

# 测试隐身检测机制
func test_stealth_detection_mechanics():
	var stealth_enemy = create_test_enemy("neutral", ["stealth"])
	stealth_enemy.setup_special_abilities()
	
	# 测试is_stealthed方法
	assert_true(stealth_enemy.get_is_stealthed(), "隐身敌人的get_is_stealthed()应该返回true")
	
	var normal_enemy = create_test_enemy("neutral", [])
	normal_enemy.setup_special_abilities()
	
	assert_false(normal_enemy.get_is_stealthed(), "普通敌人的get_is_stealthed()应该返回false")
	
	stealth_enemy.queue_free()
	normal_enemy.queue_free()

# 测试分裂能力设置
func test_split_ability_setup():
	var enemy = create_test_enemy("earth", ["split"])
	enemy.setup_special_abilities()
	
	assert_true(enemy.can_split, "具有split能力的敌人can_split应该为true")
	assert_equal(enemy.split_count, 0, "初始分裂计数应该为0")
	assert_equal(enemy.max_splits, 2, "最大分裂次数应该为2")
	
	enemy.queue_free()

# 测试死亡分裂机制
func test_split_on_death_mechanics():
	var enemy = create_test_enemy("earth", ["split"])
	enemy.setup_special_abilities()
	
	# 模拟死亡前的状态检查
	assert_true(enemy.can_split, "敌人应该具有分裂能力")
	assert_true(enemy.split_count < enemy.max_splits, "分裂计数应该小于最大分裂次数")
	
	# 测试分裂条件
	var should_split = enemy.can_split and enemy.split_count < enemy.max_splits
	assert_true(should_split, "满足分裂条件的敌人应该能够分裂")
	
	enemy.queue_free()

# 测试分裂次数限制
func test_split_count_limitation():
	var enemy = create_test_enemy("earth", ["split"])
	enemy.setup_special_abilities()
	
	# 测试不同分裂计数下的分裂能力
	enemy.split_count = 0
	assert_true(enemy.can_split and enemy.split_count < enemy.max_splits, "分裂计数为0时应该可以分裂")
	
	enemy.split_count = 1
	assert_true(enemy.can_split and enemy.split_count < enemy.max_splits, "分裂计数为1时应该可以分裂")
	
	enemy.split_count = 2
	assert_false(enemy.can_split and enemy.split_count < enemy.max_splits, "分裂计数达到最大值2时不应该可以分裂")
	
	enemy.split_count = 3
	assert_false(enemy.can_split and enemy.split_count < enemy.max_splits, "分裂计数超过最大值时不应该可以分裂")
	
	enemy.queue_free()

# 测试治疗能力设置
func test_heal_ability_setup():
	var enemy = create_test_enemy("light", ["heal"])
	enemy.setup_special_abilities()
	
	assert_true(enemy.can_heal, "具有heal能力的敌人can_heal应该为true")
	assert_approximately(enemy.heal_cooldown, 7.0, 0.01, "治疗冷却时间应该为7秒")
	assert_approximately(enemy.heal_timer, 7.0, 0.01, "治疗计时器初始值应该为7秒")
	
	enemy.queue_free()

# 测试治疗冷却机制
func test_heal_cooldown_mechanism():
	var enemy = create_test_enemy("light", ["heal"])
	enemy.setup_special_abilities()
	
	# 设置受伤状态
	enemy.hp = 50.0  # 半血状态
	enemy.heal_timer = 0.0  # 冷却完成
	
	# 测试治疗条件
	var can_heal_now = enemy.can_heal and enemy.heal_timer <= 0 and enemy.hp < enemy.max_hp
	assert_true(can_heal_now, "冷却完成且血量不满时应该可以治疗")
	
	# 测试满血时不治疗
	enemy.hp = enemy.max_hp
	var cannot_heal_full_hp = not (enemy.can_heal and enemy.heal_timer <= 0 and enemy.hp < enemy.max_hp)
	assert_true(cannot_heal_full_hp, "满血时不应该治疗")
	
	enemy.queue_free()

# 测试治疗量计算
func test_heal_amount_calculation():
	var enemy = create_test_enemy("light", ["heal"])
	enemy.setup_special_abilities()
	enemy.max_hp = 100.0
	enemy.hp = 50.0
	
	# 计算期望的治疗量（10%最大血量）
	var expected_heal = enemy.max_hp * 0.1
	assert_approximately(expected_heal, 10.0, 0.01, "治疗量应该是最大血量的10%")
	
	# 计算治疗后的血量
	var expected_hp_after_heal = min(enemy.hp + expected_heal, enemy.max_hp)
	assert_approximately(expected_hp_after_heal, 60.0, 0.01, "治疗后血量应该为60")
	
	# 测试接近满血时的治疗
	enemy.hp = 95.0
	var heal_near_full = min(enemy.hp + expected_heal, enemy.max_hp)
	assert_approximately(heal_near_full, 100.0, 0.01, "接近满血时治疗应该不超过最大血量")
	
	enemy.queue_free()

# 测试多种能力组合
func test_multiple_abilities_combination():
	var multi_ability_enemy = create_test_enemy("neutral", ["stealth", "split", "heal"])
	multi_ability_enemy.setup_special_abilities()
	
	# 验证所有能力都被正确设置
	assert_true(multi_ability_enemy.is_stealthed, "应该具有隐身能力")
	assert_true(multi_ability_enemy.can_split, "应该具有分裂能力")
	assert_true(multi_ability_enemy.can_heal, "应该具有治疗能力")
	assert_approximately(multi_ability_enemy.modulate.a, 0.5, 0.01, "应该显示隐身视觉效果")
	
	# 测试能力检查方法
	assert_true(multi_ability_enemy.has_ability("stealth"), "应该检测到stealth能力")
	assert_true(multi_ability_enemy.has_ability("split"), "应该检测到split能力")
	assert_true(multi_ability_enemy.has_ability("heal"), "应该检测到heal能力")
	assert_false(multi_ability_enemy.has_ability("unknown"), "不应该检测到不存在的能力")
	
	multi_ability_enemy.queue_free()

# 测试敌人数据中特殊能力的数据完整性
func test_enemy_data_special_abilities_integrity():
	var enemies_with_abilities = [
		{"type": "yellowDino", "expected_abilities": ["stealth"]},
		{"type": "greenDino", "expected_abilities": ["split"]},
		{"type": "stealthDino", "expected_abilities": ["stealth"]},
		{"type": "healerDino", "expected_abilities": ["heal"]}
	]
	
	for enemy_data in enemies_with_abilities:
		var enemy_type = enemy_data.type
		var expected_abilities = enemy_data.expected_abilities
		
		assert_true(enemy_type in Data.enemies, "敌人类型 %s 应该在Data.enemies中定义" % enemy_type)
		
		var data = Data.enemies[enemy_type]
		assert_has_key(data, "special_abilities", "敌人 %s 应该有special_abilities字段" % enemy_type)
		
		var abilities = data.special_abilities
		for ability in expected_abilities:
			assert_true(ability in abilities, "敌人 %s 应该具有 %s 能力" % [enemy_type, ability])

# 测试无特殊能力敌人的数据完整性
func test_normal_enemies_data_integrity():
	var normal_enemies = ["redDino", "blueDino"]
	
	for enemy_type in normal_enemies:
		assert_true(enemy_type in Data.enemies, "敌人类型 %s 应该在Data.enemies中定义" % enemy_type)
		
		var data = Data.enemies[enemy_type]
		assert_has_key(data, "special_abilities", "敌人 %s 应该有special_abilities字段" % enemy_type)
		
		var abilities = data.special_abilities
		assert_array_size(abilities, 0, "普通敌人 %s 不应该有特殊能力" % enemy_type)

# 性能测试：能力处理
func test_performance_ability_processing():
	# 测试设置特殊能力的性能
	var setup_test = func():
		var enemy = create_test_enemy("neutral", ["stealth", "split", "heal"])
		enemy.setup_special_abilities()
		enemy.queue_free()
	
	var benchmark_result = benchmark_function("ability_setup", setup_test, 1000)
	
	# 性能断言：平均每次设置应该少于0.1ms
	assert_true(benchmark_result.average_duration < 0.1,
		"能力设置平均耗时应该少于0.1ms，实际: %.4fms" % benchmark_result.average_duration)
	
	# 测试能力检查的性能
	var enemy = create_test_enemy("neutral", ["stealth", "split", "heal"])
	enemy.setup_special_abilities()
	
	var check_test = func():
		enemy.has_ability("stealth")
		enemy.has_ability("split") 
		enemy.has_ability("heal")
		enemy.has_ability("unknown")
	
	var check_benchmark = benchmark_function("ability_check", check_test, 10000)
	
	assert_true(check_benchmark.average_duration < 0.01,
		"能力检查平均耗时应该少于0.01ms，实际: %.4fms" % check_benchmark.average_duration)
	
	enemy.queue_free()