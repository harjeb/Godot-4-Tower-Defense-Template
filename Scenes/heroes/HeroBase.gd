class_name HeroBase
extends Node2D

## Core Hero system - base class for all heroes
## Handles stats, skills, charge system, talents, and integration with existing systems

signal hero_died(hero: HeroBase)
signal hero_respawned(hero: HeroBase)
signal hero_leveled_up(hero: HeroBase, new_level: int)
signal skill_cast(hero: HeroBase, skill: HeroSkill)
signal charge_changed(current_charge: float, max_charge: int)
signal experience_gained(hero: HeroBase, experience: int, new_total: int)

# Hero identification and state
@export var hero_type: String = ""
@export var hero_name: String = ""
@export var element: String = "neutral"

# Level and progression system
var current_level: int = 1
var experience_points: int = 0
var experience_required: Array[int] = [0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700, 3250, 3850, 4500, 5200, 5950]

# Health and combat state
var is_alive: bool = true
var respawn_timer: float = 0.0
var respawn_duration: float = 10.0
var is_respawning: bool = false

# Stats system - base stats from data, current stats after modifications
var base_stats: Dictionary = {}
var current_stats: Dictionary = {}
var stat_modifiers: Dictionary = {}

# Charge and skill system
var max_charge: int = 100
var current_charge: float = 0.0
var charge_generation_rate: float = 2.0
var skill_charge_paused: bool = false

# Skill management
var skills: Array[HeroSkill] = []
var skill_queue: Array[String] = []
var current_casting_skill: HeroSkill = null
var skill_cast_timer: float = 0.0
var auto_cast_enabled: bool = true

# Talent system
var talent_selections: Dictionary = {} # level -> talent_id
var available_talents: Array = []
var pending_talent_selection: bool = false

# Integration with existing systems
var gem_effect_system: GemEffectSystem
var da_bonus: float = 0.0  # Damage amplification bonus
var ta_bonus: float = 0.0  # Total amplification bonus

# Visual and UI components
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var charge_bar: ProgressBar = $UI/ChargeBar
@onready var level_label: Label = $UI/LevelLabel
@onready var casting_indicator: Control = $UI/CastingIndicator
@onready var respawn_indicator: Control = $UI/RespawnIndicator

# Combat and targeting
var attack_target: Node = null
var attack_timer: float = 0.0
var last_attack_time: float = 0.0

func _ready() -> void:
	# Set up node groups
	add_to_group("heroes")
	add_to_group("hero_units")
	
	# Initialize systems
	setup_hero_data()
	setup_gem_effect_system()
	setup_ui_components()
	
	# Connect to global signals
	# Note: Globals reference removed to avoid compilation error

func _process(delta: float) -> void:
	if is_respawning:
		process_respawn(delta)
		return
	
	if not is_alive:
		return
	
	# Update charge generation
	process_charge_generation(delta)
	
	# Update skill system
	process_skill_system(delta)
	
	# Update combat targeting
	process_combat_targeting(delta)
	
	# Update UI
	update_ui_components()

func setup_hero_data() -> void:
	"""Initialize hero with data from Data.gd"""
	if hero_type.is_empty():
		push_error("Hero type not set for hero: " + name)
		return
	
	if not Data.heroes.has(hero_type):
		push_error("Hero type not found in data: " + hero_type)
		return
	
	var hero_data = Data.heroes[hero_type]
	
	# Set basic properties
	hero_name = hero_data.get("name", hero_type)
	element = hero_data.get("element", "neutral")
	
	# Initialize base stats
	base_stats = hero_data.get("base_stats", {}).duplicate(true)
	current_stats = base_stats.duplicate(true)
	
	# Initialize charge system
	max_charge = hero_data.get("max_charge", 100)
	charge_generation_rate = hero_data.get("charge_generation", 2.0)
	current_charge = 0.0
	
	# Initialize skills
	setup_skills(hero_data.get("skills", []))
	
	# Set visual assets
	var sprite_path = hero_data.get("sprite", "")
	if not sprite_path.is_empty() and sprite:
		var texture = Data.load_resource_safe(sprite_path, "Texture2D")
		if texture:
			sprite.texture = texture

func setup_skills(skill_ids: Array) -> void:
	"""Initialize hero skills from skill IDs"""
	skills.clear()
	
	for skill_id in skill_ids:
		if not Data.hero_skills.has(skill_id):
			push_warning("Skill not found: " + skill_id)
			continue
		
		var skill_data = Data.hero_skills[skill_id]
		var skill = HeroSkill.new()
		skill.initialize_from_data(skill_id, skill_data)
		skills.append(skill)
	
	# Sort skills by priority (C > B > A)
	skills.sort_custom(func(a, b): return a.get_skill_priority() > b.get_skill_priority())

func setup_gem_effect_system() -> void:
	"""Connect to the GemEffectSystem"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
	
	gem_effect_system = tree.current_scene.get_node_or_null("GemEffectSystem") as GemEffectSystem
	if not gem_effect_system:
		# Try to find in main scene
		var main = tree.current_scene.get_node_or_null("Main")
		if main:
			gem_effect_system = main.get_node_or_null("GemEffectSystem") as GemEffectSystem

func setup_ui_components() -> void:
	"""Initialize UI components"""
	if health_bar:
		health_bar.max_value = current_stats.get("max_hp", 100)
		health_bar.value = health_bar.max_value
	
	if charge_bar:
		charge_bar.max_value = max_charge
		charge_bar.value = 0
	
	if level_label:
		level_label.text = "Lv." + str(current_level)
	
	if casting_indicator:
		casting_indicator.visible = false
	
	if respawn_indicator:
		respawn_indicator.visible = false

func process_charge_generation(delta: float) -> void:
	"""Update charge generation and skill casting"""
	if skill_charge_paused or current_casting_skill:
		return
	
	# Generate charge
	current_charge = min(current_charge + charge_generation_rate * delta, max_charge)
	charge_changed.emit(current_charge, max_charge)
	
	# Auto-cast skills if enabled
	if auto_cast_enabled:
		attempt_skill_cast()

func process_skill_system(delta: float) -> void:
	"""Process active skill casting and cooldowns"""
	# Update skill cooldowns
	for skill in skills:
		skill.update_cooldown(delta)
	
	# Process current casting skill
	if current_casting_skill:
		skill_cast_timer -= delta
		if skill_cast_timer <= 0:
			finish_skill_cast()
	
	# Process skill queue
	if skill_queue.size() > 0 and not current_casting_skill:
		var next_skill_id = skill_queue[0]
		skill_queue.remove_at(0)
		
		var skill = get_skill_by_id(next_skill_id)
		if skill and skill.can_cast(self):
			start_skill_cast(skill)

func process_combat_targeting(delta: float) -> void:
	"""Update combat targeting and basic attacks"""
	attack_timer += delta
	
	if not attack_target or not is_instance_valid(attack_target):
		find_attack_target()
	
	if attack_target and attack_timer >= get_attack_cooldown():
		perform_basic_attack()
		attack_timer = 0.0

func process_respawn(delta: float) -> void:
	"""Handle respawn countdown"""
	respawn_timer -= delta
	
	if respawn_indicator:
		var time_left = ceil(respawn_timer)
		respawn_indicator.get_child(0).text = "Respawn: " + str(time_left) + "s"
	
	if respawn_timer <= 0:
		respawn()

func attempt_skill_cast() -> void:
	"""Try to cast the highest priority available skill"""
	if current_casting_skill:
		return
	
	var available_skills = skills.filter(func(s): return s.can_cast(self))
	if available_skills.is_empty():
		return
	
	# Skills are already sorted by priority
	var best_skill = available_skills[0]
	start_skill_cast(best_skill)

func start_skill_cast(skill: HeroSkill) -> void:
	"""Begin casting a skill"""
	if not skill or not skill.can_cast(self):
		return
	
	# Consume charge
	current_charge -= skill.charge_cost
	current_charge = max(0, current_charge)
	
	# Set casting state
	current_casting_skill = skill
	skill_cast_timer = skill.get_cast_time()
	
	# Visual feedback
	if casting_indicator:
		casting_indicator.visible = true
		casting_indicator.get_child(0).text = skill.skill_name
	
	# Start cooldown
	skill.start_cooldown()
	
	# Execute skill effect immediately or after cast time
	if skill_cast_timer <= 0:
		finish_skill_cast()
	
	skill_cast.emit(self, skill)

func finish_skill_cast() -> void:
	"""Complete skill casting and execute effects"""
	if not current_casting_skill:
		return
	
	var skill = current_casting_skill
	
	# Execute skill effects
	execute_skill_effects(skill)
	
	# Clean up casting state
	current_casting_skill = null
	skill_cast_timer = 0.0
	
	if casting_indicator:
		casting_indicator.visible = false

func execute_skill_effects(skill: HeroSkill) -> void:
	"""Execute the effects of a cast skill"""
	if not skill:
		return
	
	# Find target position (for now use hero position, can be enhanced for targeting)
	var target_position = global_position
	
	# Execute skill-specific effects
	match skill.skill_id:
		"shadow_strike":
			execute_shadow_strike(skill, target_position)
		"flame_armor":
			execute_flame_armor(skill)
		"flame_phantom":
			execute_flame_phantom(skill)
		_:
			push_warning("Unknown skill: " + skill.skill_id)

func execute_shadow_strike(skill: HeroSkill, target_pos: Vector2) -> void:
	"""Execute Shadow Strike skill effects"""
	var skill_data = Data.hero_skills.get("shadow_strike", {})
	var damage_base = skill_data.get("damage_base", 70)
	var damage_scaling = skill_data.get("damage_scaling", 1.0)
	var effect_radius = skill_data.get("effect_radius", 150.0)
	var attack_count = skill_data.get("attack_count", 5)
	var attack_interval = skill_data.get("attack_interval", 0.3)
	var invulnerable_duration = skill_data.get("invulnerable_duration", 0.3)
	
	# Apply invulnerability
	if gem_effect_system:
		gem_effect_system.apply_effect(self, "invulnerable", invulnerable_duration)
	
	# Calculate total damage
	var total_damage = damage_base + (current_stats.get("damage", 0) * damage_scaling)
	
	# Execute multiple attacks with delay
	start_shadow_strike_attacks(target_pos, effect_radius, total_damage / attack_count, attack_count, attack_interval)

func start_shadow_strike_attacks(target_pos: Vector2, radius: float, damage: float, attack_count: int, attack_interval: float) -> void:
	"""Start shadow strike attacks with delays"""
	var attacks_remaining = attack_count
	execute_next_shadow_strike_attack(target_pos, radius, damage, attacks_remaining, attack_interval)

func execute_next_shadow_strike_attack(target_pos: Vector2, radius: float, damage: float, attacks_remaining: int, attack_interval: float) -> void:
	"""Execute next shadow strike attack with delay"""
	if attacks_remaining <= 0:
		return
	
	# Execute current attack
	call_deferred("perform_shadow_strike_attack", target_pos, radius, damage)
	
	# Schedule next attack if any remain
	if attacks_remaining > 1:
		var timer = Timer.new()
		timer.wait_time = attack_interval
		timer.one_shot = true
		timer.timeout.connect(func(): 
			execute_next_shadow_strike_attack(target_pos, radius, damage, attacks_remaining - 1, attack_interval)
			timer.queue_free()
		)
		add_child(timer)
		timer.start()

func perform_shadow_strike_attack(center: Vector2, radius: float, damage: float) -> void:
	"""Perform single shadow strike attack"""
	if not gem_effect_system:
		return
	
	var enemies = gem_effect_system.get_enemies_in_area(center, radius)
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, element)

func execute_flame_armor(skill: HeroSkill) -> void:
	"""Execute Flame Armor skill effects"""
	var skill_data = Data.hero_skills.get("flame_armor", {})
	var duration = skill_data.get("duration", 15.0)
	var defense_bonus = skill_data.get("defense_bonus", 15)
	var shield_amount = skill_data.get("shield_amount", 500)
	var aura_radius = skill_data.get("aura_radius", 200.0)
	var aura_damage = skill_data.get("aura_damage", 30.0)
	
	# Apply defense bonus
	apply_stat_modifier("defense", defense_bonus, duration)
	
	# Apply shield
	if has_method("add_shield"):
		add_shield(shield_amount)
	
	# Apply damage aura
	if gem_effect_system:
		gem_effect_system.apply_effect(self, "flame_aura", duration)
		# Store aura data for processing
		set_meta("flame_aura_radius", aura_radius)
		set_meta("flame_aura_damage", aura_damage)

func execute_flame_phantom(skill: HeroSkill) -> void:
	"""Execute Flame Phantom skill effects"""
	var skill_data = Data.hero_skills.get("flame_phantom", {})
	var duration = skill_data.get("duration", 30.0)
	var phantom_damage = skill_data.get("phantom_damage", 200)
	var phantom_attack_speed = skill_data.get("phantom_attack_speed", 1.7)
	var phantom_range = skill_data.get("phantom_range", 350.0)
	var aura_radius = skill_data.get("aura_radius", 250.0)
	var aura_damage = skill_data.get("aura_damage", 65.0)
	var burn_stacks = skill_data.get("burn_stacks", 3)
	
	# Create phantom summon
	create_flame_phantom(duration, phantom_damage, phantom_attack_speed, phantom_range)
	
	# Apply enhanced damage aura
	if gem_effect_system:
		gem_effect_system.apply_effect(self, "enhanced_flame_aura", duration)
		set_meta("enhanced_aura_radius", aura_radius)
		set_meta("enhanced_aura_damage", aura_damage)
		set_meta("enhanced_aura_burn_stacks", burn_stacks)

func create_flame_phantom(duration: float, damage: float, attack_speed: float, range: float) -> void:
	"""Create a flame phantom summon"""
	# Create phantom node
	var phantom = Node2D.new()
	phantom.name = "FlamePhantom"
	phantom.position = global_position + Vector2(50, 0) # Offset from hero
	
	# Add phantom to scene
	get_parent().add_child(phantom)
	phantom.add_to_group("hero_summons")
	
	# Store phantom data
	phantom.set_meta("damage", damage)
	phantom.set_meta("attack_speed", attack_speed)
	phantom.set_meta("range", range)
	phantom.set_meta("owner_hero", self)
	
	# Set up phantom timer
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): phantom.queue_free())
	phantom.add_child(timer)
	timer.start()

func find_attack_target() -> void:
	"""Find the nearest enemy within attack range"""
	if not gem_effect_system:
		return
	
	var attack_range = current_stats.get("attack_range", 150.0)
	var nearest_enemy = gem_effect_system.get_nearest_enemy(global_position, attack_range)
	
	if nearest_enemy and is_instance_valid(nearest_enemy):
		attack_target = nearest_enemy

func perform_basic_attack() -> void:
	"""Perform basic attack on current target"""
	if not attack_target or not is_instance_valid(attack_target):
		return
	
	var damage = current_stats.get("damage", 0)
	
	# Apply DA/TA bonuses
	damage *= (1.0 + da_bonus + ta_bonus)
	
	if attack_target.has_method("take_damage"):
		attack_target.take_damage(damage, element)
		last_attack_time = Time.get_time_dict_from_system()["unix"]

func get_attack_cooldown() -> float:
	"""Get current attack cooldown based on attack speed"""
	var base_cooldown = 1.0
	var attack_speed = current_stats.get("attack_speed", 1.0)
	return base_cooldown / attack_speed

func take_damage(damage: float, damage_type: String = "") -> void:
	"""Handle taking damage"""
	if not is_alive or gem_effect_system and gem_effect_system.has_effect(self, "invulnerable"):
		return
	
	# Apply defense reduction
	var defense = current_stats.get("defense", 0)
	var reduced_damage = max(1, damage - defense)
	
	# Update health
	var current_hp = health_bar.value if health_bar else current_stats.get("max_hp", 100)
	current_hp -= reduced_damage
	
	if health_bar:
		health_bar.value = current_hp
	
	# Check for death
	if current_hp <= 0:
		die()

func die() -> void:
	"""Handle hero death"""
	if not is_alive:
		return
	
	is_alive = false
	is_respawning = true
	respawn_timer = respawn_duration
	
	# Clear current state
	current_casting_skill = null
	skill_cast_timer = 0.0
	attack_target = null
	skill_queue.clear()
	
	# Visual feedback
	if sprite:
		sprite.modulate.a = 0.5
	
	if respawn_indicator:
		respawn_indicator.visible = true
	
	# Clear effects
	if gem_effect_system:
		gem_effect_system.clear_all_effects(self)
	
	hero_died.emit(self)

func respawn() -> void:
	"""Handle hero respawn"""
	if is_alive:
		return
	
	is_alive = true
	is_respawning = false
	respawn_timer = 0.0
	
	# Restore health
	var max_hp = current_stats.get("max_hp", 100)
	if health_bar:
		health_bar.value = max_hp
	
	# Restore visual
	if sprite:
		sprite.modulate.a = 1.0
	
	if respawn_indicator:
		respawn_indicator.visible = false
	
	hero_respawned.emit(self)

func gain_experience(amount: int) -> void:
	"""Add experience and check for level up"""
	experience_points += amount
	experience_gained.emit(self, amount, experience_points)
	
	check_level_up()

func check_level_up() -> void:
	"""Check if hero should level up"""
	if current_level >= experience_required.size():
		return # Max level reached
	
	var required_exp = experience_required[current_level]
	if experience_points >= required_exp:
		level_up()

func level_up() -> void:
	"""Level up the hero"""
	current_level += 1
	
	# Update stats based on level
	apply_level_stat_bonuses()
	
	# Check for talent selection
	if should_offer_talent_selection():
		pending_talent_selection = true
		available_talents = get_talent_options_for_level()
	
	# Update UI
	if level_label:
		level_label.text = "Lv." + str(current_level)
	
	hero_leveled_up.emit(self, current_level)

func should_offer_talent_selection() -> bool:
	"""Check if this level offers talent selection"""
	return current_level in [5, 10, 15] and not talent_selections.has(current_level)

func get_talent_options_for_level() -> Array:
	"""Get available talent options for current level"""
	if not Data.hero_talents.has(hero_type):
		return []
	
	var hero_talents = Data.hero_talents[hero_type]
	return hero_talents.get("level_" + str(current_level), [])

func apply_talent(talent_id: String) -> void:
	"""Apply selected talent"""
	talent_selections[current_level] = talent_id
	pending_talent_selection = false
	available_talents.clear()
	
	# Apply talent effects (implementation would depend on specific talents)
	var talent_system = get_hero_talent_system()
	if talent_system:
		talent_system.apply_talent(self, talent_id)

func get_hero_talent_system() -> HeroTalentSystem:
	"""Get reference to hero talent system"""
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return null
	
	return tree.current_scene.get_node_or_null("HeroTalentSystem") as HeroTalentSystem

func apply_level_stat_bonuses() -> void:
	"""Apply stat bonuses from leveling up"""
	# Basic stat growth per level (can be customized per hero type)
	var growth_rates = {
		"max_hp": 25,
		"damage": 3,
		"defense": 1,
		"attack_speed": 0.05
	}
	
	for stat in growth_rates:
		if current_stats.has(stat):
			current_stats[stat] += growth_rates[stat]

func apply_stat_modifier(stat_name: String, value: float, duration: float) -> void:
	"""Apply temporary stat modifier"""
	if not stat_modifiers.has(stat_name):
		stat_modifiers[stat_name] = []
	
	var modifier = {
		"value": value,
		"duration": duration,
		"remaining": duration
	}
	
	stat_modifiers[stat_name].append(modifier)
	update_current_stats()

func update_current_stats() -> void:
	"""Recalculate current stats with modifiers"""
	current_stats = base_stats.duplicate(true)
	
	# Apply level bonuses
	var level_bonus = (current_level - 1)
	current_stats["max_hp"] += level_bonus * 25
	current_stats["damage"] += level_bonus * 3
	current_stats["defense"] += level_bonus * 1
	current_stats["attack_speed"] += level_bonus * 0.05
	
	# Apply temporary modifiers
	for stat_name in stat_modifiers:
		var total_modifier = 0.0
		for modifier in stat_modifiers[stat_name]:
			total_modifier += modifier.value
		
		if current_stats.has(stat_name):
			current_stats[stat_name] += total_modifier

func update_ui_components() -> void:
	"""Update UI elements"""
	if health_bar:
		health_bar.max_value = current_stats.get("max_hp", 100)
	
	if charge_bar:
		charge_bar.value = current_charge

func get_skill_by_id(skill_id: String) -> HeroSkill:
	"""Get skill by its ID"""
	for skill in skills:
		if skill.skill_id == skill_id:
			return skill
	return null

func queue_skill(skill_id: String) -> void:
	"""Add skill to casting queue"""
	if skill_queue.find(skill_id) == -1: # Avoid duplicates
		skill_queue.append(skill_id)

func can_deploy_at_position(pos: Vector2) -> bool:
	"""Check if hero can be deployed at given position"""
	# Heroes can only be deployed on enemy paths
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return false
	
	var path_nodes = tree.current_scene.get_tree().get_nodes_in_group("enemy_path")
	for path_node in path_nodes:
		if path_node.global_position.distance_to(pos) < 50.0:
			return true
	
	return false

func _on_enemy_destroyed(remain: int) -> void:
	"""Handle enemy destruction for experience gain"""
	if is_alive and global_position.distance_to(get_viewport().get_mouse_position()) < 300.0:
		# Gain experience based on proximity to destroyed enemy
		gain_experience(10) # Base experience per kill

# Shield system (if needed)
var current_shield: float = 0.0
var max_shield: float = 0.0

func add_shield(amount: float) -> void:
	"""Add shield to hero"""
	current_shield += amount
	max_shield = max(max_shield, current_shield)

func _exit_tree() -> void:
	# Clean up any summoned phantoms
	var tree = get_tree()
	if tree and tree.current_scene:
		var phantoms = tree.current_scene.get_tree().get_nodes_in_group("hero_summons")
		for phantom in phantoms:
			if phantom.get_meta("owner_hero", null) == self:
				phantom.queue_free()