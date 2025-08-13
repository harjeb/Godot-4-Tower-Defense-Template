extends Node

## 冰元素系统功能演示
## 展示冰元素宝石系统的核心功能

func _ready():
	print("=== 冰元素宝石系统功能演示 ===\n")
	
	# 演示冰宝石数据
	demonstrate_ice_gem_data()
	
	# 演示状态效果
	demonstrate_status_effects()
	
	# 演示塔集成
	demonstrate_tower_integration()
	
	# 演示元素克制
	demonstrate_element_effectiveness()
	
	print("\n=== 功能演示完成 ===")

func demonstrate_ice_gem_data():
	print_section("冰宝石数据演示")
	
	# 显示所有冰宝石
	var ice_gems = ["ice_basic", "ice_intermediate", "ice_advanced"]
	
	for gem_name in ice_gems:
		var gem_data = Data.gems[gem_name]
		print("\n" + gem_data["name"] + " (等级 " + str(gem_data["level"]) + ")")
		print("  元素: " + gem_data["element"])
		print("  伤害加成: " + str(gem_data["damage_bonus"] * 100) + "%")
		print("  塔技能:")
		
		for tower_type in gem_data["tower_skills"]:
			var skill = gem_data["tower_skills"][tower_type]
			print("    " + tower_type + ": " + skill["name"] + " - " + skill["description"])

func demonstrate_status_effects():
	print_section("冰霜状态效果演示")
	
	# 创建状态效果实例
	var frost_effect = StatusEffect.new()
	frost_effect.initialize(null, "frost", 4.0, 3)
	
	print("冰霜效果:")
	print("  类型: " + frost_effect.effect_type)
	print("  持续时间: " + str(frost_effect.duration) + " 秒")
	print("  层数: " + str(frost_effect.stacks))
	print("  最大层数: " + str(frost_effect.max_stacks))
	print("  每层减速: " + str(frost_effect.data["slow_per_stack"] * 100) + "%")
	print("  每层伤害加成: " + str(frost_effect.data["damage_bonus"] * 100) + "%")
	
	# 创建冻结效果实例
	var freeze_effect = StatusEffect.new()
	freeze_effect.initialize(null, "freeze", 2.0, 1)
	
	print("\n冻结效果:")
	print("  类型: " + freeze_effect.effect_type)
	print("  持续时间: " + str(freeze_effect.duration) + " 秒")
	print("  伤害倍率: " + str(freeze_effect.data["freeze_damage_multiplier"]) + "x")
	print("  是否可叠加: " + ("否" if freeze_effect.max_stacks == 1 else "是"))
	
	frost_effect.cleanup_effect()
	freeze_effect.cleanup_effect()

func demonstrate_tower_integration():
	print_section("塔集成演示")
	
	# 创建测试塔
	var test_tower = Turret.new()
	add_child(test_tower)
	test_tower.turret_type = "arrow_tower"
	
	print("创建箭塔:")
	print("  塔类型: " + test_tower.turret_type)
	print("  识别键: " + test_tower._get_tower_type_key())
	
	# 装备冰宝石
	var ice_gem = Data.gems.ice_basic
	var equipped = test_tower.equip_gem(ice_gem)
	
	print("\n装备冰宝石:")
	print("  装备成功: " + ("是" if equipped else "否"))
	print("  当前元素: " + test_tower.element)
	
	# 显示塔技能信息
	var gem_skills = test_tower.get_gem_skills_info()
	if gem_skills.size() >= 2:
		print("  技能名称: " + gem_skills[0])
		print("  技能描述: " + gem_skills[1])
	
	# 测试伤害计算
	test_tower.current_target = Node.new()  # 模拟目标
	var base_damage = 100.0
	var damage_to_fire = test_tower.calculate_final_damage(base_damage, "fire")
	var damage_to_wind = test_tower.calculate_final_damage(base_damage, "wind")
	
	print("\n伤害计算:")
	print("  基础伤害: " + str(base_damage))
	print("  对火元素伤害: " + str(damage_to_fire) + " (克制)")
	print("  对风元素伤害: " + str(damage_to_wind) + " (被克制)")
	
	test_tower.queue_free()

func demonstrate_element_effectiveness():
	print_section("元素克制演示")
	
	# 测试冰元素的克制关系
	var elements = ["fire", "water", "wind", "earth", "ice", "light", "dark"]
	
	print("冰元素克制关系:")
	for target_element in elements:
		var multiplier = ElementSystem.get_effectiveness_multiplier("ice", target_element)
		var relationship = ""
		if multiplier > 1.0:
			relationship = " (克制 +" + str((multiplier - 1.0) * 100) + "%)"
		elif multiplier < 1.0:
			relationship = " (被克制 -" + str((1.0 - multiplier) * 100) + "%)"
		else:
			relationship = " (平衡)"
		
		print("  冰 vs " + target_element + ": " + str(multiplier) + "x" + relationship)
	
	# 显示元素颜色
	var ice_color = ElementSystem.get_element_color("ice")
	print("\n冰元素颜色: " + str(ice_color))

func print_section(title: String):
	print("\n" + title)
	print("=".repeat(title.length()))