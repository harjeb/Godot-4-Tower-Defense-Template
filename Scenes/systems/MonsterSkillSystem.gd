class_name MonsterSkillSystem
extends Node

## Monster Skill System for Tower Defense Enhancement
## Manages monster skill effects and area-of-effect calculations

signal skill_triggered(enemy: Node2D, skill_name: String)
signal skill_effect_applied(target: Node2D, effect_name: String, duration: float)

# Performance optimization
var max_concurrent_effects = 10
var active_effects: Array[Dictionary] = []

func _ready():
	# Initialize skill system
	set_process(true)

func _process(delta):
	# Update active skill effects
	update_active_effects(delta)
	
	# Process monster skills for all enemies
	process_monster_skills(delta)

## Trigger frost aura skill
## @param enemy: The enemy casting the skill
func trigger_frost_aura(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	
	var skill_data = {
		"range": 100.0,
		"attack_speed_reduction": 0.20,
		"cd_recovery_reduction": 0.20,
		"duration": 3.0,
		"cooldown": 8.0
	}
	
	# Find towers in range
	var towers_in_range = get_towers_in_range(enemy.global_position, skill_data.range)
	
	# Apply frost effect to each tower
	for tower in towers_in_range:
		apply_frost_effect(tower, skill_data)
	
	# Create visual effect
	create_frost_aura_visual(enemy, skill_data)
	skill_triggered.emit(enemy, "frost_aura")

## Trigger acceleration skill
## @param enemy: The enemy casting the skill
func trigger_acceleration(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	
	var skill_data = {
		"range": 150.0,
		"speed_bonus": 0.50,
		"duration": 2.0,
		"cooldown": 5.0
	}
	
	# Find random ally in range
	var allies_in_range = get_enemies_in_range(enemy.global_position, skill_data.range)
	if allies_in_range.size() > 0:
		var target_ally = allies_in_range[randi() % allies_in_range.size()]
		apply_acceleration_effect(target_ally, skill_data)
		create_acceleration_visual(enemy, target_ally, skill_data)
	
	skill_triggered.emit(enemy, "acceleration")

## Trigger self-destruct skill
## @param enemy: The enemy self-destructing
func trigger_self_destruct(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	
	var skill_data = {
		"cast_time": 1.0,
		"range": 80.0,
		"stun_duration": 1.5,
		"hp_threshold": 0.10  # Trigger when HP < 10%
	}
	
	# Start cast sequence
	start_self_destruct_cast(enemy, skill_data)
	skill_triggered.emit(enemy, "self_destruct")

## Trigger petrification skill
## @param enemy: The enemy using petrification
func trigger_petrification(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	
	var skill_data = {
		"defense_multiplier": 6.0,  # +500% defense
		"duration": 3.0,
		"cooldown": 7.0
	}
	
	apply_petrification_effect(enemy, skill_data)
	create_petrification_visual(enemy, skill_data)
	skill_triggered.emit(enemy, "petrification")

## Apply frost effect to a tower
func apply_frost_effect(tower: Node, skill_data: Dictionary) -> void:
	if not is_instance_valid(tower):
		return
	
	var effect = {
		"type": "frost",
		"target": tower,
		"original_attack_speed": tower.attack_speed,
		"duration": skill_data.duration,
		"remaining_time": skill_data.duration,
		"attack_speed_reduction": skill_data.attack_speed_reduction
	}
	
	# Apply effect immediately
	tower.attack_speed *= (1.0 - skill_data.attack_speed_reduction)
	tower.modulate = Color(0.7, 0.9, 1.0)  # Frost tint
	
	add_active_effect(effect)
	skill_effect_applied.emit(tower, "frost", skill_data.duration)

## Apply acceleration effect to an enemy
func apply_acceleration_effect(enemy: Node2D, skill_data: Dictionary) -> void:
	if not is_instance_valid(enemy):
		return
	
	var effect = {
		"type": "acceleration",
		"target": enemy,
		"original_speed": enemy.speed,
		"duration": skill_data.duration,
		"remaining_time": skill_data.duration,
		"speed_bonus": skill_data.speed_bonus
	}
	
	# Apply effect immediately
	enemy.speed *= (1.0 + skill_data.speed_bonus)
	enemy.modulate = Color(1.5, 1.2, 0.8)  # Speed tint
	
	add_active_effect(effect)
	skill_effect_applied.emit(enemy, "acceleration", skill_data.duration)

## Start self-destruct casting sequence
func start_self_destruct_cast(enemy: Node2D, skill_data: Dictionary) -> void:
	if not is_instance_valid(enemy):
		return
	
	# Disable enemy movement during cast
	enemy.speed = 0.0
	enemy.modulate = Color.RED
	
	# Create cast visual
	create_self_destruct_cast_visual(enemy, skill_data)
	
	# Schedule explosion after cast time
	await get_tree().create_timer(skill_data.cast_time).timeout
	
	if is_instance_valid(enemy):
		execute_self_destruct(enemy, skill_data)

## Execute self-destruct explosion
func execute_self_destruct(enemy: Node2D, skill_data: Dictionary) -> void:
	# Find towers in explosion range
	var towers_in_range = get_towers_in_range(enemy.global_position, skill_data.range)
	
	# Apply stun effect to towers
	for tower in towers_in_range:
		apply_stun_effect(tower, skill_data)
	
	# Create explosion visual
	create_explosion_visual(enemy, skill_data)
	
	# Destroy the enemy
	enemy.queue_free()

## Apply petrification effect to enemy
func apply_petrification_effect(enemy: Node2D, skill_data: Dictionary) -> void:
	if not is_instance_valid(enemy):
		return
	
	var effect = {
		"type": "petrification",
		"target": enemy,
		"original_defense": enemy.defense,
		"duration": skill_data.duration,
		"remaining_time": skill_data.duration,
		"defense_multiplier": skill_data.defense_multiplier
	}
	
	# Apply effect immediately
	enemy.defense *= skill_data.defense_multiplier
	enemy.modulate = Color(0.7, 0.7, 0.7)  # Stone tint
	enemy.speed = 0.0  # Cannot move while petrified
	
	add_active_effect(effect)
	skill_effect_applied.emit(enemy, "petrification", skill_data.duration)

## Apply stun effect to tower
func apply_stun_effect(tower: Node, skill_data: Dictionary) -> void:
	if not is_instance_valid(tower):
		return
	
	var effect = {
		"type": "stun",
		"target": tower,
		"original_attack_speed": tower.attack_speed,
		"duration": skill_data.stun_duration,
		"remaining_time": skill_data.stun_duration
	}
	
	# Disable tower attacks
	tower.attack_speed = 0.0
	tower.modulate = Color(0.5, 0.5, 0.5)  # Stun tint
	
	add_active_effect(effect)
	skill_effect_applied.emit(tower, "stun", skill_data.stun_duration)

## Get towers within range of a position
func get_towers_in_range(center: Vector2, range: float) -> Array:
	var towers: Array = []
	
	# Use group-based approach for better flexibility
	var turret_nodes = get_tree().get_nodes_in_group("turret")
	for turret in turret_nodes:
		if turret.get_script() and turret.get_script().get_global_name() == "Turret" and turret.get("deployed"):
			if turret.global_position.distance_to(center) <= range:
				towers.append(turret)
	
	return towers

## Get enemies within range of a position
func get_enemies_in_range(center: Vector2, range: float) -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	
	# Find all enemies in scene
	var enemy_nodes = get_tree().get_nodes_in_group("enemy")
	for enemy in enemy_nodes:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= range:
			enemies.append(enemy)
	
	return enemies

## Add effect to active effects list
func add_active_effect(effect: Dictionary) -> void:
	if active_effects.size() >= max_concurrent_effects:
		# Remove oldest effect
		var oldest_effect = active_effects[0]
		remove_effect(oldest_effect)
		active_effects.remove_at(0)
	
	active_effects.append(effect)

## Update all active effects
func update_active_effects(delta: float) -> void:
	var effects_to_remove: Array[Dictionary] = []
	
	for effect in active_effects:
		effect.remaining_time -= delta
		
		if effect.remaining_time <= 0:
			effects_to_remove.append(effect)
	
	# Remove expired effects
	for effect in effects_to_remove:
		remove_effect(effect)
		active_effects.erase(effect)

## Remove effect and restore original values
func remove_effect(effect: Dictionary) -> void:
	if not is_instance_valid(effect.target):
		return
	
	match effect.type:
		"frost":
			if effect.has("original_attack_speed"):
				effect.target.attack_speed = effect.original_attack_speed
			effect.target.modulate = Color.WHITE
		"acceleration":
			if effect.has("original_speed"):
				effect.target.speed = effect.original_speed
			effect.target.modulate = Color.WHITE
		"petrification":
			if effect.has("original_defense"):
				effect.target.defense = effect.original_defense
			effect.target.modulate = Color.WHITE
			if effect.target.has("enemy_type"):
				var enemy_data = Data.enemies.get(effect.target.enemy_type) if Data.enemies.has(effect.target.enemy_type) else {}
				if enemy_data.has("stats") and enemy_data.stats.has("speed"):
					effect.target.speed = enemy_data.stats.get("speed") if enemy_data.stats.has("speed") else 1.0
		"stun":
			if effect.has("original_attack_speed"):
				effect.target.attack_speed = effect.original_attack_speed
			effect.target.modulate = Color.WHITE

## Process monster skills for all enemies
func process_monster_skills(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# Update skill timers
		for skill in enemy.monster_skills:
			if skill in enemy.skill_timers:
				enemy.skill_timers[skill] -= delta
				
				# Trigger skill if cooldown is ready
				if enemy.skill_timers[skill] <= 0:
					trigger_monster_skill(enemy, skill)
					# Reset cooldown
					if skill in enemy.skill_cooldowns:
						enemy.skill_timers[skill] = enemy.skill_cooldowns[skill]

## Trigger a specific monster skill
func trigger_monster_skill(enemy: Node2D, skill: String) -> void:
	match skill:
		"frost_aura":
			trigger_frost_aura(enemy)
		"acceleration":
			trigger_acceleration(enemy)
		"self_destruct":
			# Only trigger if HP is below threshold
			if enemy.has("hp"):
				var max_hp = enemy.max_hp if enemy.has("max_hp") else enemy.hp
				var current_hp = enemy.hp
				if max_hp > 0 and current_hp / max_hp < 0.10:
					trigger_self_destruct(enemy)
		"petrification":
			trigger_petrification(enemy)

## VISUAL EFFECT METHODS (simplified implementations)

func create_frost_aura_visual(enemy: Node2D, skill_data: Dictionary) -> void:
	var effect = preload("res://Scenes/effects/skill_effect.tscn").instantiate() if ResourceLoader.exists("res://Scenes/effects/skill_effect.tscn") else Label.new()
	if effect is Label:
		effect.text = "FROST"
		effect.modulate = Color.CYAN
		effect.position = Vector2(0, -30)
		enemy.add_child(effect)
		animate_text_effect(effect)

func create_acceleration_visual(enemy: Node2D, target: Node2D, skill_data: Dictionary) -> void:
	var effect = Label.new()
	effect.text = "SPEED!"
	effect.modulate = Color.YELLOW
	effect.position = Vector2(0, -30)
	target.add_child(effect)
	animate_text_effect(effect)

func create_self_destruct_cast_visual(enemy: Node2D, skill_data: Dictionary) -> void:
	var effect = Label.new()
	effect.text = "EXPLODING..."
	effect.modulate = Color.RED
	effect.position = Vector2(0, -30)
	enemy.add_child(effect)
	# Don't animate - keep visible during cast

func create_explosion_visual(enemy: Node2D, skill_data: Dictionary) -> void:
	var effect = Label.new()
	effect.text = "BOOM!"
	effect.modulate = Color.ORANGE_RED
	effect.position = enemy.global_position
	get_tree().current_scene.add_child(effect)
	animate_text_effect(effect)

func create_petrification_visual(enemy: Node2D, skill_data: Dictionary) -> void:
	var effect = Label.new()
	effect.text = "STONE"
	effect.modulate = Color.GRAY
	effect.position = Vector2(0, -30)
	enemy.add_child(effect)
	animate_text_effect(effect)

func animate_text_effect(label: Label) -> void:
	var tween = create_tween()
	tween.parallel().tween_property(label, "position", label.position + Vector2(0, -30), 2.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0)
	tween.tween_callback(label.queue_free)

# Add dispel functionality for summon stones
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