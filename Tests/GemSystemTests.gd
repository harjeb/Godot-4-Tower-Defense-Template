extends TestFramework
class_name GemSystemTests

## 宝石系统测试套件
## 测试21种宝石数据完整性、2合1合成机制、装备功能和伤害BUFF计算

func run_all_tests() -> Dictionary:
	var tests = [
		{"name": "test_gem_data_integrity", "func": test_gem_data_integrity},
		{"name": "test_all_gem_elements_coverage", "func": test_all_gem_elements_coverage},
		{"name": "test_gem_level_progression", "func": test_gem_level_progression},
		{"name": "test_gem_damage_bonus_scaling", "func": test_gem_damage_bonus_scaling},
		{"name": "test_gem_crafting_two_to_one", "func": test_gem_crafting_two_to_one},
		{"name": "test_gem_crafting_validation", "func": test_gem_crafting_validation},
		{"name": "test_gem_crafting_edge_cases", "func": test_gem_crafting_edge_cases},
		{"name": "test_inventory_gem_management", "func": test_inventory_gem_management},
		{"name": "test_turret_gem_equipping", "func": test_turret_gem_equipping},
		{"name": "test_gem_damage_calculation", "func": test_gem_damage_calculation},
		{"name": "test_gem_element_assignment", "func": test_gem_element_assignment},
		{"name": "test_performance_gem_operations", "func": test_performance_gem_operations}
	]
	
	return run_test_suite("Gem System Tests", tests)

# 测试21种宝石数据完整性
func test_gem_data_integrity():
	var expected_gem_count = 21
	var actual_gem_count = Data.gems.size()
	assert_equal(actual_gem_count, expected_gem_count, "应该有21种宝石定义")
	
	# 验证每种宝石的必要属性
	for gem_id in Data.gems.keys():
		var gem_data = Data.gems[gem_id]
		
		# 必要属性检查
		assert_has_key(gem_data, "name", "宝石 %s 应该有name属性" % gem_id)
		assert_has_key(gem_data, "element", "宝石 %s 应该有element属性" % gem_id)
		assert_has_key(gem_data, "level", "宝石 %s 应该有level属性" % gem_id)
		assert_has_key(gem_data, "damage_bonus", "宝石 %s 应该有damage_bonus属性" % gem_id)
		assert_has_key(gem_data, "sprite", "宝石 %s 应该有sprite属性" % gem_id)
		
		# 属性值有效性检查
		assert_true(gem_data.level >= 1 and gem_data.level <= 3, "宝石 %s 的等级应该在1-3之间" % gem_id)
		assert_true(gem_data.damage_bonus > 0.0, "宝石 %s 的伤害加成应该大于0" % gem_id)
		assert_true(gem_data.element in Data.elements, "宝石 %s 的元素应该是有效的" % gem_id)

# 测试所有元素的宝石覆盖
func test_all_gem_elements_coverage():
	var elements = ["fire", "ice", "wind", "earth", "light", "dark"]
	var levels = [1, 2, 3]
	
	for element in elements:
		for level in levels:
			var gem_id = "%s_%s" % [element, ElementSystem.get_level_name(level)]
			assert_true(gem_id in Data.gems, "应该存在宝石: %s" % gem_id)
			
			var gem_data = Data.gems[gem_id]
			assert_equal(gem_data.element, element, "宝石 %s 的元素应该是 %s" % [gem_id, element])
			assert_equal(gem_data.level, level, "宝石 %s 的等级应该是 %d" % [gem_id, level])

# 测试宝石等级递进
func test_gem_level_progression():
	var elements = ["fire", "ice", "wind", "earth", "light", "dark"]
	
	for element in elements:
		var basic_id = "%s_basic" % element
		var intermediate_id = "%s_intermediate" % element  
		var advanced_id = "%s_advanced" % element
		
		# 确保三个等级都存在
		assert_true(basic_id in Data.gems, "应该存在初级宝石: %s" % basic_id)
		assert_true(intermediate_id in Data.gems, "应该存在中级宝石: %s" % intermediate_id)
		assert_true(advanced_id in Data.gems, "应该存在高级宝石: %s" % advanced_id)
		
		# 检查等级正确性
		assert_equal(Data.gems[basic_id].level, 1, "%s 应该是1级" % basic_id)
		assert_equal(Data.gems[intermediate_id].level, 2, "%s 应该是2级" % intermediate_id)
		assert_equal(Data.gems[advanced_id].level, 3, "%s 应该是3级" % advanced_id)

# 测试宝石伤害加成递增
func test_gem_damage_bonus_scaling():
	var elements = ["fire", "ice", "wind", "earth", "light", "dark"]
	var expected_bonuses = [0.10, 0.20, 0.35]  # basic, intermediate, advanced
	
	for element in elements:
		var gems = [
			"%s_basic" % element,
			"%s_intermediate" % element,
			"%s_advanced" % element
		]
		
		for i in range(gems.size()):
			var gem_id = gems[i]
			var expected_bonus = expected_bonuses[i]
			var actual_bonus = Data.gems[gem_id].damage_bonus
			
			assert_approximately(actual_bonus, expected_bonus, 0.001, 
				"宝石 %s 的伤害加成应该是 %.2f" % [gem_id, expected_bonus])
		
		# 确保伤害加成是递增的
		var basic_bonus = Data.gems[gems[0]].damage_bonus
		var intermediate_bonus = Data.gems[gems[1]].damage_bonus
		var advanced_bonus = Data.gems[gems[2]].damage_bonus
		
		assert_true(basic_bonus < intermediate_bonus, "%s 的加成应该小于 %s" % [gems[0], gems[1]])
		assert_true(intermediate_bonus < advanced_bonus, "%s 的加成应该小于 %s" % [gems[1], gems[2]])

# 测试2合1合成机制
func test_gem_crafting_two_to_one():
	# 创建测试背包管理器
	var inventory_manager = InventoryManager.new()
	
	# 添加足够的基础宝石进行合成
	inventory_manager.add_item("fire_basic", 2)
	
	# 测试合成条件检查
	var can_craft = ElementSystem.can_craft_gem("fire", 1, inventory_manager.get_inventory_data())
	assert_true(can_craft, "有2个fire_basic时应该能合成fire_intermediate")
	
	# 执行合成
	var craft_result = inventory_manager.craft_gem("fire", 1)
	assert_true(craft_result, "合成应该成功")
	
	# 验证合成后的物品变化
	assert_equal(inventory_manager.get_item_count("fire_basic"), 0, "合成后应该消耗2个fire_basic")
	assert_equal(inventory_manager.get_item_count("fire_intermediate"), 1, "合成后应该得到1个fire_intermediate")
	
	inventory_manager.queue_free()

# 测试合成验证逻辑
func test_gem_crafting_validation():
	var inventory_manager = InventoryManager.new()
	
	# 测试材料不足的情况
	inventory_manager.add_item("ice_basic", 1)
	var cannot_craft = not ElementSystem.can_craft_gem("ice", 1, inventory_manager.get_inventory_data())
	assert_true(cannot_craft, "只有1个ice_basic时不应该能合成")
	
	# 测试超过最大等级的情况
	inventory_manager.add_item("wind_advanced", 2)
	var cannot_craft_max_level = not ElementSystem.can_craft_gem("wind", 3, inventory_manager.get_inventory_data())
	assert_true(cannot_craft_max_level, "不应该能合成超过3级的宝石")
	
	# 测试无效元素
	var cannot_craft_invalid = not ElementSystem.can_craft_gem("invalid", 1, inventory_manager.get_inventory_data())
	assert_true(cannot_craft_invalid, "不应该能合成无效元素的宝石")
	
	inventory_manager.queue_free()

# 测试合成边界情况
func test_gem_crafting_edge_cases():
	var inventory_manager = InventoryManager.new()
	
	# 测试刚好足够的材料
	inventory_manager.add_item("earth_basic", 2)
	assert_true(inventory_manager.craft_gem("earth", 1), "刚好2个材料应该能合成")
	
	# 测试材料过多的情况
	inventory_manager.clear_inventory()
	inventory_manager.add_item("light_intermediate", 3)
	assert_true(inventory_manager.craft_gem("light", 2), "有3个材料时也应该能合成，消耗2个")
	assert_equal(inventory_manager.get_item_count("light_intermediate"), 1, "应该剩余1个材料")
	assert_equal(inventory_manager.get_item_count("light_advanced"), 1, "应该得到1个高级宝石")
	
	inventory_manager.queue_free()

# 测试背包管理器的宝石管理功能
func test_inventory_gem_management():
	var inventory_manager = InventoryManager.new()
	
	# 测试添加不同等级的宝石
	inventory_manager.add_item("fire_basic", 3)
	inventory_manager.add_item("fire_intermediate", 2)
	inventory_manager.add_item("ice_basic", 1)
	
	# 测试按元素查找宝石
	var fire_gems = inventory_manager.get_gems_by_element("fire")
	assert_equal(fire_gems.size(), 2, "应该找到2种火元素宝石")
	
	var ice_gems = inventory_manager.get_gems_by_element("ice")
	assert_equal(ice_gems.size(), 1, "应该找到1种冰元素宝石")
	
	var wind_gems = inventory_manager.get_gems_by_element("wind")
	assert_equal(wind_gems.size(), 0, "应该找到0种风元素宝石")
	
	# 测试可合成宝石列表
	var craftable = inventory_manager.get_craftable_gems()
	var found_fire_craft = false
	for craft_info in craftable:
		if craft_info.element == "fire" and craft_info.level == 1:
			found_fire_craft = true
			break
	assert_true(found_fire_craft, "应该能检测到fire_basic可以合成")
	
	inventory_manager.queue_free()

# 测试炮塔宝石装备功能
func test_turret_gem_equipping():
	# 创建测试炮塔
	var turret = Node2D.new()
	turret.set_script(preload("res://Scenes/turrets/turretBase/turret_base.gd"))
	turret.element = "neutral"
	turret.equipped_gem = {}
	
	# 创建测试宝石数据
	var gem_data = create_mock_gem_data("fire", 2)
	
	# 测试装备宝石
	turret.equip_gem(gem_data)
	
	assert_false(turret.equipped_gem.is_empty(), "炮塔应该装备了宝石")
	assert_equal(turret.element, "fire", "炮塔元素应该变成宝石的元素")
	assert_true(turret.has_gem_equipped(), "has_gem_equipped()应该返回true")
	
	# 测试卸下宝石
	turret.unequip_gem()
	
	assert_true(turret.equipped_gem.is_empty(), "卸下后炮塔不应该有装备宝石")
	assert_equal(turret.element, "neutral", "卸下后炮塔元素应该恢复为neutral")
	assert_false(turret.has_gem_equipped(), "卸下后has_gem_equipped()应该返回false")
	
	turret.queue_free()

# 测试宝石伤害计算
func test_gem_damage_calculation():
	# 创建测试炮塔
	var turret = Node2D.new()
	turret.set_script(preload("res://Scenes/turrets/turretBase/turret_base.gd"))
	turret.equipped_gem = {}
	turret.element = "neutral"
	turret.turret_category = "projectile"
	
	# 基础伤害测试
	var base_damage = 100.0
	var target_element = "neutral"
	var damage_without_gem = turret.calculate_final_damage(base_damage, target_element)
	
	# 装备火宝石
	var fire_gem = create_mock_gem_data("fire", 2)  # 20%加成
	turret.equip_gem(fire_gem)
	
	var damage_with_gem = turret.calculate_final_damage(base_damage, target_element)
	
	# 宝石加成应该增加伤害
	assert_true(damage_with_gem > damage_without_gem, "装备宝石后伤害应该增加")
	
	# 测试对风元素敌人的克制伤害（火克制风）
	var damage_vs_wind = turret.calculate_final_damage(base_damage, "wind")
	assert_true(damage_vs_wind > damage_with_gem, "火元素对风元素应该有克制加成")
	
	turret.queue_free()

# 测试宝石元素分配
func test_gem_element_assignment():
	var elements = ["fire", "ice", "wind", "earth", "light", "dark"]
	
	for element in elements:
		var gem_id = "%s_basic" % element
		
		# 测试ElementSystem的元素获取
		var gem_element = ElementSystem.get_gem_element(gem_id)
		assert_equal(gem_element, element, "宝石 %s 的元素应该是 %s" % [gem_id, element])
		
		# 测试无效宝石
		var invalid_element = ElementSystem.get_gem_element("invalid_gem")
		assert_equal(invalid_element, "neutral", "无效宝石应该返回neutral元素")

# 性能测试：宝石操作
func test_performance_gem_operations():
	# 测试宝石验证性能
	var validation_test = func():
		ElementSystem.is_valid_gem("fire_basic")
		ElementSystem.is_valid_gem("ice_intermediate")  
		ElementSystem.is_valid_gem("wind_advanced")
		ElementSystem.is_valid_gem("invalid_gem")
	
	var validation_benchmark = benchmark_function("gem_validation", validation_test, 10000)
	assert_true(validation_benchmark.average_duration < 0.01,
		"宝石验证平均耗时应该少于0.01ms，实际: %.4fms" % validation_benchmark.average_duration)
	
	# 测试合成检查性能
	var inventory = [
		{"id": "fire_basic", "quantity": 2},
		{"id": "ice_basic", "quantity": 1},
		{"id": "wind_intermediate", "quantity": 3}
	]
	
	var crafting_test = func():
		ElementSystem.can_craft_gem("fire", 1, inventory)
		ElementSystem.can_craft_gem("ice", 1, inventory)
		ElementSystem.can_craft_gem("wind", 2, inventory)
		ElementSystem.can_craft_gem("earth", 1, inventory)
	
	var crafting_benchmark = benchmark_function("gem_crafting_check", crafting_test, 5000)
	assert_true(crafting_benchmark.average_duration < 0.05,
		"合成检查平均耗时应该少于0.05ms，实际: %.4fms" % crafting_benchmark.average_duration)
	
	# 测试背包管理器性能
	var inventory_manager = InventoryManager.new()
	
	var inventory_test = func():
		inventory_manager.add_item("fire_basic", 1)
		inventory_manager.get_gems_by_element("fire")
		inventory_manager.get_item_count("fire_basic")
		inventory_manager.remove_item("fire_basic", 1)
	
	var inventory_benchmark = benchmark_function("inventory_operations", inventory_test, 1000)
	assert_true(inventory_benchmark.average_duration < 0.1,
		"背包操作平均耗时应该少于0.1ms，实际: %.4fms" % inventory_benchmark.average_duration)
	
	inventory_manager.queue_free()