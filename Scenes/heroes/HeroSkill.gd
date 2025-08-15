class_name HeroSkill
extends Resource

## Hero Skill resource class
## Defines skill properties, casting requirements, and priority system

signal cooldown_finished(skill: HeroSkill)

# Core skill identification
@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_type: String = "A" # A, B, or C type skills
@export var description: String = ""

# Casting requirements and costs
@export var charge_cost: int = 20
@export var cooldown: float = 5.0
@export var cast_time: float = 0.0 # Time to cast (0 = instant)
@export var cast_range: float = 0.0 # 0 = self-cast or auto-target

# Skill state
var is_on_cooldown: bool = false
var cooldown_remaining: float = 0.0
var last_cast_time: float = 0.0

# Skill priority mapping (higher number = higher priority)
const SKILL_PRIORITIES = {
	"C": 3, # Ultimate skills - highest priority
	"B": 2, # Major skills - medium priority  
	"A": 1  # Basic skills - lowest priority
}

# Skill data storage for dynamic properties
var skill_data: Dictionary = {}

func initialize_from_data(id: String, data: Dictionary) -> void:
	"""Initialize skill from data dictionary"""
	skill_id = id
	skill_name = data.get("name", id)
	skill_type = data.get("type", "A")
	description = data.get("description", "")
	
	charge_cost = data.get("charge_cost", 20)
	cooldown = data.get("cooldown", 5.0)
	cast_time = data.get("cast_time", 0.0)
	cast_range = data.get("cast_range", 0.0)
	
	# Store complete data for skill execution
	skill_data = data.duplicate(true)
	
	# Reset state
	is_on_cooldown = false
	cooldown_remaining = 0.0
	last_cast_time = 0.0

func can_cast(hero: HeroBase) -> bool:
	"""Check if skill can be cast by the hero"""
	if not hero or not hero.is_alive:
		return false
	
	# Check cooldown
	if is_on_cooldown:
		return false
	
	# Check charge requirement
	if hero.current_charge < charge_cost:
		return false
	
	# Check if hero is already casting
	if hero.current_casting_skill:
		return false
	
	# Skill-specific casting requirements
	return check_skill_specific_requirements(hero)

func check_skill_specific_requirements(hero: HeroBase) -> bool:
	"""Check skill-specific casting requirements"""
	match skill_id:
		"shadow_strike":
			# Can always cast Shadow Strike
			return true
		
		"flame_armor":
			# Can cast if not already active
			return not has_flame_armor_active(hero)
		
		"flame_phantom":
			# Can cast if no phantom already summoned
			return not has_active_phantom(hero)
		
		"tough_skin":
			# 被动技能始终可用
			return true
		
		"flame_sword":
			# 需要有攻击目标才能激活
			return hero.attack_target != null and is_instance_valid(hero.attack_target)
		
		"loyalty_reward":
			# 需要有其他火/光英雄才有意义
			return has_fire_or_light_heroes(hero)
		
		"meteor_impact":
			# 需要前方有效目标区域
			return has_valid_target_area(hero)
		
		_:
			# Default: can always cast
			return true

func has_flame_armor_active(hero: HeroBase) -> bool:
	"""Check if hero already has Flame Armor active"""
	if not hero.gem_effect_system:
		return false
	
	return hero.gem_effect_system.has_effect(hero, "flame_armor")

func has_active_phantom(hero: HeroBase) -> bool:
	"""Check if hero has an active phantom summon"""
	var tree = hero.get_tree()
	if not tree or not tree.current_scene:
		return false
	
	var phantoms = tree.current_scene.get_tree().get_nodes_in_group("hero_summons")
	for phantom in phantoms:
		if phantom.get_meta("owner_hero", null) == hero:
			return true
	
	return false

func has_fire_or_light_heroes(hero: HeroBase) -> bool:
	"""Check if there are other fire/light heroes"""
	var tree = hero.get_tree()
	if not tree or not tree.current_scene:
		return false
	
	var heroes = tree.current_scene.get_tree().get_nodes_in_group("heroes")
	for other_hero in heroes:
		if other_hero != hero and other_hero.element in ["fire", "light"]:
			return true
	return false

func has_valid_target_area(hero: HeroBase) -> bool:
	"""Check if there is a valid target area for meteor impact"""
	# 简化实现，假设总是有有效目标区域
	return true

func start_cooldown() -> void:
	"""Start skill cooldown"""
	is_on_cooldown = true
	cooldown_remaining = cooldown
	last_cast_time = Time.get_time_dict_from_system()["unix"]

func update_cooldown(delta: float) -> void:
	"""Update cooldown timer"""
	if not is_on_cooldown:
		return
	
	cooldown_remaining -= delta
	if cooldown_remaining <= 0:
		finish_cooldown()

func finish_cooldown() -> void:
	"""Finish skill cooldown"""
	is_on_cooldown = false
	cooldown_remaining = 0.0
	cooldown_finished.emit(self)

func get_skill_priority() -> int:
	"""Get skill priority for auto-casting order"""
	return SKILL_PRIORITIES.get(skill_type, 1)

func get_cast_time() -> float:
	"""Get skill cast time"""
	return cast_time

func get_cooldown_progress() -> float:
	"""Get cooldown progress (0.0 to 1.0)"""
	if not is_on_cooldown:
		return 1.0
	
	return 1.0 - (cooldown_remaining / cooldown)

func get_skill_tooltip() -> String:
	"""Generate skill tooltip text"""
	var tooltip = skill_name + " (" + skill_type + ")\n"
	tooltip += description + "\n\n"
	tooltip += "Charge Cost: " + str(charge_cost) + "\n"
	tooltip += "Cooldown: " + str(cooldown) + "s"
	
	if cast_time > 0:
		tooltip += "\nCast Time: " + str(cast_time) + "s"
	
	if cast_range > 0:
		tooltip += "\nRange: " + str(cast_range)
	
	return tooltip

func get_damage_value(hero: HeroBase, damage_key: String = "damage_base") -> float:
	"""Calculate damage value with hero scaling"""
	if not skill_data.has(damage_key):
		return 0.0
	
	var base_damage = skill_data.get(damage_key, 0.0)
	var scaling_key = damage_key.replace("_base", "_scaling")
	var scaling = skill_data.get(scaling_key, 0.0)
	
	if not hero:
		return base_damage
	
	var hero_damage = hero.current_stats.get("damage", 0)
	return base_damage + (hero_damage * scaling)

func get_area_of_effect() -> float:
	"""Get skill area of effect radius"""
	return skill_data.get("effect_radius", 0.0)

func get_duration() -> float:
	"""Get skill effect duration"""
	return skill_data.get("duration", 0.0)

func is_targeted_skill() -> bool:
	"""Check if skill requires targeting"""
	return cast_range > 0.0

func is_instant_cast() -> bool:
	"""Check if skill casts instantly"""
	return cast_time <= 0.0

func get_skill_icon_path() -> String:
	"""Get path to skill icon"""
	return skill_data.get("icon", "res://Assets/skills/" + skill_id + ".png")

func get_skill_effects() -> Array:
	"""Get list of effects this skill applies"""
	return skill_data.get("effects", [])

func get_mana_cost_reduction(hero: HeroBase) -> int:
	"""Calculate charge cost reduction from talents/items"""
	# Base implementation - can be extended for talent system
	return 0

func get_cooldown_reduction(hero: HeroBase) -> float:
	"""Calculate cooldown reduction from talents/items"""
	# Base implementation - can be extended for talent system
	return 0.0

func get_damage_multiplier(hero: HeroBase) -> float:
	"""Get damage multiplier from talents/items"""
	# Base implementation - can be extended for talent system
	var multiplier = 1.0
	
	# Apply DA/TA bonuses to skills
	if hero:
		multiplier *= (1.0 + hero.da_bonus + hero.ta_bonus)
	
	return multiplier

func validate_skill_data() -> bool:
	"""Validate that skill has required data"""
	if skill_id.is_empty():
		push_error("Skill has empty ID")
		return false
	
	if skill_name.is_empty():
		push_warning("Skill " + skill_id + " has empty name")
	
	if charge_cost < 0:
		push_error("Skill " + skill_id + " has negative charge cost")
		return false
	
	if cooldown < 0:
		push_error("Skill " + skill_id + " has negative cooldown")
		return false
	
	if not skill_type in ["A", "B", "C"]:
		push_error("Skill " + skill_id + " has invalid type: " + skill_type)
		return false
	
	return true

func create_skill_effect_at_position(position: Vector2, hero: HeroBase) -> void:
	"""Create visual/audio effect at target position"""
	# This could be extended to create particle effects, sounds, etc.
	match skill_id:
		"shadow_strike":
			create_shadow_strike_effect(position)
		"flame_armor":
			create_flame_armor_effect(hero)
		"flame_phantom":
			create_flame_phantom_effect(position)

func create_shadow_strike_effect(position: Vector2) -> void:
	"""Create Shadow Strike visual effect"""
	# Placeholder for visual effect creation
	pass

func create_flame_armor_effect(hero: HeroBase) -> void:
	"""Create Flame Armor visual effect"""
	# Placeholder for visual effect creation
	pass

func create_flame_phantom_effect(position: Vector2) -> void:
	"""Create Flame Phantom visual effect"""
	# Placeholder for visual effect creation
	pass

func get_skill_range_indicator_data() -> Dictionary:
	"""Get data for displaying skill range indicators"""
	return {
		"cast_range": cast_range,
		"effect_radius": get_area_of_effect(),
		"skill_type": skill_type,
		"color": get_skill_type_color()
	}

func get_skill_type_color() -> Color:
	"""Get color associated with skill type"""
	match skill_type:
		"A":
			return Color.GREEN
		"B":
			return Color.YELLOW
		"C":
			return Color.RED
		_:
			return Color.WHITE

# Static utility functions for skill system
static func create_skill_from_id(skill_id: String) -> HeroSkill:
	"""Create skill instance from skill ID"""
	if not Data.hero_skills.has(skill_id):
		push_error("Skill data not found: " + skill_id)
		return null
	
	var skill = HeroSkill.new()
	var skill_data = Data.hero_skills[skill_id]
	skill.initialize_from_data(skill_id, skill_data)
	
	if not skill.validate_skill_data():
		push_error("Invalid skill data for: " + skill_id)
		return null
	
	return skill

static func get_all_skill_types() -> Array[String]:
	"""Get all available skill types"""
	return ["A", "B", "C"]

static func compare_skill_priority(skill_a: HeroSkill, skill_b: HeroSkill) -> bool:
	"""Compare skills by priority (for sorting)"""
	return skill_a.get_skill_priority() > skill_b.get_skill_priority()

static func filter_castable_skills(skills: Array[HeroSkill], hero: HeroBase) -> Array[HeroSkill]:
	"""Filter skills to only those that can be cast"""
	var castable: Array[HeroSkill] = []
	
	for skill in skills:
		if skill.can_cast(hero):
			castable.append(skill)
	
	return castable

static func get_highest_priority_skill(skills: Array[HeroSkill]) -> HeroSkill:
	"""Get the highest priority skill from an array"""
	if skills.is_empty():
		return null
	
	var highest_priority_skill = skills[0]
	for skill in skills:
		if skill.get_skill_priority() > highest_priority_skill.get_skill_priority():
			highest_priority_skill = skill
	
	return highest_priority_skill