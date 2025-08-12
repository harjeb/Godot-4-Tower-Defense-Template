class_name ChargeSystem
extends Node

signal charge_ability_triggered(tower: Turret, ability_name: String)
signal charge_updated(tower: Turret, current_charge: int)

var tower_charges: Dictionary = {}
var max_charge: int = 100
var charge_speed_multiplier: float = 1.0

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
	
	# Apply charge speed multiplier from talents
	charge_amount = int(charge_amount * charge_speed_multiplier)
	
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
	# Apply projectile speed talent boost
	var speed_multiplier = Globals.get("projectile_speed_boost") if Globals.has_method("get") and Globals.get("projectile_speed_boost") != null else 1.0
	projectile.speed = 300.0 * speed_multiplier
	# 标记为充能技能投射物，禁用DA/TA触发
	projectile.set("is_charge_ability", true)
	
	Globals.projectilesNode.add_child(projectile)
	projectile.position = tower.position
	projectile.target = target_pos

func _on_tower_placed(tower: Turret):
	initialize_tower_charge(tower)

func _on_tower_removed(tower: Turret):
	if tower:
		tower_charges.erase(tower.get_instance_id())

func set_charge_multiplier(multiplier: float):
	charge_speed_multiplier = multiplier