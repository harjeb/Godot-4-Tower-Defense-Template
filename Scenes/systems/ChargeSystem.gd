class_name ChargeSystem
extends Node

signal charge_ability_triggered(tower: Node2D, ability_name: String)
signal charge_updated(tower: Node2D, current_charge: int)

var tower_charges: Dictionary = {}
var max_charge: int = 100
var charge_speed_multiplier: float = 1.0

# 充能增加规则
var charge_per_hit: int = 2  # 命中1个单位增加2点
var charge_per_second: int = 3  # 每秒增加3点
var passive_charge_timer: Timer

func _ready():
	if Globals.has_signal("turret_placed"):
		Globals.turret_placed.connect(_on_tower_placed)
	if Globals.has_signal("turret_removed"):  
		Globals.turret_removed.connect(_on_tower_removed)
	
	# 创建被动充能计时器
	setup_passive_charge_timer()

func setup_passive_charge_timer():
	# 创建被动充能计时器
	passive_charge_timer = Timer.new()
	passive_charge_timer.wait_time = 1.0  # 每秒触发
	passive_charge_timer.timeout.connect(_on_passive_charge_timeout)
	add_child(passive_charge_timer)
	passive_charge_timer.start()

func initialize_tower_charge(tower: Node2D):
	if not tower or not tower.deployed:
		return
	tower_charges[tower.get_instance_id()] = 0

func add_charge_on_hit(tower: Node2D):
	# 命中敌人时调用，增加2点充能
	add_charge(tower, charge_per_hit)

func add_charge(tower: Node2D, amount: int):
	if not tower or not tower.deployed:
		return
	
	var tower_id = tower.get_instance_id()
	if not tower_charges.has(tower_id):
		initialize_tower_charge(tower)
	
	# Apply charge speed multiplier from talents
	var charge_amount = int(amount * charge_speed_multiplier)
	
	tower_charges[tower_id] = min(tower_charges[tower_id] + charge_amount, max_charge)
	tower.current_charge = tower_charges[tower_id]  # Update tower's charge value
	charge_updated.emit(tower, tower_charges[tower_id])
	
	if tower_charges[tower_id] >= max_charge:
		trigger_charge_ability(tower)

func _on_passive_charge_timeout():
	# 每秒为所有有充能技能的塔增加3点充能
	var all_towers = get_all_towers()
	for tower in all_towers:
		if tower and tower.deployed and has_charge_ability(tower.turret_type):
			add_charge(tower, charge_per_second)

func trigger_charge_ability(tower: Node2D):
	if not tower or not has_charge_ability(tower.turret_type):
		return
	
	var tower_id = tower.get_instance_id()
	tower_charges[tower_id] = 0
	
	var ability_data = Data.charge_system.charge_abilities.get(tower.turret_type) if Data.charge_system.charge_abilities.has(tower.turret_type) else {}
	execute_charge_ability(tower, ability_data)
	charge_ability_triggered.emit(tower, ability_data.get("name") if ability_data.has("name") else "Unknown")

func execute_charge_ability(tower: Node2D, ability_data: Dictionary):
	match tower.turret_type:
		"arrow_tower":
			execute_arrow_rain(tower, ability_data)
		"capture_tower":
			execute_thorn_net(tower, ability_data)
		"mage_tower":
			execute_activation(tower, ability_data)

func has_charge_ability(tower_type: String) -> bool:
	return Data.charge_system.charge_abilities.has(tower_type)

func get_tower_charge(tower: Node2D) -> int:
	if not tower:
		return 0
	var tower_id = tower.get_instance_id()
	if tower_charges.has(tower_id):
		return tower_charges.get(tower_id)
	return 0

func execute_arrow_rain(tower: Node2D, ability_data: Dictionary):
	# Create multiple projectiles in target area
	var target_pos = tower.current_target.position if tower.current_target else tower.position
	var arrow_count = ability_data.get("arrow_count") if ability_data.has("arrow_count") else 15
	var damage_multiplier = ability_data.get("damage_multiplier") if ability_data.has("damage_multiplier") else 0.8
	
	for i in range(arrow_count):
		var offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))
		create_charge_projectile(tower, target_pos + offset, damage_multiplier)

func execute_thorn_net(tower: Node2D, ability_data: Dictionary):
	# Enhance capture tower's next few attacks
	var enhanced_range = tower.attack_range * (ability_data.get("range_multiplier") if ability_data.has("range_multiplier") else 2.0)
	var armor_reduction = ability_data.get("armor_reduction") if ability_data.has("armor_reduction") else 0.15
	tower.set("enhanced_capture", {"range": enhanced_range, "armor_reduction": armor_reduction, "duration": 5.0})

func execute_activation(tower: Node2D, ability_data: Dictionary):
	# Boost mage tower attack speed temporarily
	var speed_bonus = ability_data.get("speed_bonus") if ability_data.has("speed_bonus") else 0.30
	var duration = ability_data.get("duration") if ability_data.has("duration") else 3.0
	var original_speed = tower.attack_speed
	tower.attack_speed *= (1.0 + speed_bonus)
	
	# Restore after duration
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(tower):
		tower.attack_speed = original_speed

func create_charge_projectile(tower: Node2D, target_pos: Vector2, damage_multiplier: float):
	var projectileScene := preload("res://Scenes/turrets/projectileTurret/bullet/bulletBase.tscn")
	var projectile := projectileScene.instantiate()
	projectile.bullet_type = "fire"
	projectile.base_damage = tower.damage * damage_multiplier
	projectile.element = tower.element
	projectile.source_tower = tower  # 设置发射塔的引用
	# Apply projectile speed talent boost
	var speed_multiplier = 1.0
	if Globals.has_method("get") and Globals.get("projectile_speed_boost") != null:
		speed_multiplier = Globals.get("projectile_speed_boost")
	projectile.speed = 300.0 * speed_multiplier
	# 标记为充能技能投射物，禁用DA/TA触发
	projectile.set_meta("is_charge_ability", true)
	
	Globals.projectiles_node.add_child(projectile)
	projectile.position = tower.position
	projectile.target = target_pos

func _on_tower_placed(tower: Node2D):
	initialize_tower_charge(tower)

func _on_tower_removed(tower: Node2D):
	if tower:
		tower_charges.erase(tower.get_instance_id())

func get_all_towers() -> Array:
	var towers = []
	if get_tree() and get_tree().current_scene:
		var all_nodes = get_tree().get_nodes_in_group("turret")
		for node in all_nodes:
			if node.get_script() and node.get_script().get_global_name() == "Turret" and node.get("deployed"):
				towers.append(node)
	return towers

func set_charge_multiplier(multiplier: float):
	charge_speed_multiplier = multiplier