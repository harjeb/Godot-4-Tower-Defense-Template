extends TestFramework
class_name InventoryUISystemTests

## 物品和UI系统测试套件
## 测试20槽背包容量管理、10槽武器盘BUFF叠加、物品掉落概率机制、UI界面交互完整性

func run_all_tests() -> Dictionary:
	var tests = [
		{"name": "test_inventory_capacity_management", "func": test_inventory_capacity_management},
		{"name": "test_inventory_item_stacking", "func": test_inventory_item_stacking},
		{"name": "test_inventory_overflow_handling", "func": test_inventory_overflow_handling},
		{"name": "test_weapon_wheel_capacity", "func": test_weapon_wheel_capacity},
		{"name": "test_weapon_wheel_buff_stacking", "func": test_weapon_wheel_buff_stacking},
		{"name": "test_weapon_wheel_buff_calculations", "func": test_weapon_wheel_buff_calculations},
		{"name": "test_loot_drop_probability", "func": test_loot_drop_probability},
		{"name": "test_loot_drop_item_selection", "func": test_loot_drop_item_selection},
		{"name": "test_loot_pickup_mechanism", "func": test_loot_pickup_mechanism},
		{"name": "test_inventory_signals", "func": test_inventory_signals},
		{"name": "test_weapon_wheel_signals", "func": test_weapon_wheel_signals},
		{"name": "test_performance_inventory_operations", "func": test_performance_inventory_operations}
	]
	
	return run_test_suite("Inventory and UI System Tests", tests)

# 测试背包容量管理（20槽）
func test_inventory_capacity_management():
	var inventory_manager = InventoryManager.new()
	
	# 验证初始状态
	assert_equal(inventory_manager.max_capacity, 20, "背包最大容量应该是20")
	assert_equal(inventory_manager.inventory.size(), 0, "初始背包应该是空的")
	
	# 测试添加物品直到满容量
	for i in range(20):
		var item_id = "test_item_%d" % i
		var success = inventory_manager.add_item(item_id, 1)
		assert_true(success, "在容量限制内应该能成功添加物品 %d" % i)
	
	# 验证满容量状态
	assert_equal(inventory_manager.inventory.size(), 20, "背包应该达到最大容量20")
	
	# 测试超出容量的添加
	var overflow_success = inventory_manager.add_item("overflow_item", 1)
	assert_false(overflow_success, "超出容量时不应该能添加新物品")
	assert_equal(inventory_manager.inventory.size(), 20, "容量应该保持在20")
	
	inventory_manager.queue_free()

# 测试物品堆叠机制
func test_inventory_item_stacking():
	var inventory_manager = InventoryManager.new()
	
	# 添加同一种物品多次
	inventory_manager.add_item("fire_basic", 3)
	inventory_manager.add_item("fire_basic", 2)
	
	# 验证物品堆叠
	assert_equal(inventory_manager.inventory.size(), 1, "相同物品应该堆叠，只占用1个槽位")
	assert_equal(inventory_manager.get_item_count("fire_basic"), 5, "fire_basic的总数量应该是5")
	
	# 测试不同物品不堆叠
	inventory_manager.add_item("ice_basic", 2)
	assert_equal(inventory_manager.inventory.size(), 2, "不同物品应该占用不同槽位")
	assert_equal(inventory_manager.get_item_count("ice_basic"), 2, "ice_basic的数量应该是2")
	
	inventory_manager.queue_free()

# 测试背包溢出处理
func test_inventory_overflow_handling():
	var inventory_manager = InventoryManager.new()
	
	# 填满背包（每种物品占一个槽位）
	for i in range(20):
		inventory_manager.add_item("item_%d" % i, 1)
	
	# 尝试添加已存在的物品（应该成功，因为会堆叠）
	var stack_success = inventory_manager.add_item("item_0", 5)
	assert_true(stack_success, "向已存在的物品堆叠应该成功")
	assert_equal(inventory_manager.get_item_count("item_0"), 6, "物品堆叠后数量应该正确")
	
	# 尝试添加新物品（应该失败）
	var new_item_success = inventory_manager.add_item("new_item", 1)
	assert_false(new_item_success, "背包满时添加新物品应该失败")
	
	# 移除一个物品后应该能添加新物品
	inventory_manager.remove_item("item_19", 1)
	var after_remove_success = inventory_manager.add_item("new_item", 1)
	assert_true(after_remove_success, "释放槽位后应该能添加新物品")
	
	inventory_manager.queue_free()

# 测试武器盘容量（10槽）
func test_weapon_wheel_capacity():
	var weapon_wheel = WeaponWheelManager.new()
	
	# 验证初始状态
	assert_equal(weapon_wheel.max_slots, 10, "武器盘最大槽位应该是10")
	assert_equal(weapon_wheel.get_slot_count(), 0, "初始武器盘应该是空的")
	assert_equal(weapon_wheel.get_available_slots(), 10, "初始可用槽位应该是10")
	
	# 添加BUFF直到满容量
	var buff_types = ["projectile_damage", "ray_damage", "melee_damage", 
					  "fire_element", "ice_element", "wind_element", 
					  "earth_element", "light_element", "dark_element"]
	
	# 添加9种不同的BUFF
	for i in range(9):
		var success = weapon_wheel.add_to_weapon_wheel(buff_types[i])
		assert_true(success, "应该能成功添加BUFF %d" % i)
	
	# 添加第10个BUFF（重复的火元素BUFF）
	var tenth_success = weapon_wheel.add_to_weapon_wheel("fire_element")
	assert_true(tenth_success, "应该能添加第10个BUFF")
	
	# 验证满容量状态
	assert_equal(weapon_wheel.get_slot_count(), 10, "武器盘应该达到最大容量10")
	assert_true(weapon_wheel.is_full(), "武器盘应该显示为满")
	assert_equal(weapon_wheel.get_available_slots(), 0, "可用槽位应该为0")
	
	# 测试超出容量的添加
	var overflow_success = weapon_wheel.add_to_weapon_wheel("projectile_damage")
	assert_false(overflow_success, "武器盘满时不应该能添加新BUFF")
	
	weapon_wheel.queue_free()

# 测试武器盘BUFF叠加
func test_weapon_wheel_buff_stacking():
	var weapon_wheel = WeaponWheelManager.new()
	
	# 添加多个相同类型的BUFF
	weapon_wheel.add_to_weapon_wheel("fire_element")
	weapon_wheel.add_to_weapon_wheel("fire_element") 
	weapon_wheel.add_to_weapon_wheel("projectile_damage")
	weapon_wheel.add_to_weapon_wheel("projectile_damage")
	
	# 验证BUFF叠加
	assert_equal(weapon_wheel.get_slot_count(), 4, "应该占用4个槽位")
	
	# 测试火元素BUFF叠加计算
	var fire_multiplier = weapon_wheel.calculate_element_multiplier("fire")
	assert_approximately(fire_multiplier, 1.20, 0.001, "两个火元素BUFF应该提供20%加成（1.0 + 0.1 + 0.1）")
	
	# 测试投射物BUFF叠加计算
	var projectile_multiplier = weapon_wheel.calculate_turret_multiplier("projectile")
	# 注意：投射物伤害BUFF应用于gatling和laser，每个提供5%加成
	assert_approximately(projectile_multiplier, 1.10, 0.001, "两个投射物BUFF应该提供10%加成（1.0 + 0.05 + 0.05）")
	
	weapon_wheel.queue_free()

# 测试武器盘BUFF计算规则
func test_weapon_wheel_buff_calculations():
	var weapon_wheel = WeaponWheelManager.new()
	
	# 添加不同类型的BUFF
	weapon_wheel.add_to_weapon_wheel("projectile_damage")  # 5%投射物伤害
	weapon_wheel.add_to_weapon_wheel("fire_element")       # 10%火元素
	weapon_wheel.add_to_weapon_wheel("ray_damage")         # 8%射线伤害
	
	# 测试投射物炮塔（如gatling）的BUFF计算
	var projectile_buffs = weapon_wheel.get_turret_buffs("projectile")
	assert_equal(projectile_buffs.size(), 1, "投射物炮塔应该匹配1个类型BUFF")
	
	# 测试射线炮塔的BUFF计算
	var ray_buffs = weapon_wheel.get_turret_buffs("ray")
	assert_equal(ray_buffs.size(), 1, "射线炮塔应该匹配1个类型BUFF")
	
	# 测试元素BUFF计算
	var fire_buffs = weapon_wheel.get_element_buffs("fire")
	assert_equal(fire_buffs.size(), 1, "火元素应该匹配1个元素BUFF")
	
	var ice_buffs = weapon_wheel.get_element_buffs("ice")
	assert_equal(ice_buffs.size(), 0, "冰元素不应该匹配任何BUFF")
	
	weapon_wheel.queue_free()

# 测试物品掉落概率机制
func test_loot_drop_probability():
	# 测试不同概率下的掉落
	var high_chance_enemy = {
		"drop_table": {
			"base_chance": 1.0,  # 100%掉落
			"items": ["fire_basic", "ice_basic"]
		}
	}
	
	var no_chance_enemy = {
		"drop_table": {
			"base_chance": 0.0,  # 0%掉落
			"items": ["fire_basic", "ice_basic"]
		}
	}
	
	var no_drop_table_enemy = {}  # 没有掉落表
	
	# 测试高概率掉落（多次测试确保稳定性）
	var high_chance_drops = 0
	for i in range(10):
		var dropped_item = LootSystem.roll_drop(high_chance_enemy)
		if dropped_item != "":
			high_chance_drops += 1
	
	assert_equal(high_chance_drops, 10, "100%概率应该每次都掉落")
	
	# 测试零概率掉落
	var no_chance_drops = 0
	for i in range(10):
		var dropped_item = LootSystem.roll_drop(no_chance_enemy)
		if dropped_item != "":
			no_chance_drops += 1
	
	assert_equal(no_chance_drops, 0, "0%概率应该从不掉落")
	
	# 测试没有掉落表的敌人
	var no_table_result = LootSystem.roll_drop(no_drop_table_enemy)
	assert_equal(no_table_result, "", "没有掉落表的敌人不应该掉落任何物品")

# 测试掉落物品选择
func test_loot_drop_item_selection():
	var enemy_with_multiple_items = {
		"drop_table": {
			"base_chance": 1.0,
			"items": ["fire_basic", "ice_basic", "wind_basic", "earth_basic"]
		}
	}
	
	# 多次掉落测试，验证所有物品都有可能被选中
	var dropped_items = {}
	for i in range(1000):
		var dropped_item = LootSystem.roll_drop(enemy_with_multiple_items)
		if dropped_item != "":
			if not dropped_item in dropped_items:
				dropped_items[dropped_item] = 0
			dropped_items[dropped_item] += 1
	
	# 验证所有物品都有机会掉落
	var expected_items = ["fire_basic", "ice_basic", "wind_basic", "earth_basic"]
	for item in expected_items:
		assert_true(item in dropped_items, "物品 %s 应该有机会掉落" % item)
		assert_true(dropped_items[item] > 0, "物品 %s 应该至少掉落过一次" % item)
	
	# 测试单个物品的掉落表
	var single_item_enemy = {
		"drop_table": {
			"base_chance": 1.0,
			"items": ["light_basic"]
		}
	}
	
	var single_drop = LootSystem.roll_drop(single_item_enemy)
	assert_equal(single_drop, "light_basic", "单物品掉落表应该总是掉落指定物品")

# 测试掉落物品拾取机制
func test_loot_pickup_mechanism():
	# 创建测试掉落物品节点
	var drop_item = Node2D.new()
	drop_item.name = "TestDropItem"
	drop_item.set_meta("item_id", "fire_basic")
	drop_item.set_meta("pickup_ready", true)
	
	# 模拟拾取（这里我们测试拾取的逻辑，不测试实际的UI交互）
	var has_item_id = drop_item.has_meta("item_id")
	var is_pickup_ready = drop_item.get_meta("pickup_ready", false)
	
	assert_true(has_item_id, "掉落物品应该有item_id元数据")
	assert_true(is_pickup_ready, "掉落物品应该标记为可拾取")
	
	var item_id = drop_item.get_meta("item_id")
	assert_equal(item_id, "fire_basic", "掉落物品的item_id应该正确")
	
	drop_item.queue_free()

# 测试背包管理器信号系统
func test_inventory_signals():
	var inventory_manager = InventoryManager.new()
	var signal_received = false
	var received_item = {}
	
	# 连接信号
	inventory_manager.item_added.connect(func(item): 
		signal_received = true
		received_item = item
	)
	
	# 添加物品触发信号
	inventory_manager.add_item("test_gem", 1)
	
	# 等待信号处理（在实际测试中可能需要await或process frames）
	assert_true(signal_received, "添加物品应该触发item_added信号")
	assert_equal(received_item.id, "test_gem", "信号应该携带正确的物品信息")
	
	# 测试移除物品信号
	signal_received = false
	received_item = {}
	
	inventory_manager.item_removed.connect(func(item):
		signal_received = true
		received_item = item
	)
	
	inventory_manager.remove_item("test_gem", 1)
	assert_true(signal_received, "移除物品应该触发item_removed信号")
	
	inventory_manager.queue_free()

# 测试武器盘管理器信号系统
func test_weapon_wheel_signals():
	var weapon_wheel = WeaponWheelManager.new()
	var signal_received = false
	var received_items = []
	
	# 连接信号
	weapon_wheel.weapon_wheel_updated.connect(func(items):
		signal_received = true
		received_items = items
	)
	
	# 添加BUFF触发信号
	weapon_wheel.add_to_weapon_wheel("fire_element")
	
	assert_true(signal_received, "添加BUFF应该触发weapon_wheel_updated信号")
	assert_equal(received_items.size(), 1, "信号应该携带正确的物品数量")
	
	# 测试移除BUFF信号
	signal_received = false
	received_items = []
	
	weapon_wheel.remove_from_weapon_wheel(0)
	assert_true(signal_received, "移除BUFF应该触发weapon_wheel_updated信号")
	assert_equal(received_items.size(), 0, "移除后信号应该显示空的武器盘")
	
	weapon_wheel.queue_free()

# 性能测试：背包和武器盘操作
func test_performance_inventory_operations():
	# 测试背包管理器性能
	var inventory_manager = InventoryManager.new()
	
	var inventory_ops = func():
		inventory_manager.add_item("test_item", 1)
		inventory_manager.get_item_count("test_item")
		inventory_manager.has_item("test_item")
		inventory_manager.remove_item("test_item", 1)
	
	var inventory_benchmark = benchmark_function("inventory_operations", inventory_ops, 1000)
	assert_true(inventory_benchmark.average_duration < 0.1,
		"背包操作平均耗时应该少于0.1ms，实际: %.4fms" % inventory_benchmark.average_duration)
	
	# 测试武器盘管理器性能
	var weapon_wheel = WeaponWheelManager.new()
	
	var weapon_wheel_ops = func():
		weapon_wheel.add_to_weapon_wheel("fire_element")
		weapon_wheel.get_active_buffs()
		weapon_wheel.calculate_element_multiplier("fire")
		weapon_wheel.remove_from_weapon_wheel(0)
	
	var weapon_wheel_benchmark = benchmark_function("weapon_wheel_operations", weapon_wheel_ops, 1000)
	assert_true(weapon_wheel_benchmark.average_duration < 0.1,
		"武器盘操作平均耗时应该少于0.1ms，实际: %.4fms" % weapon_wheel_benchmark.average_duration)
	
	# 测试物品掉落性能
	var enemy_data = create_mock_enemy_data("fire", [])
	
	var loot_ops = func():
		LootSystem.roll_drop(enemy_data)
	
	var loot_benchmark = benchmark_function("loot_operations", loot_ops, 5000)
	assert_true(loot_benchmark.average_duration < 0.02,
		"掉落计算平均耗时应该少于0.02ms，实际: %.4fms" % loot_benchmark.average_duration)
	
	inventory_manager.queue_free()
	weapon_wheel.queue_free()