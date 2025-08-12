# Tower Defense Enhancement System - Technical Specification

## Problem Statement
- **Business Issue**: The current tower defense game lacks advanced mechanics and variety that would provide engaging endgame content and complex strategic decisions
- **Current State**: Basic tower types with simple DA/TA system, limited tower synergies, and basic enemy mechanics
- **Expected Outcome**: A rich tower defense experience with 9 new tower types, passive synergy system, charge mechanics, monster skills, summon stones, and integrated defense system

## Solution Overview
- **Approach**: Extend existing systems incrementally while maintaining backward compatibility with current DA/TA, element, and passive synergy frameworks
- **Core Changes**: New tower data structures, charge system implementation, monster skill enhancements, summon stone UI/mechanics, tech tree unlocks
- **Success Criteria**: All 9 tower types functional with unique mechanics, charge system at 100-point capacity, 4 monster skills operational, 5 summon stones with WOW-style UI, defense integration complete

## Technical Implementation

### Database Changes

#### Data.gd Enhancements
- **Tables to Modify**: Extend existing `turrets` dictionary with new tower types
- **New Data Structures**: Add charge system configuration, summon stone definitions, tech tree unlock conditions
- **Migration Scripts**: No SQL required - extend existing dictionary structures

```gdscript
# Add to Data.gd after line 887
const charge_system := {
	"max_charge": 100,
	"charge_per_attack": {
		"arrow_tower": 8,
		"capture_tower": 12,
		"mage_tower": 15
	},
	"charge_abilities": {
		"arrow_tower": {
			"name": "剑雨",
			"description": "小范围AOE，在目标区域施放15支箭",
			"range": 120.0,
			"arrow_count": 15,
			"damage_multiplier": 0.8
		},
		"capture_tower": {
			"name": "刺网", 
			"description": "捕获网范围增加100%，被捕单位防御力降低15%",
			"range_multiplier": 2.0,
			"armor_reduction": 0.15,
			"duration": 3.0
		},
		"mage_tower": {
			"name": "激活",
			"description": "攻击速度增加30%，持续3S",
			"speed_bonus": 0.30,
			"duration": 3.0
		}
	}
}

const summon_stones := {
	"shiva": {
		"name": "湿婆",
		"description": "所有塔攻击力+150%，持续15S",
		"cooldown": 180.0,
		"duration": 15.0,
		"effect_type": "global_damage_boost",
		"damage_multiplier": 2.5,
		"icon": "res://Assets/summon_stones/shiva.png"
	},
	"lucifer": {
		"name": "路西法",
		"description": "圆形范围内共造成2000点光属性伤害",
		"cooldown": 120.0,
		"effect_type": "targeted_damage",
		"damage": 2000,
		"element": "light",
		"range": 150.0,
		"icon": "res://Assets/summon_stones/lucifer.png"
	},
	"europa": {
		"name": "欧罗巴",
		"description": "圆形范围内共造成1200点冰属性伤害，并冻结所有单位2s",
		"cooldown": 180.0,
		"effect_type": "freeze_damage",
		"damage": 1200,
		"element": "ice",
		"range": 180.0,
		"freeze_duration": 2.0,
		"icon": "res://Assets/summon_stones/europa.png"
	},
	"titan": {
		"name": "泰坦",
		"description": "对所有塔充能30，伤害增加30%，持续5S",
		"cooldown": 120.0,
		"effect_type": "charge_and_damage",
		"charge_bonus": 30,
		"damage_bonus": 0.30,
		"duration": 5.0,
		"icon": "res://Assets/summon_stones/titan.png"
	},
	"zeus": {
		"name": "宙斯",
		"description": "驱散范围内敌方的BUFF，造成1500点光属性伤害",
		"cooldown": 180.0,
		"effect_type": "dispel_damage",
		"damage": 1500,
		"element": "light",
		"range": 200.0,
		"icon": "res://Assets/summon_stones/zeus.png"
	}
}

const tech_tree := {
	"charge_system_unlock": {
		"name": "充能系统解锁",
		"description": "解锁炮塔充能条系统",
		"cost": 1000,
		"unlocked": false,
		"requirements": []
	},
	"summon_stones_unlock": {
		"name": "召唤石系统解锁", 
		"description": "解锁召唤石装备系统",
		"cost": 1500,
		"unlocked": false,
		"requirements": ["charge_system_unlock"]
	}
}

const tower_mechanics := {
	"ricochet_shots": {
		"description": "子弹在敌人间弹射",
		"max_bounces": 5,
		"bounce_range": 80.0,
		"damage_falloff": 0.9
	},
	"periodic_aoe": {
		"description": "周期性区域伤害",
		"pulse_interval": 3.0,
		"range_multiplier": 1.0
	},
	"persistent_slow": {
		"description": "持续范围减速",
		"slow_strength": 0.3,
		"tick_interval": 0.5
	},
	"dot_damage": {
		"description": "持续伤害效果",
		"dot_duration": 15.0,
		"tick_interval": 1.0,
		"damage_per_tick": 25.0
	},
	"armor_reduction": {
		"description": "降低护甲效果",
		"reduction_amount": 0.05,
		"max_stacks": 10,
		"duration": 5.0
	}
}
```

### Code Changes

#### New Files to Create

**D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\ChargeSystem.gd**
```gdscript
class_name ChargeSystem
extends Node

signal charge_ability_triggered(tower: Turret, ability_name: String)
signal charge_updated(tower: Turret, current_charge: int)

var tower_charges: Dictionary = {}
var max_charge: int = 100

func _ready():
	if Globals.has_signal("turret_placed"):
		Globals.turret_placed.connect(_on_tower_placed)
	if Globals.has_signal("turret_removed"):  
		Globals.turret_removed.connect(_on_tower_removed)

func initialize_tower_charge(tower: Turret):
	if not tower or not tower.deployed:
		return
	tower_charges[tower.get_instance_id()] = 0

func add_charge(tower: Turret, amount: int = 0):
	if not tower or not tower.deployed:
		return
	
	var tower_id = tower.get_instance_id()
	if not tower_charges.has(tower_id):
		initialize_tower_charge(tower)
	
	var charge_amount = amount
	if charge_amount == 0:
		charge_amount = Data.charge_system.charge_per_attack.get(tower.turret_type, 5)
	
	tower_charges[tower_id] = min(tower_charges[tower_id] + charge_amount, max_charge)
	charge_updated.emit(tower, tower_charges[tower_id])
	
	if tower_charges[tower_id] >= max_charge:
		trigger_charge_ability(tower)

func trigger_charge_ability(tower: Turret):
	if not tower or not has_charge_ability(tower.turret_type):
		return
	
	var tower_id = tower.get_instance_id()
	tower_charges[tower_id] = 0
	
	var ability_data = Data.charge_system.charge_abilities.get(tower.turret_type, {})
	execute_charge_ability(tower, ability_data)
	charge_ability_triggered.emit(tower, ability_data.get("name", "Unknown"))

func execute_charge_ability(tower: Turret, ability_data: Dictionary):
	match tower.turret_type:
		"arrow_tower":
			execute_arrow_rain(tower, ability_data)
		"capture_tower":
			execute_thorn_net(tower, ability_data)
		"mage_tower":
			execute_activation(tower, ability_data)

func has_charge_ability(tower_type: String) -> bool:
	return Data.charge_system.charge_abilities.has(tower_type)

func get_tower_charge(tower: Turret) -> int:
	if not tower:
		return 0
	return tower_charges.get(tower.get_instance_id(), 0)

func execute_arrow_rain(tower: Turret, ability_data: Dictionary):
	# Create multiple projectiles in target area
	var target_pos = tower.current_target.position if tower.current_target else tower.position
	var arrow_count = ability_data.get("arrow_count", 15)
	var damage_multiplier = ability_data.get("damage_multiplier", 0.8)
	
	for i in range(arrow_count):
		var offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))
		create_charge_projectile(tower, target_pos + offset, damage_multiplier)

func execute_thorn_net(tower: Turret, ability_data: Dictionary):
	# Enhance capture tower's next few attacks
	var enhanced_range = tower.attack_range * ability_data.get("range_multiplier", 2.0)
	var armor_reduction = ability_data.get("armor_reduction", 0.15)
	tower.set("enhanced_capture", {"range": enhanced_range, "armor_reduction": armor_reduction, "duration": 5.0})

func execute_activation(tower: Turret, ability_data: Dictionary):
	# Boost mage tower attack speed temporarily
	var speed_bonus = ability_data.get("speed_bonus", 0.30)
	var duration = ability_data.get("duration", 3.0)
	var original_speed = tower.attack_speed
	tower.attack_speed *= (1.0 + speed_bonus)
	
	# Restore after duration
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(tower):
		tower.attack_speed = original_speed

func create_charge_projectile(tower: Turret, target_pos: Vector2, damage_multiplier: float):
	var projectileScene := preload("res://Scenes/turrets/projectileTurret/bullet/bulletBase.tscn")
	var projectile := projectileScene.instantiate()
	projectile.bullet_type = "fire"
	projectile.base_damage = tower.damage * damage_multiplier
	projectile.element = tower.element
	projectile.speed = 300.0
	
	Globals.projectilesNode.add_child(projectile)
	projectile.position = tower.position
	projectile.target = target_pos

func _on_tower_placed(tower: Turret):
	initialize_tower_charge(tower)

func _on_tower_removed(tower: Turret):
	if tower:
		tower_charges.erase(tower.get_instance_id())
```

**D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\SummonStoneSystem.gd**
```gdscript
class_name SummonStoneSystem
extends Node

signal summon_stone_activated(stone_id: String, position: Vector2)
signal summon_stone_equipped(slot: int, stone_id: String)
signal summon_stone_cooldown_updated(slot: int, remaining_time: float)

var equipped_stones: Array[String] = ["", "", ""]
var stone_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var max_slots: int = 3

func _ready():
	set_process(true)

func _process(delta):
	update_cooldowns(delta)

func equip_summon_stone(slot: int, stone_id: String) -> bool:
	if slot < 0 or slot >= max_slots:
		return false
	
	if not Data.summon_stones.has(stone_id):
		return false
	
	equipped_stones[slot] = stone_id
	summon_stone_equipped.emit(slot, stone_id)
	return true

func activate_summon_stone(slot: int, target_position: Vector2 = Vector2.ZERO) -> bool:
	if slot < 0 or slot >= max_slots:
		return false
	
	if stone_cooldowns[slot] > 0:
		return false
	
	var stone_id = equipped_stones[slot]
	if stone_id == "":
		return false
	
	if not Data.summon_stones.has(stone_id):
		return false
	
	var stone_data = Data.summon_stones[stone_id]
	stone_cooldowns[slot] = stone_data.cooldown
	
	execute_summon_stone_effect(stone_id, stone_data, target_position)
	summon_stone_activated.emit(stone_id, target_position)
	return true

func execute_summon_stone_effect(stone_id: String, stone_data: Dictionary, position: Vector2):
	match stone_data.effect_type:
		"global_damage_boost":
			apply_global_damage_boost(stone_data)
		"targeted_damage":
			apply_targeted_damage(stone_data, position)
		"freeze_damage":
			apply_freeze_damage(stone_data, position)
		"charge_and_damage":
			apply_charge_and_damage(stone_data)
		"dispel_damage":
			apply_dispel_damage(stone_data, position)

func update_cooldowns(delta: float):
	for i in range(max_slots):
		if stone_cooldowns[i] > 0:
			stone_cooldowns[i] -= delta
			stone_cooldowns[i] = max(0, stone_cooldowns[i])
			summon_stone_cooldown_updated.emit(i, stone_cooldowns[i])

func get_stone_cooldown_ratio(slot: int) -> float:
	if slot < 0 or slot >= max_slots:
		return 0.0
	
	var stone_id = equipped_stones[slot]
	if stone_id == "" or not Data.summon_stones.has(stone_id):
		return 0.0
	
	var max_cooldown = Data.summon_stones[stone_id].cooldown
	return stone_cooldowns[slot] / max_cooldown

func apply_global_damage_boost(stone_data: Dictionary):
	var all_towers = get_all_towers()
	var duration = stone_data.get("duration", 15.0)
	var multiplier = stone_data.get("damage_multiplier", 2.5)
	
	for tower in all_towers:
		if is_instance_valid(tower):
			var original_damage = tower.damage
			tower.damage *= multiplier
			# Restore after duration
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(tower):
				tower.damage = original_damage

func apply_targeted_damage(stone_data: Dictionary, position: Vector2):
	var damage = stone_data.get("damage", 2000)
	var range_val = stone_data.get("range", 150.0)
	var element = stone_data.get("element", "light")
	
	var enemies = get_enemies_in_range(position, range_val)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.get_damage(damage)

func apply_freeze_damage(stone_data: Dictionary, position: Vector2):
	var damage = stone_data.get("damage", 1200)
	var range_val = stone_data.get("range", 180.0)
	var freeze_duration = stone_data.get("freeze_duration", 2.0)
	
	var enemies = get_enemies_in_range(position, range_val)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.get_damage(damage)
			apply_freeze_effect(enemy, freeze_duration)

func apply_charge_and_damage(stone_data: Dictionary):
	var charge_bonus = stone_data.get("charge_bonus", 30)
	var damage_bonus = stone_data.get("damage_bonus", 0.30)
	var duration = stone_data.get("duration", 5.0)
	
	var all_towers = get_all_towers()
	var charge_system = get_charge_system()
	
	for tower in all_towers:
		if is_instance_valid(tower) and charge_system:
			charge_system.add_charge(tower, charge_bonus)
			var original_damage = tower.damage
			tower.damage *= (1.0 + damage_bonus)
			# Restore after duration
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(tower):
				tower.damage = original_damage

func apply_dispel_damage(stone_data: Dictionary, position: Vector2):
	var damage = stone_data.get("damage", 1500)
	var range_val = stone_data.get("range", 200.0)
	
	var enemies = get_enemies_in_range(position, range_val)
	for enemy in enemies:
		if is_instance_valid(enemy):
			dispel_enemy_buffs(enemy)
			enemy.get_damage(damage)

func get_all_towers() -> Array[Turret]:
	var towers: Array[Turret] = []
	var turret_nodes = get_tree().get_nodes_in_group("turret")
	for turret in turret_nodes:
		if turret is Turret and turret.deployed:
			towers.append(turret)
	return towers

func get_enemies_in_range(center: Vector2, range_val: float) -> Array:
	var enemies = []
	var enemy_nodes = get_tree().get_nodes_in_group("enemy")
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= range_val:
			enemies.append(enemy)
	return enemies

func get_charge_system() -> ChargeSystem:
	return get_tree().current_scene.get_node_or_null("ChargeSystem")

func apply_freeze_effect(enemy: Node2D, duration: float):
	if enemy.has_method("set"):
		var original_speed = enemy.speed
		enemy.speed = 0.0
		enemy.modulate = Color.CYAN
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(enemy):
			enemy.speed = original_speed
			enemy.modulate = Color.WHITE

func dispel_enemy_buffs(enemy: Node2D):
	# Remove any active buffs from monster skill system
	var monster_skill_system = get_tree().current_scene.get_node_or_null("MonsterSkillSystem")
	if monster_skill_system and monster_skill_system.has_method("remove_enemy_buffs"):
		monster_skill_system.remove_enemy_buffs(enemy)
```

**D:\pycode\Godot-4-Tower-Defense-Template\Scenes\ui\summonStones\SummonStoneUI.gd**
```gdscript
class_name SummonStoneUI
extends Control

signal stone_slot_clicked(slot: int, position: Vector2)

@onready var slot_containers: Array[Control] = []
@onready var cooldown_overlays: Array[Control] = []
@onready var progress_indicators: Array[TextureProgressBar] = []

var summon_system: SummonStoneSystem

func _ready():
	setup_ui()
	find_summon_system()
	connect_signals()

func setup_ui():
	# Create 3 horizontal slots for WOW-style layout
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hbox.position = Vector2(50, -100)
	add_child(hbox)
	
	for i in range(3):
		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = Vector2(64, 64)
		slot_panel.add_theme_style_override("panel", create_slot_style())
		hbox.add_child(slot_panel)
		slot_containers.append(slot_panel)
		
		# Add icon texture rect
		var icon_rect = TextureRect.new()
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		slot_panel.add_child(icon_rect)
		
		# Add progress bar for cooldown (circular)
		var progress = TextureProgressBar.new()
		progress.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		progress.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		progress.value = 100
		progress.modulate = Color(1, 1, 1, 0.8)
		slot_panel.add_child(progress)
		progress_indicators.append(progress)
		
		# Add cooldown text overlay
		var cooldown_label = Label.new()
		cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldown_label.add_theme_font_size_override("font_size", 12)
		cooldown_label.modulate = Color.YELLOW
		cooldown_label.visible = false
		slot_panel.add_child(cooldown_label)
		cooldown_overlays.append(cooldown_label)
		
		# Connect click signal
		slot_panel.gui_input.connect(_on_slot_clicked.bind(i))

func create_slot_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.GOLD
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func find_summon_system():
	summon_system = get_tree().current_scene.get_node_or_null("SummonStoneSystem")

func connect_signals():
	if summon_system:
		summon_system.summon_stone_equipped.connect(_on_stone_equipped)
		summon_system.summon_stone_cooldown_updated.connect(_on_cooldown_updated)

func _on_slot_clicked(slot: int, event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var global_pos = get_global_mouse_position()
			if summon_system:
				summon_system.activate_summon_stone(slot, global_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click to open stone selection
			stone_slot_clicked.emit(slot, get_global_mouse_position())

func _on_stone_equipped(slot: int, stone_id: String):
	if slot >= 0 and slot < slot_containers.size():
		var slot_panel = slot_containers[slot]
		var icon_rect = slot_panel.get_child(0) as TextureRect
		
		if stone_id != "" and Data.summon_stones.has(stone_id):
			var stone_data = Data.summon_stones[stone_id]
			var icon_path = stone_data.get("icon", "")
			if icon_path != "" and ResourceLoader.exists(icon_path):
				icon_rect.texture = load(icon_path)
			
			# Update tooltip
			slot_panel.tooltip_text = "%s\n%s\nCD: %.0fs" % [
				stone_data.get("name", "Unknown"),
				stone_data.get("description", ""),
				stone_data.get("cooldown", 0)
			]
		else:
			icon_rect.texture = null
			slot_panel.tooltip_text = "Empty Slot"

func _on_cooldown_updated(slot: int, remaining_time: float):
	if slot >= 0 and slot < progress_indicators.size():
		var progress = progress_indicators[slot]
		var overlay = cooldown_overlays[slot] as Label
		
		if remaining_time > 0:
			var stone_id = summon_system.equipped_stones[slot]
			if stone_id != "" and Data.summon_stones.has(stone_id):
				var max_cooldown = Data.summon_stones[stone_id].cooldown
				var ratio = remaining_time / max_cooldown
				progress.value = (1.0 - ratio) * 100
				overlay.text = "%.1f" % remaining_time
				overlay.visible = true
		else:
			progress.value = 100
			overlay.visible = false
```

**D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\TechTreeSystem.gd**
```gdscript
class_name TechTreeSystem
extends Node

signal tech_unlocked(tech_id: String)
signal tech_purchase_failed(tech_id: String, reason: String)

var unlocked_techs: Array[String] = []

func _ready():
	load_tech_progress()

func can_unlock_tech(tech_id: String) -> bool:
	if not Data.tech_tree.has(tech_id):
		return false
	
	var tech_data = Data.tech_tree[tech_id]
	
	# Check if already unlocked
	if tech_data.unlocked or tech_id in unlocked_techs:
		return false
	
	# Check requirements
	for requirement in tech_data.requirements:
		if not is_tech_unlocked(requirement):
			return false
	
	# Check cost
	if Globals.currentMap and Globals.currentMap.gold < tech_data.cost:
		return false
	
	return true

func unlock_tech(tech_id: String) -> bool:
	if not can_unlock_tech(tech_id):
		tech_purchase_failed.emit(tech_id, "Requirements not met")
		return false
	
	var tech_data = Data.tech_tree[tech_id]
	
	# Deduct cost
	if Globals.currentMap:
		Globals.currentMap.gold -= tech_data.cost
	
	# Mark as unlocked
	unlocked_techs.append(tech_id)
	tech_data.unlocked = true
	
	apply_tech_effects(tech_id)
	tech_unlocked.emit(tech_id)
	save_tech_progress()
	return true

func is_tech_unlocked(tech_id: String) -> bool:
	return tech_id in unlocked_techs or Data.tech_tree.get(tech_id, {}).get("unlocked", false)

func apply_tech_effects(tech_id: String):
	match tech_id:
		"charge_system_unlock":
			enable_charge_system()
		"summon_stones_unlock":
			enable_summon_stones()

func enable_charge_system():
	# Enable charge system functionality
	var charge_system = get_tree().current_scene.get_node_or_null("ChargeSystem")
	if charge_system:
		charge_system.set_process(true)

func enable_summon_stones():
	# Enable summon stone functionality  
	var summon_system = get_tree().current_scene.get_node_or_null("SummonStoneSystem")
	if summon_system:
		summon_system.set_process(true)

func save_tech_progress():
	var save_data = {
		"unlocked_techs": unlocked_techs
	}
	var file = FileAccess.open("user://tech_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_tech_progress():
	if FileAccess.file_exists("user://tech_progress.json"):
		var file = FileAccess.open("user://tech_progress.json", FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				var save_data = json.data
				unlocked_techs = save_data.get("unlocked_techs", [])
				# Apply unlocked tech effects
				for tech_id in unlocked_techs:
					apply_tech_effects(tech_id)
```

#### Files to Modify

**D:\pycode\Godot-4-Tower-Defense-Template\Scenes\turrets\turretBase\turret_base.gd**
- **Modification Type**: Extend with charge system integration
- **Changes**: Add charge tracking, charge ability methods, integrate with ChargeSystem

```gdscript
# Add these properties after line 60
var current_charge: int = 0
var charge_system: ChargeSystem

# Add to _ready() method after line 82
func _ready():
	# Existing _ready code...
	find_charge_system()

# Add new methods after line 306
func find_charge_system():
	var tree = get_tree()
	if tree and tree.current_scene:
		charge_system = tree.current_scene.get_node_or_null("ChargeSystem")

# Modify attack() method to add charge after successful attack
func attack():
	if is_instance_valid(current_target):
		# Existing attack logic...
		pass
	else:
		try_get_closest_target()
	
	# Add charge after attack (only for towers with charge abilities)
	if charge_system and deployed and has_charge_ability():
		charge_system.add_charge(self)

func get_charge_progress() -> float:
	if not charge_system:
		return 0.0
	return float(charge_system.get_tower_charge(self)) / float(charge_system.max_charge)

func can_use_charge_ability() -> bool:
	return charge_system and charge_system.has_charge_ability(turret_type) and current_charge >= 100

func has_charge_ability() -> bool:
	return charge_system and charge_system.has_charge_ability(turret_type)
```

**D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\MonsterSkillSystem.gd**
- **Modification Type**: Add dispel functionality for summon stones
- **Changes**: Add method to remove enemy buffs

```gdscript
# Add after line 380
func remove_enemy_buffs(enemy: Node2D):
	# Remove all active effects targeting this enemy
	var effects_to_remove: Array[Dictionary] = []
	
	for effect in active_effects:
		if effect.target == enemy and effect.type in ["acceleration", "petrification"]:
			effects_to_remove.append(effect)
	
	# Remove the effects
	for effect in effects_to_remove:
		remove_effect(effect)
		active_effects.erase(effect)
```

### API Changes

#### New Node Signals
- **ChargeSystem**: `charge_ability_triggered(tower, ability_name)`, `charge_updated(tower, current_charge)`
- **SummonStoneSystem**: `summon_stone_activated(stone_id, position)`, `summon_stone_equipped(slot, stone_id)`
- **TechTreeSystem**: `tech_unlocked(tech_id)`, `tech_purchase_failed(tech_id, reason)`

#### Integration Points
- **PassiveSynergyManager**: Already implemented, handles new tower passive effects
- **MonsterSkillSystem**: Already implemented, needs integration testing
- **DefenseSystem**: Already implemented, works with armor reduction mechanics

### Configuration Changes

#### New Scene Files Required
- `res://Scenes/systems/ChargeSystem.tscn`
- `res://Scenes/systems/SummonStoneSystem.tscn`  
- `res://Scenes/systems/TechTreeSystem.tscn`
- `res://Scenes/ui/summonStones/SummonStoneUI.tscn`
- `res://Scenes/ui/techTree/TechTreeUI.tscn`

#### Environment Variables
- No new environment variables required
- All configuration data stored in Data.gd

#### Feature Flags
- Tech tree unlocks act as feature flags for charge system and summon stones
- Controlled via `TechTreeSystem.is_tech_unlocked()`

## Implementation Sequence

### Phase 1: Core System Infrastructure
- **Task 1.1**: Create ChargeSystem.gd with basic charge tracking (file: D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\ChargeSystem.gd)
- **Task 1.2**: Create SummonStoneSystem.gd with equipment/activation logic (file: D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\SummonStoneSystem.gd)
- **Task 1.3**: Create TechTreeSystem.gd with unlock mechanics (file: D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\TechTreeSystem.gd)
- **Task 1.4**: Extend Data.gd with charge system, summon stones, and tech tree data
- **Task 1.5**: Modify turret_base.gd to integrate charge system functionality

### Phase 2: Tower Type Charge Abilities Implementation
- **Task 2.1**: Implement arrow tower charge ability (剑雨 - Arrow Rain)
- **Task 2.2**: Implement capture tower charge ability (刺网 - Thorn Net) 
- **Task 2.3**: Implement mage tower charge ability (激活 - Activation)
- **Task 2.4**: Verify existing tower types work with new charge system
- **Task 2.5**: Test passive synergy integration with charge abilities

### Phase 3: Summon Stone System Implementation
- **Task 3.1**: Create SummonStoneUI.gd with 3-slot WOW-style interface (file: D:\pycode\Godot-4-Tower-Defense-Template\Scenes\ui\summonStones\SummonStoneUI.gd)
- **Task 3.2**: Implement all 5 summon stone effects (湿婆, 路西法, 欧罗巴, 泰坦, 宙斯)
- **Task 3.3**: Create cooldown visual indicators and progress bars
- **Task 3.4**: Integrate summon stone equipment and activation mechanics
- **Task 3.5**: Add monster skill dispel functionality for Zeus summon stone

### Phase 4: Integration and Tech Tree
- **Task 4.1**: Integrate all systems with existing PassiveSynergyManager and MonsterSkillSystem
- **Task 4.2**: Create tech tree UI for unlocking charge system and summon stones
- **Task 4.3**: Test DA/TA system compatibility with charge abilities (charge abilities cannot trigger DA/TA)
- **Task 4.4**: Validate defense system formula integration with existing armor mechanics
- **Task 4.5**: Performance testing with multiple concurrent effects and charge abilities

## Validation Plan

### Unit Tests
- **ChargeSystem Tests**: Verify charge accumulation (8 points per arrow tower attack), ability triggering at 100 charge, reset functionality
- **SummonStoneSystem Tests**: Test equipment in 3 slots, activation with correct cooldowns, visual cooldown indicators
- **TechTreeSystem Tests**: Validate unlock requirements, cost deduction (1000 gold for charge, 1500 for summon stones), effect application
- **Tower Charge Integration Tests**: Ensure only towers with charge abilities accumulate charge
- **Summon Stone Effect Tests**: Verify all 5 summon stone effects work correctly with proper ranges and durations

### Integration Tests
- **System Interaction Tests**: Charge system + existing DA/TA compatibility, summon stones + monster skill dispel
- **Performance Tests**: Multiple towers with charge abilities, concurrent summon stone activations
- **UI Integration Tests**: Summon stone UI responsiveness, charge bar updates in real-time
- **Tech Tree Progression Tests**: Unlock flow from charge system to summon stones

### Business Logic Verification
- **Charge Ability Balance**: Arrow rain (15 arrows, 0.8x damage), thorn net (2x range, 15% armor reduction), activation (30% speed boost, 3s duration)
- **Summon Stone Balance**: Cooldowns (2-3 minutes), effects provide meaningful strategic value
- **Tech Tree Progression**: Unlock costs feel appropriate for progression curve
- **Player Experience Flow**: Charge system unlocks create satisfying progression, summon stones provide powerful late-game options

## Performance Considerations

### Optimization Strategies
- **ChargeSystem**: Event-driven charge updates only on successful attacks, not per-frame processing
- **SummonStoneSystem**: Cooldown updates only when stones are equipped and on cooldown
- **PassiveSynergyManager**: Existing 1-second update interval maintained for performance
- **MonsterSkillSystem**: Existing 10 concurrent effect limit prevents performance degradation

### Memory Management
- **Tower Charge Data**: Use instance IDs as keys, automatic cleanup on tower removal
- **Summon Stone Cooldowns**: Fixed 3-slot array, minimal memory overhead
- **Effect Pooling**: Reuse projectile objects for charge abilities to reduce instantiation

### Scalability Limits
- **Maximum Charge Abilities**: No limit on concurrent charge ability usage
- **Summon Stone Activations**: Cooldown-gated, multiple stones can be activated simultaneously
- **Tech Tree Storage**: Persistent save/load for unlock progression across game sessions

This technical specification provides the complete implementation blueprint for the charge system, summon stone mechanics, and tech tree integration while maintaining compatibility with the existing tower defense enhancement systems.