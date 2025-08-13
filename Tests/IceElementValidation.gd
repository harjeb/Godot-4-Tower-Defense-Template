extends TestFramework
class_name IceElementValidation

## 冰元素系统验证脚本
## 验证冰元素宝石系统的完整性和功能

func _ready():
	super._ready()
	test_name = "冰元素系统验证"

func run_validation() -> void:
	print("=== 开始冰元素系统验证 ===")
	
	validate_data_integrity()
	validate_status_effects()
	validate_gem_effects()
	validate_tower_integration()
	validate_element_system()
	
	print("=== 冰元素系统验证完成 ===")

func validate_data_integrity() -> void:
	print_section("数据完整性验证")
	
	# 验证冰宝石数据
	var ice_gems = ["ice_basic", "ice_intermediate", "ice_advanced"]
	for gem_name in ice_gems:
		assert_not_null(Data.gems.get(gem_name), gem_name + " 宝石数据存在")
		var gem_data = Data.gems[gem_name]
		assert_equal(gem_data.element, "ice", gem_name + " 元素类型正确")
		assert_has_key(gem_data, "tower_skills", gem_name + " 有塔技能数据")
		
		# 验证每种塔类型都有技能定义
		var tower_skills = gem_data.tower_skills
		var expected_towers = ["arrow_tower", "capture_tower", "mage_tower", "感应塔", "末日塔", "pulse_tower", "弹射塔", "aura_tower", "weakness_tower"]
		
		for tower_type in expected_towers:
			assert_has_key(tower_skills, tower_type, gem_name + " 包含 " + tower_type + " 技能")
			var skill = tower_skills[tower_type]
			assert_has_key(skill, "name", tower_type + " 技能有名称")
			assert_has_key(skill, "description", tower_type + " 技能有描述")
			assert_has_key(skill, "effects", tower_type + " 技有效果列表")
	
	# 验证冰元素效果定义
	var ice_effects = [
		"frost_debuff_1", "frost_debuff_2", "frost_debuff_3",
		"frost_area_1", "frost_on_bounce_1", "frost_debuff_2_area", "frost_debuff_3_area",
		"freeze_chance_15_1s", "freeze_chance_20_0.5s", "freeze_chance_10_1s",
		"freeze_chance_20_0.5s_bounce", "freeze_main_2s", "freeze_on_end_1.5s",
		"freeze_on_end_5s", "freeze_stealth_1s", "freeze_on_death",
		"freeze_duration_20", "frost_ground_3s", "frost_damage_boost_30"
	]
	
	for effect_name in ice_effects:
		assert_has_key(Data.effects, effect_name, effect_name + " 效果定义存在")
		var effect_data = Data.effects[effect_name]
		assert_has_key(effect_data, "type", effect_name + " 有效果类型")
	
	print("✓ 数据完整性验证通过")

func validate_status_effects() -> void:
	print_section("状态效果系统验证")
	
	# 创建状态效果实例进行测试
	var frost_effect = StatusEffect.new()
	frost_effect.initialize(null, "frost", 4.0, 2)
	
	assert_equal(frost_effect.effect_type, "frost", "冰霜效果类型正确")
	assert_equal(frost_effect.max_stacks, 15, "冰霜效果最大层数正确")
	assert_has_key(frost_effect.data, "slow_per_stack", "冰霜效果有减速数据")
	assert_has_key(frost_effect.data, "damage_bonus", "冰霜效果有伤害加成数据")
	
	# 测试冻结效果
	var freeze_effect = StatusEffect.new()
	freeze_effect.initialize(null, "freeze", 2.0, 1)
	
	assert_equal(freeze_effect.effect_type, "freeze", "冻结效果类型正确")
	assert_equal(freeze_effect.max_stacks, 1, "冻结效果不能叠加")
	assert_has_key(freeze_effect.data, "freeze_damage_multiplier", "冻结效果有伤害倍率数据")
	
	# 清理效果
	frost_effect.cleanup_effect()
	freeze_effect.cleanup_effect()
	
	print("✓ 状态效果系统验证通过")

func validate_gem_effects() -> void:
	print_section("宝石效果系统验证")
	
	# 创建宝石效果系统实例
	var gem_system = GemEffectSystem.new()
	add_child(gem_system)
	
	# 验证效果频率映射
	assert_has_key(GemEffectSystem.EFFECT_UPDATE_FREQUENCY, "freeze", "冻结效果有更新频率")
	assert_equal(GemEffectSystem.EFFECT_UPDATE_FREQUENCY["freeze"], "high_freq", "冻结效果为高频更新")
	assert_has_key(GemEffectSystem.EFFECT_UPDATE_FREQUENCY, "frost", "冰霜效果有更新频率")
	assert_equal(GemEffectSystem.EFFECT_UPDATE_FREQUENCY["frost"], "mid_freq", "冰霜效果为中频更新")
	
	# 验证冰元素特效方法
	var ice_methods = [
		"apply_frost_area", "apply_chance_freeze", "is_target_frozen",
		"get_frost_stacks", "apply_frozen_damage_bonus", "apply_frost_aura",
		"get_enemies_in_area", "apply_frost_on_bounce"
	]
	
	for method_name in ice_methods:
		assert_has_method(gem_system, method_name, "有 " + method_name + " 方法")
	
	gem_system.queue_free()
	print("✓ 宝石效果系统验证通过")

func validate_tower_integration() -> void:
	print_section("塔集成验证")
	
	# 创建测试塔实例
	var test_tower = Turret.new()
	add_child(test_tower)
	test_tower.turret_type = "arrow_tower"
	
	# 验证塔类型识别
	assert_equal(test_tower._get_tower_type_key(), "arrow_tower", "箭塔类型识别正确")
	
	# 验证冰宝石装备
	var ice_gem = Data.gems.ice_basic
	assert_true(test_tower.equip_gem(ice_gem), "可以装备基础冰宝石")
	assert_equal(test_tower.element, "ice", "装备冰宝石后元素正确")
	
	# 验证特殊效果处理器
	var ice_effect_handlers = [
		"_setup_frost_area_effect", "_setup_frost_bounce_effect", "_setup_frost_aura_effect",
		"_setup_chance_freeze_effect", "_setup_freeze_main_target_effect",
		"_setup_freeze_on_end_effect", "_setup_freeze_stealth_effect",
		"_setup_frozen_damage_multiplier_effect"
	]
	
	for handler_name in ice_effect_handlers:
		assert_has_method(test_tower, handler_name, "有 " + handler_name + " 处理器")
	
	# 验证冰元素伤害计算
	test_tower.current_target = Node.new()  # 模拟目标
	var base_damage = 100.0
	var final_damage = test_tower.calculate_final_damage(base_damage, "fire")
	assert_true(final_damage > base_damage, "冰元素对火元素有克制加成")
	
	test_tower.queue_free()
	print("✓ 塔集成验证通过")

func validate_element_system() -> void:
	print_section("元素系统验证")
	
	# 验证冰元素克制关系
	var effectiveness = ElementSystem.get_effectiveness_multiplier("ice", "fire")
	assert_equal(effectiveness, 1.5, "冰元素克制火元素 (+50%伤害)")
	
	effectiveness = ElementSystem.get_effectiveness_multiplier("ice", "wind")
	assert_equal(effectiveness, 0.75, "冰元素被风元素克制 (-25%伤害)")
	
	effectiveness = ElementSystem.get_effectiveness_multiplier("ice", "ice")
	assert_equal(effectiveness, 1.0, "同元素无克制效果")
	
	# 验证元素颜色
	var ice_color = ElementSystem.get_element_color("ice")
	assert_true(ice_color == Color.CYAN, "冰元素颜色正确")
	
	print("✓ 元素系统验证通过")

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