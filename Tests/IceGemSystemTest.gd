extends TestFramework
class_name IceGemSystemTest

## 冰元素宝石系统完整测试
## 测试所有9种塔类型的冰宝石技能效果

func _ready():
	super._ready()
	test_name = "冰元素宝石系统测试"

func run_tests() -> void:
	print("=== 开始冰元素宝石系统测试 ===")
	
	test_ice_gem_data_integrity()
	test_status_effect_system()
	test_gem_effect_system()
	test_tower_integration()
	test_ice_element_effectiveness()
	test_performance_optimization()
	
	print("=== 冰元素宝石系统测试完成 ===")

func test_ice_gem_data_integrity() -> void:
	print_section("冰宝石数据完整性测试")
	
	# 测试基础冰宝石
	var basic_ice = Data.gems.get("ice_basic")
	assert_not_null(basic_ice, "基础冰宝石数据存在")
	assert_equal(basic_ice.element, "ice", "基础冰宝石元素正确")
	assert_equal(basic_ice.level, 1, "基础冰宝石等级正确")
	assert_has_key(basic_ice, "tower_skills", "基础冰宝石有塔技能")
	
	# 测试中级冰宝石
	var intermediate_ice = Data.gems.get("ice_intermediate")
	assert_not_null(intermediate_ice, "中级冰宝石数据存在")
	assert_equal(intermediate_ice.level, 2, "中级冰宝石等级正确")
	
	# 测试高级冰宝石
	var advanced_ice = Data.gems.get("ice_advanced")
	assert_not_null(advanced_ice, "高级冰宝石数据存在")
	assert_equal(advanced_ice.level, 3, "高级冰宝石等级正确")
	
	# 测试所有塔类型都有技能定义
	var tower_types = ["arrow_tower", "capture_tower", "mage_tower", "感应塔", "末日塔", "pulse_tower", "弹射塔", "aura_tower", "weakness_tower"]
	
	for gem_level in ["ice_basic", "ice_intermediate", "ice_advanced"]:
		var gem_data = Data.gems[gem_level]
		var skills = gem_data.tower_skills
		
		for tower_type in tower_types:
			assert_has_key(skills, tower_type, gem_level + " 包含 " + tower_type + " 技能")
			var tower_skill = skills[tower_type]
			assert_has_key(tower_skill, "name", tower_type + " 技能有名称")
			assert_has_key(tower_skill, "description", tower_type + " 技能有描述")
			assert_has_key(tower_skill, "effects", tower_type + " 技有效果列表")
	
	print("✓ 冰宝石数据完整性测试通过")

func test_status_effect_system() -> void:
	print_section("状态效果系统测试")
	
	# 创建测试用的状态效果
	var test_effect = StatusEffect.new()
	
	# 测试冰霜效果设置
	test_effect.initialize(null, "frost", 4.0, 2)
	assert_equal(test_effect.effect_type, "frost", "冰霜效果类型正确")
	assert_equal(test_effect.max_stacks, 15, "冰霜效果最大层数正确")
	assert_has_key(test_effect.data, "slow_per_stack", "冰霜效果有减速数据")
	assert_has_key(test_effect.data, "damage_bonus", "冰霜效果有伤害加成数据")
	
	# 测试冻结效果设置
	var freeze_effect = StatusEffect.new()
	freeze_effect.initialize(null, "freeze", 2.0, 1)
	assert_equal(freeze_effect.effect_type, "freeze", "冻结效果类型正确")
	assert_equal(freeze_effect.max_stacks, 1, "冻结效果不能叠加")
	assert_has_key(freeze_effect.data, "freeze_damage_multiplier", "冻结效果有伤害倍率数据")
	
	# 测试效果应用和清理
	test_effect.cleanup_effect()
	freeze_effect.cleanup_effect()
	
	print("✓ 状态效果系统测试通过")

func test_gem_effect_system() -> void:
	print_section("宝石效果系统测试")
	
	# 创建宝石效果系统实例
	var gem_system = GemEffectSystem.new()
	add_child(gem_system)
	
	# 测试效果频率映射
	assert_has_key(GemEffectSystem.EFFECT_UPDATE_FREQUENCY, "freeze", "冻结效果有更新频率")
	assert_equal(GemEffectSystem.EFFECT_UPDATE_FREQUENCY["freeze"], "high_freq", "冻结效果为高频更新")
	assert_has_key(GemEffectSystem.EFFECT_UPDATE_FREQUENCY, "frost", "冰霜效果有更新频率")
	assert_equal(GemEffectSystem.EFFECT_UPDATE_FREQUENCY["frost"], "mid_freq", "冰霜效果为中频更新")
	
	# 测试冰元素特效方法
	assert_has_method(gem_system, "apply_frost_area", "有冰霜区域效果方法")
	assert_has_method(gem_system, "apply_chance_freeze", "有概率冻结效果方法")
	assert_has_method(gem_system, "is_target_frozen", "有冻结检查方法")
	assert_has_method(gem_system, "get_frost_stacks", "有冰霜层数获取方法")
	assert_has_method(gem_system, "apply_frozen_damage_bonus", "有冻结伤害加成方法")
	
	gem_system.queue_free()
	print("✓ 宝石效果系统测试通过")

func test_tower_integration() -> void:
	print_section("塔集成测试")
	
	# 创建测试塔实例
	var test_tower = Turret.new()
	add_child(test_tower)
	test_tower.turret_type = "arrow_tower"
	
	# 测试塔类型识别
	assert_equal(test_tower._get_tower_type_key(), "arrow_tower", "箭塔类型识别正确")
	
	# 测试冰宝石装备
	var ice_gem = Data.gems.ice_basic
	assert_true(test_tower.equip_gem(ice_gem), "可以装备基础冰宝石")
	assert_equal(test_tower.element, "ice", "装备冰宝石后元素正确")
	
	# 测试特殊效果处理器
	assert_has_method(test_tower, "_setup_frost_area_effect", "有冰霜区域效果处理器")
	assert_has_method(test_tower, "_setup_chance_freeze_effect", "有概率冻结效果处理器")
	assert_has_method(test_tower, "_setup_freeze_main_target_effect", "有主目标冻结效果处理器")
	assert_has_method(test_tower, "_setup_frost_aura_effect", "有冰霜光环效果处理器")
	
	# 测试冰元素伤害计算
	test_tower.current_target = Node.new()  # 模拟目标
	var base_damage = 100.0
	var final_damage = test_tower.calculate_final_damage(base_damage, "fire")
	assert_true(final_damage > base_damage, "冰元素对火元素有克制加成")
	
	test_tower.queue_free()
	print("✓ 塔集成测试通过")

func test_ice_element_effectiveness() -> void:
	print_section("冰元素克制测试")
	
	# 测试冰元素克制关系
	var effectiveness = ElementSystem.get_effectiveness_multiplier("ice", "fire")
	assert_equal(effectiveness, 1.5, "冰元素克制火元素 (+50%伤害)")
	
	effectiveness = ElementSystem.get_effectiveness_multiplier("ice", "wind")
	assert_equal(effectiveness, 0.75, "冰元素被风元素克制 (-25%伤害)")
	
	effectiveness = ElementSystem.get_effectiveness_multiplier("ice", "ice")
	assert_equal(effectiveness, 1.0, "同元素无克制效果")
	
	# 测试元素颜色
	var ice_color = ElementSystem.get_element_color("ice")
	assert_true(ice_color == Color.CYAN, "冰元素颜色正确")
	
	print("✓ 冰元素克制测试通过")

func test_performance_optimization() -> void:
	print_section("性能优化测试")
	
	# 创建效果池实例
	var effect_pool = EffectPool.new()
	add_child(effect_pool)
	
	# 测试对象池功能
	var effect1 = effect_pool.get_effect("frost")
	var effect2 = effect_pool.get_effect("freeze")
	
	assert_not_null(effect1, "可以从池中获取冰霜效果")
	assert_not_null(effect2, "可以从池中获取冻结效果")
	
	# 测试效果回收
	effect_pool.return_effect(effect1)
	effect_pool.return_effect(effect2)
	
	# 测试池统计
	var pool_stats = effect_pool.get_debug_info()
	assert_has_key(pool_stats, "pool_size", "效果池有大小统计")
	assert_has_key(pool_stats, "total_allocated", "效果池有分配统计")
	assert_has_key(pool_stats, "active_effects", "效果池有活跃效果统计")
	
	effect_pool.queue_free()
	print("✓ 性能优化测试通过")

# 辅助方法
func assert_has_key(dictionary: Dictionary, key: String, message: String) -> void:
	if not dictionary.has(key):
		test_failed(message + " - 缺少键: " + key)
	else:
		test_passed(message)

func assert_has_method(object: Object, method_name: String, message: String) -> void:
	if not object.has_method(method_name):
		test_failed(message + " - 缺少方法: " + method_name)
	else:
		test_passed(message)