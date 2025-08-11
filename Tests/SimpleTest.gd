@tool
extends SceneTree

func _init():
	print("塔防游戏增强系统基础测试")
	print("==================================================")
	
	# 基础数据检查
	test_basic_data()
	
	# 元素系统测试
	test_element_system()
	
	print("==================================================")
	print("基础测试完成！")
	quit()

func test_basic_data():
	print("测试基础数据...")
	
	# 检查自动加载是否正常工作
	if Data:
		print("✓ Data 自动加载正常")
	else:
		print("✗ Data 自动加载失败")
	
	if ElementSystem:
		print("✓ ElementSystem 自动加载正常") 
	else:
		print("✗ ElementSystem 自动加载失败")
	
	if LootSystem:
		print("✓ LootSystem 自动加载正常")
	else:
		print("✗ LootSystem 自动加载失败")

func test_element_system():
	print("测试元素系统...")
	
	# 测试元素克制关系
	var fire_vs_wind = ElementSystem.get_effectiveness_multiplier("fire", "wind")
	if fire_vs_wind == 1.5:
		print("✓ 火克制风：", fire_vs_wind, "x")
	else:
		print("✗ 火克制风失败，期望1.5，得到：", fire_vs_wind)
	
	var ice_vs_fire = ElementSystem.get_effectiveness_multiplier("ice", "fire")  
	if ice_vs_fire == 1.5:
		print("✓ 冰克制火：", ice_vs_fire, "x")
	else:
		print("✗ 冰克制火失败，期望1.5，得到：", ice_vs_fire)
	
	var neutral_test = ElementSystem.get_effectiveness_multiplier("neutral", "fire")
	if neutral_test == 1.0:
		print("✓ 无属性中性：", neutral_test, "x") 
	else:
		print("✗ 无属性中性失败，期望1.0，得到：", neutral_test)
	
	# 测试宝石数据
	if Data.gems and Data.gems.size() > 0:
		print("✓ 宝石数据已加载，数量：", Data.gems.size())
		
		# 检查火属性初级宝石
		if "fire_basic" in Data.gems:
			var gem = Data.gems.fire_basic
			print("✓ 火属性初级宝石：", gem.name, " - ", gem.damage_bonus, "%")
		else:
			print("✗ 缺少火属性初级宝石")
	else:
		print("✗ 宝石数据未加载")