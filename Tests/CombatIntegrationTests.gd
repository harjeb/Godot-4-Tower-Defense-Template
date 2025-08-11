extends TestFramework
class_name CombatIntegrationTests

## 战斗系统集成测试套件
## 测试复合伤害计算公式、BUFF叠加规则（同类型加算，不同类型乘算）、实时战斗场景

func run_all_tests() -> Dictionary:
	var tests = [
		{"name": "test_basic_damage_calculation", "func": test_basic_damage_calculation},
		{"name": "test_element_effectiveness_integration", "func": test_element_effectiveness_integration},
		{"name": "test_gem_damage_bonus_integration", "func": test_gem_damage_bonus_integration},
		{"name": "test_weapon_wheel_buff_integration", "func": test_weapon_wheel_buff_integration},
		{"name": "test_buff_stacking_rules_additive", "func": test_buff_stacking_rules_additive},
		{"name": "test_buff_stacking_rules_multiplicative", "func": test_buff_stacking_rules_multiplicative},
		{"name": "test_complex_damage_formula", "func": test_complex_damage_formula},
		{"name": "test_stealth_detection_in_combat", "func": test_stealth_detection_in_combat},
		{"name": "test_split_enemy_combat_mechanics", "func": test_split_enemy_combat_mechanics},
		{"name": "test_healing_enemy_combat_interaction", "func": test_healing_enemy_combat_interaction},
		{"name": "test_real_time_combat_scenario", "func": test_real_time_combat_scenario},
		{"name": "test_performance_damage_calculation", "func": test_performance_damage_calculation}
	]
	
	return run_test_suite("Combat System Integration Tests", tests)

# 创建测试炮塔的辅助方法
func create_test_turret(turret_type: String = "gatling", element: String = "neutral") -> Node2D:
	var turret = Node2D.new()
	turret.set_script(preload("res://Scenes/turrets/turretBase/turret_base.gd"))
	
	# 设置基础属性
	turret.turret_type = turret_type
	turret.element = element
	turret.turret_category = Data.turrets[turret_type].get("turret_category", "projectile")
	turret.damage = Data.turrets[turret_type]["stats"]["damage"]
	turret.equipped_gem = {}
	
	# 添加必要的子节点
	var detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	turret.add_child(detection_area)
	
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	detection_area.add_child(collision)
	
	var attack_cooldown = Timer.new()
	attack_cooldown.name = "AttackCooldown"
	turret.add_child(attack_cooldown)
	
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	turret.add_child(sprite)
	
	return turret

# 创建测试敌人的辅助方法
func create_test_enemy_for_combat(element: String = "neutral", hp: float = 100.0) -> Node:
	var enemy = Node2D.new()
	enemy.set_script(preload("res://Scenes/enemies/enemy_mover.gd"))
	
	enemy.element = element
	enemy.hp = hp
	enemy.max_hp = hp
	enemy.special_abilities = []
	enemy.is_stealthed = false
	enemy.progress_ratio = 0.5  # 在路径中间
	
	# 添加必要的子节点
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	enemy.add_child(sprite)
	
	return enemy

# 测试基础伤害计算
func test_basic_damage_calculation():
	var turret = create_test_turret("gatling", "neutral")
	var enemy = create_test_enemy_for_combat("neutral", 100.0)
	
	var base_damage = 50.0
	var calculated_damage = turret.calculate_final_damage(base_damage, enemy.element)
	
	# 无任何加成时应该等于基础伤害
	assert_approximately(calculated_damage, base_damage, 0.001, "无加成时伤害应该等于基础伤害")
	
	turret.queue_free()
	enemy.queue_free()

# 测试元素克制集成
func test_element_effectiveness_integration():
	# 火元素炮塔对风元素敌人（克制关系）
	var fire_turret = create_test_turret("gatling", "fire")
	var wind_enemy = create_test_enemy_for_combat("wind", 100.0)
	
	var base_damage = 100.0
	var damage_vs_wind = fire_turret.calculate_final_damage(base_damage, wind_enemy.element)
	
	# 火克制风，应该有1.5倍伤害
	assert_approximately(damage_vs_wind, 150.0, 0.001, "火克制风应该造成1.5倍伤害")
	
	# 反向测试：风元素炮塔对火元素敌人（被克制）
	var wind_turret = create_test_turret("gatling", "wind")
	var fire_enemy = create_test_enemy_for_combat("fire", 100.0)
	
	var damage_vs_fire = wind_turret.calculate_final_damage(base_damage, fire_enemy.element)
	assert_approximately(damage_vs_fire, 75.0, 0.001, "风被火克制应该造成0.75倍伤害")
	
	fire_turret.queue_free()
	wind_enemy.queue_free()
	wind_turret.queue_free()
	fire_enemy.queue_free()

# 测试宝石伤害加成集成
func test_gem_damage_bonus_integration():
	var turret = create_test_turret("gatling", "neutral")
	var enemy = create_test_enemy_for_combat("neutral", 100.0)
	
	# 装备中级火宝石（20%加成）
	var fire_gem = create_mock_gem_data("fire", 2)
	turret.equip_gem(fire_gem)
	
	var base_damage = 100.0
	var damage_with_gem = turret.calculate_final_damage(base_damage, enemy.element)
	
	# 应该有20%的宝石加成
	assert_approximately(damage_with_gem, 120.0, 0.001, "装备20%宝石后伤害应该是120")
	
	# 测试宝石+元素克制组合
	var wind_enemy = create_test_enemy_for_combat("wind", 100.0)
	var damage_with_gem_and_effectiveness = turret.calculate_final_damage(base_damage, wind_enemy.element)
	
	# 20%宝石加成 * 1.5倍克制 = 120 * 1.5 = 180
	assert_approximately(damage_with_gem_and_effectiveness, 180.0, 0.001, "宝石+克制组合伤害应该是180")
	
	turret.queue_free()
	enemy.queue_free()
	wind_enemy.queue_free()

# 测试武器盘BUFF集成
func test_weapon_wheel_buff_integration():
	var turret = create_test_turret("gatling", "fire")  # 投射物+火元素炮塔
	var enemy = create_test_enemy_for_combat("neutral", 100.0)
	
	# 创建武器盘管理器并添加BUFF
	var weapon_wheel = WeaponWheelManager.new()
	weapon_wheel.add_to_weapon_wheel("projectile_damage")  # 5%投射物伤害
	weapon_wheel.add_to_weapon_wheel("fire_element")       # 10%火元素加成
	
	# 将武器盘管理器添加到场景树中（模拟实际运行环境）
	add_child(weapon_wheel)
	weapon_wheel.name = "WeaponWheelManager"
	
	var base_damage = 100.0
	var damage_with_buffs = turret.calculate_final_damage(base_damage, enemy.element)
	
	# 投射物BUFF(5%) + 火元素BUFF(10%) = 15%总加成
	assert_approximately(damage_with_buffs, 115.0, 0.001, "武器盘BUFF应该提供15%总加成")
	
	weapon_wheel.queue_free()
	turret.queue_free()
	enemy.queue_free()

# 测试BUFF叠加规则 - 加算（同类型）
func test_buff_stacking_rules_additive():
	var turret = create_test_turret("gatling", "fire")
	var enemy = create_test_enemy_for_combat("neutral", 100.0)
	
	var weapon_wheel = WeaponWheelManager.new()
	
	# 添加多个相同类型的BUFF
	weapon_wheel.add_to_weapon_wheel("fire_element")  # 10%火元素
	weapon_wheel.add_to_weapon_wheel("fire_element")  # 另一个10%火元素
	
	add_child(weapon_wheel)
	weapon_wheel.name = "WeaponWheelManager"
	
	var base_damage = 100.0
	var damage_with_stacked_buffs = turret.calculate_final_damage(base_damage, enemy.element)
	
	# 两个10%火元素BUFF应该加算：1.0 + 0.1 + 0.1 = 1.2倍
	assert_approximately(damage_with_stacked_buffs, 120.0, 0.001, "相同类型BUFF应该加算到120")
	
	weapon_wheel.queue_free()
	turret.queue_free()
	enemy.queue_free()

# 测试BUFF叠加规则 - 乘算（不同类型）
func test_buff_stacking_rules_multiplicative():
	var turret = create_test_turret("gatling", "fire")
	var wind_enemy = create_test_enemy_for_combat("wind", 100.0)
	
	var weapon_wheel = WeaponWheelManager.new()
	
	# 添加不同类型的BUFF
	weapon_wheel.add_to_weapon_wheel("projectile_damage")  # 5%炮塔类型
	weapon_wheel.add_to_weapon_wheel("fire_element")       # 10%元素
	
	add_child(weapon_wheel)
	weapon_wheel.name = "WeaponWheelManager"
	
	# 装备宝石增加更多元素加成
	var fire_gem = create_mock_gem_data("fire", 1)  # 10%宝石加成
	turret.equip_gem(fire_gem)
	
	var base_damage = 100.0
	var final_damage = turret.calculate_final_damage(base_damage, wind_enemy.element)
	
	# 计算公式：基础 × 炮塔类型BUFF × 元素BUFF(武器盘+宝石) × 属性克制
	# 100 × 1.05 × (1.0 + 0.1 + 0.1) × 1.5 = 100 × 1.05 × 1.2 × 1.5 = 189
	assert_approximately(final_damage, 189.0, 0.001, "不同类型BUFF应该乘算")
	
	weapon_wheel.queue_free()
	turret.queue_free()
	wind_enemy.queue_free()

# 测试复合伤害公式的完整性
func test_complex_damage_formula():
	var turret = create_test_turret("ray", "light")  # 射线炮塔+光元素
	var dark_enemy = create_test_enemy_for_combat("dark", 100.0)
	
	var weapon_wheel = WeaponWheelManager.new()
	
	# 添加多种BUFF
	weapon_wheel.add_to_weapon_wheel("ray_damage")      # 8%射线伤害
	weapon_wheel.add_to_weapon_wheel("light_element")   # 10%光元素
	weapon_wheel.add_to_weapon_wheel("light_element")   # 再一个10%光元素
	
	add_child(weapon_wheel)
	weapon_wheel.name = "WeaponWheelManager"
	
	# 装备高级光宝石
	var light_gem = create_mock_gem_data("light", 3)  # 35%宝石加成
	turret.equip_gem(light_gem)
	
	var base_damage = 100.0
	var final_damage = turret.calculate_final_damage(base_damage, dark_enemy.element)
	
	# 计算公式：
	# 炮塔类型倍率：1.0 + 0.08 = 1.08
	# 元素倍率：1.0 + 0.1 + 0.1 + 0.35 = 1.55 (武器盘*2 + 宝石)
	# 属性克制：1.5 (光克制暗)
	# 最终：100 × 1.08 × 1.55 × 1.5 = 251.1
	assert_approximately(final_damage, 251.1, 0.1, "复合伤害公式应该正确计算")
	
	weapon_wheel.queue_free()
	turret.queue_free()
	dark_enemy.queue_free()

# 测试隐身检测在战斗中的集成
func test_stealth_detection_in_combat():
	# 普通炮塔不能检测隐身敌人
	var normal_turret = create_test_turret("gatling", "fire")
	var stealth_enemy = create_test_enemy_for_combat("neutral", 100.0)
	stealth_enemy.special_abilities = ["stealth"]
	stealth_enemy.is_stealthed = true
	
	var can_detect_normal = normal_turret.can_detect_stealth()
	assert_false(can_detect_normal, "普通火元素炮塔不应该能检测隐身敌人")
	
	# 光元素炮塔能检测隐身敌人
	var light_turret = create_test_turret("gatling", "light")
	var can_detect_light = light_turret.can_detect_stealth()
	assert_true(can_detect_light, "光元素炮塔应该能检测隐身敌人")
	
	# 装备光宝石的炮塔能检测隐身敌人
	var gem_turret = create_test_turret("gatling", "neutral")
	var light_gem = create_mock_gem_data("light", 1)
	gem_turret.equip_gem(light_gem)
	
	var can_detect_gem = gem_turret.can_detect_stealth()
	assert_true(can_detect_gem, "装备光宝石的炮塔应该能检测隐身敌人")
	
	normal_turret.queue_free()
	stealth_enemy.queue_free()
	light_turret.queue_free()
	gem_turret.queue_free()

# 测试分裂敌人战斗机制
func test_split_enemy_combat_mechanics():
	var turret = create_test_turret("gatling", "earth")
	var split_enemy = create_test_enemy_for_combat("earth", 100.0)
	
	split_enemy.special_abilities = ["split"]
	split_enemy.can_split = true
	split_enemy.split_count = 0
	split_enemy.max_splits = 2
	
	# 测试分裂条件
	var should_split = split_enemy.can_split and split_enemy.split_count < split_enemy.max_splits
	assert_true(should_split, "初始状态的分裂敌人应该满足分裂条件")
	
	# 模拟受到足够伤害死亡
	var lethal_damage = turret.calculate_final_damage(150.0, split_enemy.element)
	assert_true(lethal_damage >= split_enemy.hp, "致命伤害应该足以杀死敌人")
	
	# 测试分裂计数增加后的情况
	split_enemy.split_count = 2
	var cannot_split = not (split_enemy.can_split and split_enemy.split_count < split_enemy.max_splits)
	assert_true(cannot_split, "达到最大分裂次数后不应该再分裂")
	
	turret.queue_free()
	split_enemy.queue_free()

# 测试治疗敌人在战斗中的交互
func test_healing_enemy_combat_interaction():
	var turret = create_test_turret("gatling", "light")
	var healer_enemy = create_test_enemy_for_combat("light", 100.0)
	
	healer_enemy.special_abilities = ["heal"]
	healer_enemy.can_heal = true
	healer_enemy.heal_cooldown = 7.0
	healer_enemy.heal_timer = 0.0  # 冷却完成
	
	# 设置受伤状态
	healer_enemy.hp = 60.0
	
	# 测试治疗条件
	var can_heal = healer_enemy.can_heal and healer_enemy.heal_timer <= 0 and healer_enemy.hp < healer_enemy.max_hp
	assert_true(can_heal, "受伤的治疗敌人在冷却完成后应该能治疗")
	
	# 计算治疗量
	var heal_amount = healer_enemy.max_hp * 0.1  # 10%最大血量
	var expected_hp_after_heal = min(healer_enemy.hp + heal_amount, healer_enemy.max_hp)
	assert_approximately(expected_hp_after_heal, 70.0, 0.001, "治疗后血量应该增加到70")
	
	# 测试对治疗敌人的伤害计算（光vs光，无克制）
	var damage_to_healer = turret.calculate_final_damage(50.0, healer_enemy.element)
	assert_approximately(damage_to_healer, 50.0, 0.001, "光对光应该是正常伤害")
	
	turret.queue_free()
	healer_enemy.queue_free()

# 测试实时战斗场景
func test_real_time_combat_scenario():
	# 创建一个包含多种元素和能力的战斗场景
	var fire_turret = create_test_turret("gatling", "fire")
	var ice_turret = create_test_turret("ray", "ice")
	var light_turret = create_test_turret("melee", "light")
	
	# 创建各种敌人
	var wind_enemy = create_test_enemy_for_combat("wind", 80.0)      # 被火克制
	var fire_enemy = create_test_enemy_for_combat("fire", 100.0)     # 被冰克制
	var dark_stealth_enemy = create_test_enemy_for_combat("dark", 60.0)  # 被光克制，隐身
	dark_stealth_enemy.special_abilities = ["stealth"]
	dark_stealth_enemy.is_stealthed = true
	
	# 设置武器盘BUFF
	var weapon_wheel = WeaponWheelManager.new()
	weapon_wheel.add_to_weapon_wheel("projectile_damage")
	weapon_wheel.add_to_weapon_wheel("fire_element")
	weapon_wheel.add_to_weapon_wheel("ray_damage")
	
	add_child(weapon_wheel)
	weapon_wheel.name = "WeaponWheelManager"
	
	# 测试各种战斗交互
	var fire_vs_wind = fire_turret.calculate_final_damage(50.0, wind_enemy.element)
	assert_true(fire_vs_wind > 50.0, "火炮塔对风敌人应该有优势")
	
	var ice_vs_fire = ice_turret.calculate_final_damage(40.0, fire_enemy.element)
	assert_true(ice_vs_fire > 40.0, "冰炮塔对火敌人应该有优势")
	
	var light_detect_stealth = light_turret.can_detect_stealth()
	assert_true(light_detect_stealth, "光元素炮塔应该能检测隐身暗敌人")
	
	var light_vs_dark = light_turret.calculate_final_damage(60.0, dark_stealth_enemy.element)
	assert_true(light_vs_dark > 60.0, "光炮塔对暗敌人应该有克制优势")
	
	# 清理
	fire_turret.queue_free()
	ice_turret.queue_free()
	light_turret.queue_free()
	wind_enemy.queue_free()
	fire_enemy.queue_free()
	dark_stealth_enemy.queue_free()
	weapon_wheel.queue_free()

# 性能测试：伤害计算
func test_performance_damage_calculation():
	var turret = create_test_turret("gatling", "fire")
	var enemy = create_test_enemy_for_combat("wind", 100.0)
	
	# 设置复杂的战斗环境
	var weapon_wheel = WeaponWheelManager.new()
	weapon_wheel.add_to_weapon_wheel("projectile_damage")
	weapon_wheel.add_to_weapon_wheel("fire_element")
	weapon_wheel.add_to_weapon_wheel("fire_element")
	
	add_child(weapon_wheel)
	weapon_wheel.name = "WeaponWheelManager"
	
	var fire_gem = create_mock_gem_data("fire", 3)
	turret.equip_gem(fire_gem)
	
	# 测试伤害计算性能
	var damage_calc_test = func():
		turret.calculate_final_damage(100.0, enemy.element)
	
	var benchmark_result = benchmark_function("complex_damage_calculation", damage_calc_test, 10000)
	
	# 性能断言：复杂伤害计算应该在0.05ms内完成
	assert_true(benchmark_result.average_duration < 0.05,
		"复杂伤害计算平均耗时应该少于0.05ms，实际: %.4fms" % benchmark_result.average_duration)
	
	# 测试总伤害倍率计算性能
	var multiplier_test = func():
		turret.get_total_damage_multiplier(enemy.element)
	
	var multiplier_benchmark = benchmark_function("damage_multiplier_calculation", multiplier_test, 10000)
	
	assert_true(multiplier_benchmark.average_duration < 0.03,
		"伤害倍率计算平均耗时应该少于0.03ms，实际: %.4fms" % multiplier_benchmark.average_duration)
	
	turret.queue_free()
	enemy.queue_free()
	weapon_wheel.queue_free()