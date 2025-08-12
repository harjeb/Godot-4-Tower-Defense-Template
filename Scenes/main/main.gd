extends Node2D

# Preload system scripts to ensure they're available
const TowerTechSystem = preload("res://Scenes/systems/TowerTechSystem.gd")
const InventoryManager = preload("res://Scenes/systems/InventoryManager.gd")
const WeaponWheelManager = preload("res://Scenes/systems/WeaponWheelManager.gd")
const PassiveSynergyManager = preload("res://Scenes/systems/PassiveSynergyManager.gd")
const MonsterSkillSystem = preload("res://Scenes/systems/MonsterSkillSystem.gd")
const ChargeSystem = preload("res://Scenes/systems/ChargeSystem.gd")
const SummonStoneSystem = preload("res://Scenes/systems/SummonStoneSystem.gd")
const TechPointSystem = preload("res://Scenes/systems/TechPointSystem.gd")
const WaveManager = preload("res://Scenes/systems/WaveManager.gd")
const EffectManager = preload("res://Scenes/systems/EffectManager.gd")

func _ready():
	Globals.mainNode = self
	
	# 验证系统功能
	run_system_tests()
	
	# 初始化管理器系统
	init_manager_systems()
	
	# 加载地图
	var map_key = Globals.selected_map if Globals.selected_map != "" else "map1"
	var selectedMapScene := load(Data.maps[map_key]["scene"])
	var map = selectedMapScene.instantiate()
	map.map_type = map_key
	add_child(map)

func init_manager_systems():
	# 使用call_deferred避免忙碌状态问题
	call_deferred("add_managers")
func add_managers():
	# 创建并添加背包管理器
	var inventory_manager = InventoryManager.new()
	inventory_manager.name = "InventoryManager"
	get_tree().root.add_child(inventory_manager)
	
	# 创建并添加武器盘管理器
	var weapon_wheel_manager = WeaponWheelManager.new()
	weapon_wheel_manager.name = "WeaponWheelManager"
	get_tree().root.add_child(weapon_wheel_manager)
	
	# 创建并添加被动协同管理器
	var passive_synergy_manager = PassiveSynergyManager.new()
	passive_synergy_manager.name = "PassiveSynergyManager"
	add_child(passive_synergy_manager)
	
	# 创建并添加怪物技能系统
	var monster_skill_system = MonsterSkillSystem.new()
	monster_skill_system.name = "MonsterSkillSystem"
	add_child(monster_skill_system)
	
	# 创建并添加充能系统
	var charge_system = ChargeSystem.new()
	charge_system.name = "ChargeSystem"
	add_child(charge_system)
	
	# 创建并添加召唤石系统
	var summon_stone_system = SummonStoneSystem.new()
	summon_stone_system.name = "SummonStoneSystem"
	add_child(summon_stone_system)
	
	# 创建并添加科技点系统
	var tech_point_system = TechPointSystem.new()
	tech_point_system.name = "TechPointSystem"
	add_child(tech_point_system)
	
	# 创建并添加波次管理系统
	var wave_manager = WaveManager.new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)
	
	# 创建并添加塔科技系统
	var tower_tech_system = TowerTechSystem.new()
	tower_tech_system.name = "TowerTechSystem"
	add_child(tower_tech_system)
	
	# 创建并添加效果管理器
	var effect_manager = EffectManager.new()
	effect_manager.name = "EffectManager"
	add_child(effect_manager)
	
	# 添加一些初始物品用于测试 (可选)
	call_deferred("add_test_items")  

func add_test_items():
	# 获取管理器引用
	var inventory_manager = get_tree().root.get_node("InventoryManager") as InventoryManager
	var weapon_manager = get_tree().root.get_node("WeaponWheelManager") as WeaponWheelManager
	
	if inventory_manager:
		# 添加一些初始宝石用于测试
		inventory_manager.add_item("fire_basic", 3)
		inventory_manager.add_item("ice_basic", 2)
		inventory_manager.add_item("wind_basic", 2)
		inventory_manager.add_item("earth_basic", 1)
		inventory_manager.add_item("light_basic", 2)
	
	if weapon_manager:
		# 添加一些初始 BUFF 用于测试
		weapon_manager.add_to_weapon_wheel("projectile_damage")
		weapon_manager.add_to_weapon_wheel("fire_element")

# 可选的系统验证函数，用于开发时检查功能
func run_system_tests():
	# 注释掉测试输出，避免生产环境干扰
	# print("==== 塔防增强系统测试 ====")
	
	# 验证核心系统加载状态
	if not ElementSystem or not Data:
		push_error("核心系统未正确加载！")
	
	# print("==== 系统测试完成 ====\n")

func _exit_tree():
	# 清理管理器（如果需要）
	var inventory_manager = get_tree().root.get_node_or_null("InventoryManager")
	if inventory_manager:
		inventory_manager.queue_free()
	
	var weapon_manager = get_tree().root.get_node_or_null("WeaponWheelManager")
	if weapon_manager:
		weapon_manager.queue_free()
