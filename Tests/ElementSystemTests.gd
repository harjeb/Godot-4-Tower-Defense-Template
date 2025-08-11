extends TestFramework
class_name ElementSystemTests

## 元素系统测试套件
## 测试7种元素的克制关系、伤害倍率计算、循环克制链和光暗互克关系

func run_all_tests() -> Dictionary:
	var tests = [
		{"name": "test_element_effectiveness_fire_wind", "func": test_element_effectiveness_fire_wind},
		{"name": "test_element_effectiveness_wind_earth", "func": test_element_effectiveness_wind_earth},
		{"name": "test_element_effectiveness_earth_fire", "func": test_element_effectiveness_earth_fire},
		{"name": "test_element_effectiveness_ice_fire", "func": test_element_effectiveness_ice_fire},
		{"name": "test_element_effectiveness_light_dark_mutual", "func": test_element_effectiveness_light_dark_mutual},
		{"name": "test_element_effectiveness_neutral", "func": test_element_effectiveness_neutral},
		{"name": "test_cyclic_effectiveness_chain", "func": test_cyclic_effectiveness_chain},
		{"name": "test_all_elements_data_integrity", "func": test_all_elements_data_integrity},
		{"name": "test_element_buff_calculation", "func": test_element_buff_calculation},
		{"name": "test_element_color_mapping", "func": test_element_color_mapping},
		{"name": "test_gem_element_validation", "func": test_gem_element_validation},
		{"name": "test_gem_crafting_logic", "func": test_gem_crafting_logic},
		{"name": "test_performance_effectiveness_calculation", "func": test_performance_effectiveness_calculation}
	]
	
	return run_test_suite("Element System Tests", tests)

# 测试火→风克制关系
func test_element_effectiveness_fire_wind():
	var multiplier = ElementSystem.get_effectiveness_multiplier("fire", "wind")
	assert_approximately(multiplier, 1.5, 0.001, "火克制风应该造成1.5倍伤害")
	
	# 反向测试
	var reverse_multiplier = ElementSystem.get_effectiveness_multiplier("wind", "fire")
	assert_approximately(reverse_multiplier, 0.75, 0.001, "风被火克制应该造成0.75倍伤害")

# 测试风→土克制关系
func test_element_effectiveness_wind_earth():
	var multiplier = ElementSystem.get_effectiveness_multiplier("wind", "earth")
	assert_approximately(multiplier, 1.5, 0.001, "风克制土应该造成1.5倍伤害")
	
	var reverse_multiplier = ElementSystem.get_effectiveness_multiplier("earth", "wind")
	assert_approximately(reverse_multiplier, 0.75, 0.001, "土被风克制应该造成0.75倍伤害")

# 测试土→火克制关系
func test_element_effectiveness_earth_fire():
	var multiplier = ElementSystem.get_effectiveness_multiplier("earth", "fire")
	assert_approximately(multiplier, 1.5, 0.001, "土克制火应该造成1.5倍伤害")
	
	var reverse_multiplier = ElementSystem.get_effectiveness_multiplier("fire", "earth")
	assert_approximately(reverse_multiplier, 0.75, 0.001, "火被土克制应该造成0.75倍伤害")

# 测试冰→火克制关系
func test_element_effectiveness_ice_fire():
	var multiplier = ElementSystem.get_effectiveness_multiplier("ice", "fire")
	assert_approximately(multiplier, 1.5, 0.001, "冰克制火应该造成1.5倍伤害")
	
	var reverse_multiplier = ElementSystem.get_effectiveness_multiplier("fire", "ice")
	assert_approximately(reverse_multiplier, 0.75, 0.001, "火被冰克制应该造成0.75倍伤害")

# 测试光暗互克关系
func test_element_effectiveness_light_dark_mutual():
	var light_vs_dark = ElementSystem.get_effectiveness_multiplier("light", "dark")
	assert_approximately(light_vs_dark, 1.5, 0.001, "光克制暗应该造成1.5倍伤害")
	
	var dark_vs_light = ElementSystem.get_effectiveness_multiplier("dark", "light")
	assert_approximately(dark_vs_light, 1.5, 0.001, "暗克制光应该造成1.5倍伤害")

# 测试中性元素
func test_element_effectiveness_neutral():
	var neutral_vs_fire = ElementSystem.get_effectiveness_multiplier("neutral", "fire")
	assert_approximately(neutral_vs_fire, 1.0, 0.001, "中性元素对火应该造成1.0倍伤害")
	
	var fire_vs_neutral = ElementSystem.get_effectiveness_multiplier("fire", "neutral")
	assert_approximately(fire_vs_neutral, 1.0, 0.001, "火对中性元素应该造成1.0倍伤害")
	
	var neutral_vs_neutral = ElementSystem.get_effectiveness_multiplier("neutral", "neutral")
	assert_approximately(neutral_vs_neutral, 1.0, 0.001, "中性元素对中性元素应该造成1.0倍伤害")

# 测试循环克制链：火→风→土→冰→火
func test_cyclic_effectiveness_chain():
	# 完整循环：火→风→土→冰→火
	assert_approximately(ElementSystem.get_effectiveness_multiplier("fire", "wind"), 1.5, 0.001, "火→风")
	assert_approximately(ElementSystem.get_effectiveness_multiplier("wind", "earth"), 1.5, 0.001, "风→土")
	assert_approximately(ElementSystem.get_effectiveness_multiplier("earth", "ice"), 1.5, 0.001, "土→冰")  # 注意：这可能需要更正Data.gd中的配置
	assert_approximately(ElementSystem.get_effectiveness_multiplier("ice", "fire"), 1.5, 0.001, "冰→火")
	
	# 验证反向都是被克制
	assert_approximately(ElementSystem.get_effectiveness_multiplier("wind", "fire"), 0.75, 0.001, "风被火克制")
	assert_approximately(ElementSystem.get_effectiveness_multiplier("earth", "wind"), 0.75, 0.001, "土被风克制")
	assert_approximately(ElementSystem.get_effectiveness_multiplier("ice", "earth"), 0.75, 0.001, "冰被土克制")
	assert_approximately(ElementSystem.get_effectiveness_multiplier("fire", "ice"), 0.75, 0.001, "火被冰克制")

# 测试所有元素数据完整性
func test_all_elements_data_integrity():
	var expected_elements = ["fire", "ice", "wind", "earth", "light", "dark", "neutral"]
	
	# 验证所有元素都在Data.elements中定义
	for element in expected_elements:
		assert_true(element in Data.elements, "元素 %s 应该在Data.elements中定义" % element)
		assert_has_key(Data.elements[element], "name", "元素 %s 应该有name属性" % element)
		assert_has_key(Data.elements[element], "color", "元素 %s 应该有color属性" % element)
	
	# 验证元素克制关系数据完整性
	for element in expected_elements:
		if element == "neutral":
			continue
		assert_true(element in Data.element_effectiveness, "元素 %s 应该在element_effectiveness中定义" % element)
		var effectiveness = Data.element_effectiveness[element]
		assert_has_key(effectiveness, "strong_against", "元素 %s 应该定义strong_against" % element)
		assert_has_key(effectiveness, "weak_against", "元素 %s 应该定义weak_against" % element)

# 测试元素BUFF计算
func test_element_buff_calculation():
	# 创建测试BUFF数组
	var buffs = [
		{"element_type": "fire", "bonus": 0.1},
		{"element_type": "fire", "bonus": 0.05},
		{"element_type": "ice", "bonus": 0.2},
		{"type": "damage", "bonus": 0.15}  # 非元素BUFF
	]
	
	var fire_buff = ElementSystem.get_element_buff("fire", buffs)
	assert_approximately(fire_buff, 0.15, 0.001, "火元素BUFF应该是0.1+0.05=0.15")
	
	var ice_buff = ElementSystem.get_element_buff("ice", buffs)
	assert_approximately(ice_buff, 0.2, 0.001, "冰元素BUFF应该是0.2")
	
	var wind_buff = ElementSystem.get_element_buff("wind", buffs)
	assert_approximately(wind_buff, 0.0, 0.001, "风元素BUFF应该是0.0")

# 测试元素颜色映射
func test_element_color_mapping():
	var fire_color = ElementSystem.get_element_color("fire")
	assert_not_null(fire_color, "火元素应该有颜色定义")
	assert_equal(fire_color, Color.RED, "火元素颜色应该是红色")
	
	var unknown_color = ElementSystem.get_element_color("unknown")
	assert_equal(unknown_color, Color.WHITE, "未知元素应该返回白色")

# 测试宝石元素验证
func test_gem_element_validation():
	# 测试有效宝石
	assert_true(ElementSystem.is_valid_gem("fire_basic"), "fire_basic应该是有效宝石")
	assert_true(ElementSystem.is_valid_gem("ice_intermediate"), "ice_intermediate应该是有效宝石")
	assert_true(ElementSystem.is_valid_gem("dark_advanced"), "dark_advanced应该是有效宝石")
	
	# 测试无效宝石
	assert_false(ElementSystem.is_valid_gem("invalid_gem"), "invalid_gem应该是无效宝石")
	assert_false(ElementSystem.is_valid_gem("fire_master"), "fire_master应该是无效宝石")
	
	# 测试宝石元素获取
	assert_equal(ElementSystem.get_gem_element("fire_basic"), "fire", "fire_basic的元素应该是fire")
	assert_equal(ElementSystem.get_gem_element("invalid_gem"), "neutral", "无效宝石应该返回neutral")

# 测试宝石合成逻辑
func test_gem_crafting_logic():
	# 创建测试背包
	var test_inventory = [
		{"id": "fire_basic", "quantity": 3},
		{"id": "ice_basic", "quantity": 1},
		{"id": "wind_intermediate", "quantity": 2}
	]
	
	# 测试可以合成的情况
	assert_true(ElementSystem.can_craft_gem("fire", 1, test_inventory), "应该可以合成fire_intermediate")
	assert_true(ElementSystem.can_craft_gem("wind", 2, test_inventory), "应该可以合成wind_advanced")
	
	# 测试不能合成的情况
	assert_false(ElementSystem.can_craft_gem("ice", 1, test_inventory), "不应该能合成ice_intermediate（只有1个basic）")
	assert_false(ElementSystem.can_craft_gem("fire", 3, test_inventory), "不应该能合成超过最大等级的宝石")
	
	# 测试获取下一级宝石
	assert_equal(ElementSystem.get_next_level_gem("fire_basic"), "fire_intermediate", "fire_basic的下一级应该是fire_intermediate")
	assert_equal(ElementSystem.get_next_level_gem("ice_intermediate"), "ice_advanced", "ice_intermediate的下一级应该是ice_advanced")
	assert_equal(ElementSystem.get_next_level_gem("wind_advanced"), "", "wind_advanced应该没有下一级")

# 性能测试：效力计算
func test_performance_effectiveness_calculation():
	var test_func = func():
		ElementSystem.get_effectiveness_multiplier("fire", "wind")
		ElementSystem.get_effectiveness_multiplier("ice", "fire")
		ElementSystem.get_effectiveness_multiplier("light", "dark")
		ElementSystem.get_effectiveness_multiplier("neutral", "earth")
	
	var benchmark_result = benchmark_function("effectiveness_calculation", test_func, 10000)
	
	# 性能断言：平均每次计算应该少于0.01ms
	assert_true(benchmark_result.average_duration < 0.01, 
		"效力计算平均耗时应该少于0.01ms，实际: %.4fms" % benchmark_result.average_duration)