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

# Hero system classes
const HeroManager = preload("res://Scenes/systems/HeroManager.gd")
const HeroTalentSystem = preload("res://Scenes/systems/HeroTalentSystem.gd")
const LevelModifierSystem = preload("res://Scenes/systems/LevelModifierSystem.gd")
const HeroRangeIndicator = preload("res://Scenes/ui/heroSystem/HeroRangeIndicator.gd")

func _ready() -> void:
	if not is_instance_valid(Globals):
		push_error("Globals not available")
		return
	
	Globals.main_node = self
	
	# Verify system functionality
	run_system_tests()
	
	# Initialize manager systems
	init_manager_systems()
	
	# Load map
	var map_key = Globals.selected_map if not Globals.selected_map.is_empty() else "map1"
	if not Data.maps.has(map_key):
		push_error("Map key not found: " + map_key)
		map_key = "map1"  # Fallback
	
	var map_data = Data.maps[map_key]
	var scene_path = map_data.get("scene", "")
	if scene_path.is_empty():
		push_error("Scene path empty for map: " + map_key)
		return
	
	var selected_map_scene = Data.load_resource_safe(scene_path, "PackedScene")
	if not selected_map_scene:
		return
	
	var map = selected_map_scene.instantiate()
	if not map:
		push_error("Failed to instantiate map scene")
		return
	
	if "map_type" in map:
		map.map_type = map_key
	
	add_child(map)
	Globals.current_map = map

func init_manager_systems() -> void:
	# Use call_deferred to avoid busy state issues
	call_deferred("add_managers")
func add_managers() -> void:
	var tree = get_tree()
	if not tree:
		push_error("Cannot access scene tree")
		return
	
	# Create and add inventory manager
	_create_manager("InventoryManager", InventoryManager, tree.root)
	
	# Create and add weapon wheel manager
	_create_manager("WeaponWheelManager", WeaponWheelManager, tree.root)
	
	# Create and add passive synergy manager
	_create_manager("PassiveSynergyManager", PassiveSynergyManager, self)
	
	# Create and add monster skill system
	_create_manager("MonsterSkillSystem", MonsterSkillSystem, self)
	
	# Create and add charge system
	_create_manager("ChargeSystem", ChargeSystem, self)
	
	# Create and add summon stone system
	_create_manager("SummonStoneSystem", SummonStoneSystem, self)

func _create_manager(manager_name: String, manager_class, parent_node: Node) -> void:
	if not is_instance_valid(parent_node):
		push_error("Cannot create manager '" + manager_name + "': parent node is invalid")
		return
	
	# Check if manager already exists
	if parent_node.get_node_or_null(manager_name):
		push_warning("Manager '" + manager_name + "' already exists")
		return
	
	var manager = manager_class.new()
	if not manager:
		push_error("Failed to create manager: " + manager_name)
		return
	
	manager.name = manager_name
	parent_node.add_child(manager)
	
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
	
	# 创建并添加英雄系统
	var hero_manager = HeroManager.new()
	hero_manager.name = "HeroManager"
	add_child(hero_manager)
	
	# 创建并添加英雄天赋系统
	var hero_talent_system = HeroTalentSystem.new()
	hero_talent_system.name = "HeroTalentSystem"
	add_child(hero_talent_system)
	
	# 创建并添加关卡词缀系统
	var level_modifier_system = LevelModifierSystem.new()
	level_modifier_system.name = "LevelModifierSystem"
	add_child(level_modifier_system)
	
	# 创建并添加英雄范围指示器
	var hero_range_indicator = HeroRangeIndicator.new()
	hero_range_indicator.name = "HeroRangeIndicator"
	add_child(hero_range_indicator)
	
	# 连接英雄系统
	connect_hero_systems()
	
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

func connect_hero_systems() -> void:
	"""连接英雄系统之间的信号"""
	var hero_manager = get_node_or_null("HeroManager") as HeroManager
	var talent_system = get_node_or_null("HeroTalentSystem") as HeroTalentSystem
	var modifier_system = get_node_or_null("LevelModifierSystem") as LevelModifierSystem
	var range_indicator = get_node_or_null("HeroRangeIndicator") as HeroRangeIndicator
	
	# 连接UI组件
	var hero_selection_ui = get_node_or_null("UI/HeroSelection")
	var hero_info_panel = get_node_or_null("UI/HeroInfoPanel")
	var talent_selection_ui = get_node_or_null("UI/HeroTalentSelection")
	
	if hero_manager and hero_selection_ui:
		# 连接英雄管理器到选择UI
		hero_selection_ui.setup_from_hero_manager(hero_manager)
	
	if hero_manager and hero_info_panel:
		# 连接英雄管理器到信息面板
		hero_info_panel.setup_from_hero_manager(hero_manager)
	
	if hero_manager and talent_selection_ui:
		# 连接英雄管理器到天赋选择UI
		talent_selection_ui.setup_from_hero_manager(hero_manager)
	
	if hero_manager and talent_system:
		# 连接英雄管理器和天赋系统
		hero_manager.connect("hero_deployed", _on_hero_deployed)
		hero_manager.connect("hero_leveled_up", _on_hero_leveled_up)
		
		if talent_system.has_signal("talent_selected"):
			talent_system.connect("talent_selected", _on_talent_selected)
	
	if hero_manager and range_indicator:
		# 连接英雄管理器到范围指示器
		hero_manager.connect("hero_selection_started", _on_hero_selection_started)
		range_indicator.connect("deployment_position_selected", _on_deployment_position_selected)
	
	if modifier_system:
		# 连接词缀系统
		if modifier_system.has_signal("modifiers_applied"):
			modifier_system.connect("modifiers_applied", _on_level_modifiers_applied)

func _on_hero_deployed(hero: HeroBase, position: Vector2) -> void:
	"""处理英雄部署"""
	print("Hero deployed: ", hero.hero_name, " at ", position)
	
	# 连接英雄到天赋系统
	var talent_system = get_node_or_null("HeroTalentSystem") as HeroTalentSystem
	if talent_system:
		talent_system.connect_to_hero(hero)
	
	# 更新英雄信息面板
	var hero_info_panel = get_node_or_null("UI/HeroInfoPanel") as Control
	if hero_info_panel:
		hero_info_panel.update_hero_info(hero)

func _on_hero_leveled_up(hero: HeroBase, new_level: int) -> void:
	"""处理英雄升级"""
	print("Hero leveled up: ", hero.hero_name, " to level ", new_level)

func _on_talent_selected(hero: HeroBase, talent_id: String, level: int) -> void:
	"""处理天赋选择"""
	print("Talent selected: ", talent_id, " for ", hero.hero_name, " at level ", level)

func _on_level_modifiers_applied(modifiers: Array[Dictionary]) -> void:
	"""处理关卡词缀应用"""
	print("Level modifiers applied: ", modifiers.size(), " modifiers")

func _on_hero_selection_started(hero_type: String) -> void:
	"""处理英雄选择开始"""
	var range_indicator = get_node_or_null("HeroRangeIndicator") as HeroRangeIndicator
	if range_indicator:
		range_indicator.show_deployment_zones(hero_type)

func _on_deployment_position_selected(position: Vector2) -> void:
	"""处理部署位置选择"""
	var hero_manager = get_node_or_null("HeroManager") as HeroManager
	if hero_manager:
		hero_manager.deploy_hero_at_position(position)

func _exit_tree():
	# 清理管理器（如果需要）
	var inventory_manager = get_tree().root.get_node_or_null("InventoryManager")
	if inventory_manager:
		inventory_manager.queue_free()
	
	var weapon_manager = get_tree().root.get_node_or_null("WeaponWheelManager")
	if weapon_manager:
		weapon_manager.queue_free()
