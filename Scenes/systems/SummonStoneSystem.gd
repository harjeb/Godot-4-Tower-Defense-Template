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
	var duration = stone_data.get("duration") if stone_data.has("duration") else 15.0
	var multiplier = stone_data.get("damage_multiplier") if stone_data.has("damage_multiplier") else 2.5
	
	for tower in all_towers:
		if is_instance_valid(tower):
			var original_damage = tower.damage
			tower.damage *= multiplier
			# Restore after duration
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(tower):
				tower.damage = original_damage

func apply_targeted_damage(stone_data: Dictionary, position: Vector2):
	var damage = stone_data.get("damage") if stone_data.has("damage") else 2000
	var range_val = stone_data.get("range") if stone_data.has("range") else 150.0
	var element = stone_data.get("element") if stone_data.has("element") else "light"
	
	var enemies = get_enemies_in_range(position, range_val)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.get_damage(damage)

func apply_freeze_damage(stone_data: Dictionary, position: Vector2):
	var damage = stone_data.get("damage") if stone_data.has("damage") else 1200
	var range_val = stone_data.get("range") if stone_data.has("range") else 180.0
	var freeze_duration = stone_data.get("freeze_duration") if stone_data.has("freeze_duration") else 2.0
	
	var enemies = get_enemies_in_range(position, range_val)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.get_damage(damage)
			apply_freeze_effect(enemy, freeze_duration)

func apply_charge_and_damage(stone_data: Dictionary):
	var charge_bonus = stone_data.get("charge_bonus") if stone_data.has("charge_bonus") else 30
	var damage_bonus = stone_data.get("damage_bonus") if stone_data.has("damage_bonus") else 0.30
	var duration = stone_data.get("duration") if stone_data.has("duration") else 5.0
	
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
	var damage = stone_data.get("damage") if stone_data.has("damage") else 1500
	var range_val = stone_data.get("range") if stone_data.has("range") else 200.0
	
	var enemies = get_enemies_in_range(position, range_val)
	for enemy in enemies:
		if is_instance_valid(enemy):
			dispel_enemy_buffs(enemy)
			enemy.get_damage(damage)

func get_all_towers() -> Array:
	var towers: Array = []
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