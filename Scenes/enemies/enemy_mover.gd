extends PathFollow2D

# 新增属性
var element: String = "neutral"
var special_abilities: Array = []
var defense: float = 0.0
var monster_skills: Array = []
var skill_cooldowns: Dictionary = {}
var skill_timers: Dictionary = {}
var is_stealthed: bool = false
var can_split: bool = false
var split_count: int = 0
var max_splits: int = 2
var can_heal: bool = false
var heal_cooldown: float = 7.0
var heal_timer: float = 0.0
var max_hp: float = 10.0

# Flight System
enum MovementType {
	GROUND,  # 地面单位，会被近战塔阻挡
	FLYING   # 飞行单位，不会被近战塔阻挡
}
var movement_type: MovementType = MovementType.GROUND
var flying_height: float = 0.0  # 飞行高度，用于视觉效果

# Physics system for ground units
var physics_body: PhysicsEnemyMover
var using_physics_mode: bool = false
var block_detection_area: Area2D
var last_physics_check: float = 0.0
var physics_check_interval: float = 0.2  # 每0.2秒检查一次是否需要物理模式

var enemy_type := "":
	set(val):
		enemy_type = val
		var enemy_data = Data.enemies[val]
		$Sprite2D.texture = load(enemy_data["sprite"])
		element = enemy_data.get("element") if enemy_data.has("element") else "neutral"
		special_abilities = enemy_data.get("special_abilities") if enemy_data.has("special_abilities") else []
		monster_skills = enemy_data.get("monster_skills") if enemy_data.has("monster_skills") else []
		skill_cooldowns = enemy_data.get("skill_cooldowns") if enemy_data.has("skill_cooldowns") else {}
		max_hp = enemy_data["stats"]["hp"]
		
		# Setup movement type (ground/flying)
		var movement_type_str = enemy_data.get("movement_type", "ground")
		movement_type = MovementType.FLYING if movement_type_str == "flying" else MovementType.GROUND
		flying_height = enemy_data.get("flying_height", 0.0)
		
		# Initialize skill timers
		for skill in monster_skills:
			if skill in skill_cooldowns:
				skill_timers[skill] = 0.0
		
		# 设置特殊能力
		setup_special_abilities()
		
		# Apply visual effects for flying units
		if movement_type == MovementType.FLYING:
			setup_flying_visual_effects()
		
		for stat in enemy_data["stats"].keys():
			set(stat, enemy_data["stats"][stat])

enum State {walking, damaged}
var state = State.walking
var goldYield := 10.0
var hp := 10.0
var baseDamage := 5.0
var speed := 1.0
var is_destroyed := false

# Ice Effect System
var speed_modifiers: Dictionary = {}
var frost_stacks: int = 0
var is_frozen: bool = false
var freeze_timer: float = 0.0
var freeze_duration: float = 0.0
var base_speed: float = 1.0

# Earth Effect System
var defense_modifiers: Dictionary = {}
var weight_stacks: int = 0
var armor_break_stacks: int = 0
var is_petrified: bool = false
var petrify_timer: float = 0.0
var petrify_duration: float = 0.0

# Shadow Effect System
var corrosion_stacks: int = 0
var is_feared: bool = false
var fear_timer: float = 0.0
var fear_duration: float = 0.0
var fear_miss_chance: float = 0.0
var life_drain_stacks: int = 0
var life_drain_timer: float = 0.0
var life_drain_duration: float = 0.0
var healing_reduction: float = 0.0
var no_healing: bool = false
var no_healing_timer: float = 0.0

@onready var spawner := get_parent() as EnemyPath
func _ready():
	add_to_group("enemy")
	# 初始化治疗计时器
	heal_timer = heal_cooldown
	
	# 创建HP条
	create_health_bar()
	
	# 为地面单位设置物理系统
	if movement_type == MovementType.GROUND:
		setup_physics_system()

func _process(delta):
	if state == State.walking:
		# Handle freeze timer
		if is_frozen and freeze_timer > 0:
			freeze_timer -= delta
			if freeze_timer <= 0:
				set_frozen(false)
		
		# Handle petrify timer
		if is_petrified and petrify_timer > 0:
			petrify_timer -= delta
			if petrify_timer <= 0:
				set_petrified(false)
		
		# 物理模式处理
		if movement_type == MovementType.GROUND and not using_physics_mode:
			# 定期检查是否需要切换到物理模式
			last_physics_check += delta
			if last_physics_check >= physics_check_interval:
				last_physics_check = 0.0
				check_for_blocking_towers()
		
		# 普通移动（如果不在物理模式且未冻结）
		if not using_physics_mode and not is_frozen:
			# Move
			progress_ratio += 0.0001 * speed
			if progress_ratio == 1:
				finished_path()
				return
		
		# Monster skill processing
		process_monster_skills(delta)
		
		# 治疗逻辑
		if can_heal:
			heal_timer -= delta
			if heal_timer <= 0 and hp < max_hp:
				heal_with_effects(max_hp * 0.1)
				heal_timer = heal_cooldown
		
		# Flip (只在非物理模式下处理)
		if not using_physics_mode:
			var angle = int(rotation_degrees) % 360
			if angle > 180:
				angle -= 360
			$Sprite2D.flip_v = abs(angle) > 90
		
		# Update light effects
		update_light_effects(delta)
		
		# Update shadow effects
		update_shadow_effects(delta)
		
		# Update wind effects
		update_wind_effects(delta)

func finished_path():
	if is_destroyed:
		return
	is_destroyed = true
	spawner.enemy_destroyed()
	Globals.current_map.get_base_damage(baseDamage)
	queue_free()

func get_damage(damage):
	if is_destroyed:
		return
	
	# Apply defense system damage reduction
	var final_damage = damage
	if defense > 0:
		final_damage = damage / (1 + defense/100.0)
	hp -= final_damage
	damage_animation()
	
	# 更新HP条
	update_health_bar()
	
	if hp <= 0:
		handle_death()

func handle_death():
	is_destroyed = true
	spawner.enemy_destroyed()
	Globals.current_map.gold += goldYield
	
	# 掉落物品
	var drop_item_id = LootSystem.roll_drop(Data.enemies[enemy_type])
	if drop_item_id != "":
		var drop = LootSystem.create_drop_item(drop_item_id, global_position)
		get_tree().current_scene.add_child(drop)
	
	# 分裂逻辑
	if can_split and split_count < max_splits:
		spawn_split_units()
	
	queue_free()

func damage_animation():
	var tween := create_tween()
	tween.tween_property(self, "v_offset", 0, 0.05)
	tween.tween_property(self, "modulate", Color.ORANGE_RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	tween.set_parallel()
	tween.tween_property(self, "v_offset", -5, 0.2)
	tween.set_parallel(false)
	tween.tween_property(self, "v_offset", 0, 0.2)

# 新增方法
func setup_special_abilities():
	for ability in special_abilities:
		match ability:
			"stealth":
				is_stealthed = true
				modulate.a = 0.5  # 半透明
			"split":
				can_split = true
			"heal":
				can_heal = true

func heal_with_effects(amount: float) -> void:
	heal(amount)
	# 显示治疗效果
	var heal_label = Label.new()
	heal_label.text = "+%.0f" % amount
	heal_label.modulate = Color.GREEN
	add_child(heal_label)
	# 治疗动画
	var tween = create_tween()
	tween.tween_property(heal_label, "position", Vector2(0, -30), 1.0)
	tween.tween_property(heal_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(heal_label.queue_free)

func spawn_split_units():
	for i in range(2):
		var split_enemy = preload("res://Scenes/enemies/enemy_mover.tscn").instantiate()
		split_enemy.enemy_type = enemy_type
		split_enemy.split_count = split_count + 1
		split_enemy.progress_ratio = progress_ratio
		split_enemy.hp = max_hp * 0.6  # 分裂后血量60%
		split_enemy.scale = Vector2(0.8, 0.8)  # 尺寸缩小
		spawner.add_child(split_enemy)

func get_is_stealthed() -> bool:
	return is_stealthed

func get_element() -> String:
	return element

func has_ability(ability_name: String) -> bool:
	return ability_name in special_abilities

func get_element_color() -> Color:
	return ElementSystem.get_element_color(element)

# Monster skill processing
func process_monster_skills(delta: float) -> void:
	# Update skill timers and trigger skills when ready
	for skill in monster_skills:
		if skill in skill_timers:
			skill_timers[skill] -= delta
			
			# Trigger skill if cooldown is ready
			if skill_timers[skill] <= 0:
				trigger_monster_skill(skill)
				# Reset cooldown
				if skill in skill_cooldowns:
					skill_timers[skill] = skill_cooldowns[skill]

func trigger_monster_skill(skill: String) -> void:
	var monster_skill_system = get_monster_skill_system()
	if not monster_skill_system:
		return
		
	match skill:
		"frost_aura":
			monster_skill_system.trigger_frost_aura(self)
		"acceleration":
			monster_skill_system.trigger_acceleration(self)
		"self_destruct":
			# Only trigger if HP is below threshold
			if hp / max_hp < 0.10:
				monster_skill_system.trigger_self_destruct(self)
		"petrification":
			monster_skill_system.trigger_petrification(self)

func get_monster_skill_system() -> MonsterSkillSystem:
	var tree = get_tree()
	if tree and tree.current_scene:
		return tree.current_scene.get_node_or_null("MonsterSkillSystem")
	return null

## Flight System Methods

# Check if this enemy is flying
func is_flying() -> bool:
	return movement_type == MovementType.FLYING

# Setup visual effects for flying units
func setup_flying_visual_effects() -> void:
	if movement_type != MovementType.FLYING:
		return
	
	# Offset sprite upward to show flying
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.position.y -= flying_height
		
		# Add slight transparency to indicate flying
		sprite.modulate.a = 0.9
		
		# Add floating animation
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "position:y", sprite.position.y - 3, 1.0)
		tween.tween_property(sprite, "position:y", sprite.position.y + 3, 1.0)

# Check if this unit can be blocked by a tower
func can_be_blocked_by_tower(tower: Node) -> bool:
	if not is_instance_valid(tower):
		return false
	
	# Flying units cannot be blocked by any tower
	if movement_type == MovementType.FLYING:
		return false
	
	# Ground units can only be blocked by melee towers
	return true

## Wind Element Effect System

# Imbalance effect variables
var is_imbalanced: bool = false
var imbalance_miss_chance: float = 0.30
var imbalance_duration: float = 0.0
var imbalance_timer: float = 0.0

# Silence effect variables
var is_silenced: bool = false
var silence_duration: float = 0.0
var silence_timer: float = 0.0

# Wind effect variables
var wind_speed_modifier: float = 1.0
var wind_attack_speed_modifier: float = 1.0
var wind_effect_timer: float = 0.0

# Set imbalance state
func set_imbalanced(imbalanced: bool, miss_chance: float = 0.30, duration: float = 0.0) -> void:
	if imbalanced == is_imbalanced:
		return
	
	is_imbalanced = imbalanced
	imbalance_miss_chance = miss_chance
	imbalance_duration = duration
	
	if is_imbalanced:
		imbalance_timer = duration
		# Add visual imbalance effect
		_add_imbalance_visual_effect()
	else:
		# Remove visual imbalance effect
		_remove_imbalance_visual_effect()

# Set silence state
func set_silenced(silenced: bool, duration: float = 0.0) -> void:
	if silenced == is_silenced:
		return
	
	is_silenced = silenced
	silence_duration = duration
	
	if is_silenced:
		silence_timer = duration
		# Prevent monster skills from triggering
		_update_effective_speed()
		# Add visual silence effect
		_add_silence_visual_effect()
	else:
		_update_effective_speed()
		# Remove visual silence effect
		_remove_silence_visual_effect()

# Apply knockback effect
func apply_knockback(force: float) -> void:
	if movement_type == MovementType.FLYING:
		# Flying units are knocked back further
		force *= 1.5
	
	# Calculate knockback direction (away from current facing)
	var knockback_direction = Vector2.RIGHT.rotated(rotation)
	var knockback_distance = force
	
	# Try to move back along the path
	var new_progress = progress_ratio - (knockback_distance / 100.0)
	new_progress = max(0.0, new_progress)
	progress_ratio = new_progress
	
	# Add visual knockback effect
	_add_knockback_visual_effect(knockback_direction)

# Apply wind speed modifier
func apply_wind_speed_modifier(source: String, multiplier: float) -> void:
	if source == "flying_debuff":
		wind_speed_modifier = multiplier
		_update_effective_speed()

# Apply wind attack speed modifier
func apply_attack_speed_modifier(source: String, multiplier: float) -> void:
	if source == "flying_debuff":
		wind_attack_speed_modifier = multiplier
		# This would need to be implemented in the attack system

# Special wind effects
func apply_exile(duration: float) -> void:
	# Remove from path temporarily
	visible = false
	is_imbalanced = true  # Can't attack while exiled
	
	# Create timer for return
	var exile_timer = Timer.new()
	exile_timer.wait_time = duration
	exile_timer.one_shot = true
	exile_timer.timeout.connect(_on_exile_end)
	add_child(exile_timer)
	exile_timer.start()
	
	# Add visual exile effect
	_add_exile_visual_effect()

func apply_imprison(duration: float) -> void:
	# Similar to freeze but different visual
	is_imbalanced = true
	imbalance_timer = duration
	
	# Stop movement
	_update_effective_speed()
	
	# Add visual prison effect
	_add_imprison_visual_effect()

func apply_hurricane(center: Vector2, duration: float, pull_force: float, damage_per_second: float) -> void:
	# Create hurricane effect timer
	var hurricane_timer = Timer.new()
	hurricane_timer.wait_time = duration
	hurricane_timer.one_shot = true
	hurricane_timer.timeout.connect(_on_hurricane_end)
	add_child(hurricane_timer)
	hurricane_timer.start()
	
	# Store hurricane data for continuous effect
	set_meta("hurricane_center", center)
	set_meta("hurricane_pull_force", pull_force)
	set_meta("hurricane_damage_per_second", damage_per_second)
	set_meta("hurricane_damage_timer", 0.0)
	
	# Add visual hurricane effect
	_add_hurricane_visual_effect()

# Update wind effects
func update_wind_effects(delta: float) -> void:
	# Update imbalance timer
	if is_imbalanced:
		imbalance_timer -= delta
		if imbalance_timer <= 0:
			set_imbalanced(false)
	
	# Update silence timer
	if is_silenced:
		silence_timer -= delta
		if silence_timer <= 0:
			set_silenced(false)
	
	# Update hurricane effect
	if has_meta("hurricane_center"):
		var damage_timer = get_meta("hurricane_damage_timer") as float
		damage_timer += delta
		
		if damage_timer >= 1.0:  # Apply damage every second
			damage_timer = 0.0
			var damage_per_second = get_meta("hurricane_damage_per_second") as float
			get_damage(damage_per_second)
			
			# Pull towards center
			var center = get_meta("hurricane_center") as Vector2
			var pull_force = get_meta("hurricane_pull_force") as float
			var direction = (center - global_position).normalized()
			global_position += direction * pull_force * delta
		
		set_meta("hurricane_damage_timer", damage_timer)

# Wind effect visual methods (placeholders)
func _add_imbalance_visual_effect() -> void:
	# Add dizziness or swirling effect
	modulate = Color(1.0, 0.8, 0.8)  # Slightly reddish tint

func _remove_imbalance_visual_effect() -> void:
	modulate = Color.WHITE

func _add_silence_visual_effect() -> void:
	# Add mute symbol or dimmed effect
	modulate = Color(0.7, 0.7, 0.7)  # Grayed out

func _remove_silence_visual_effect() -> void:
	modulate = Color.WHITE

func _add_knockback_visual_effect(direction: Vector2) -> void:
	# Add motion blur or lines in knockback direction
	var tween = create_tween()
	tween.tween_method(_update_knockback_visual, 0.0, 1.0, 0.3)

func _update_knockback_visual(progress: float) -> void:
	# Update knockback visual effect
	pass

func _add_exile_visual_effect() -> void:
	# Add portal or dimensional rift effect
	modulate.a = 0.3  # Very transparent

func _add_imprison_visual_effect() -> void:
	# Add cage or prison bars effect
	modulate = Color(0.5, 0.5, 1.0)  # Bluish tint

func _add_hurricane_visual_effect() -> void:
	# Add swirling wind or vortex effect
	modulate = Color(0.8, 0.8, 1.0)  # Light blue tint

func _on_exile_end() -> void:
	visible = true
	is_imbalanced = false
	_remove_exile_visual_effect()

func _on_hurricane_end() -> void:
	# Remove hurricane metadata
	remove_meta("hurricane_center")
	remove_meta("hurricane_pull_force")
	remove_meta("hurricane_damage_per_second")
	remove_meta("hurricane_damage_timer")
	_remove_hurricane_visual_effect()

func _remove_hurricane_visual_effect() -> void:
	modulate = Color.WHITE

func _remove_exile_visual_effect() -> void:
	modulate = Color.WHITE
	visible = true


## Physics System Methods

# Setup physics system for ground units
func setup_physics_system() -> void:
	if movement_type != MovementType.GROUND:
		return
	
	# 创建物理体
	physics_body = preload("res://Scenes/enemies/PhysicsEnemyMover.gd").new()
	get_parent().add_child(physics_body)
	physics_body.setup(self)
	physics_body.visible = false
	
	# 创建阻挡检测区域
	block_detection_area = Area2D.new()
	var detection_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 25  # 检测范围
	detection_shape.shape = shape
	block_detection_area.add_child(detection_shape)
	
	# 设置检测层
	block_detection_area.collision_layer = 0
	block_detection_area.collision_mask = 8  # 检测阻挡塔层
	
	add_child(block_detection_area)

# Check for nearby blocking towers
func check_for_blocking_towers() -> void:
	if not block_detection_area or using_physics_mode:
		return
	
	var blocking_towers = block_detection_area.get_overlapping_areas()
	for area in blocking_towers:
		var tower = area.get_parent()
		if is_instance_valid(tower) and tower.is_in_group("tower"):
			if tower.has_method("can_block_path") and tower.can_block_path and tower.is_alive:
				# 找到阻挡塔，切换到物理模式
				activate_physics_mode()
				return

# Activate physics mode
func activate_physics_mode() -> void:
	if using_physics_mode or not physics_body:
		return
	
	using_physics_mode = true
	
	# 计算前方的目标位置
	var future_progress = min(progress_ratio + 0.1, 1.0)  # 前方10%的位置
	var path = get_parent().get_node("Path2D").curve
	var target_pos = path.sample_baked(future_progress * path.get_baked_length())
	
	# 激活物理体
	physics_body.activate_physics_mode(get_parent().global_position + target_pos)
	
	print("Enemy switched to physics mode")

# Deactivate physics mode
func deactivate_physics_mode() -> void:
	if not using_physics_mode or not physics_body:
		return
	
	using_physics_mode = false
	physics_body.deactivate_physics_mode()
	
	print("Enemy returned to path mode")

## Ice Effect System Methods

# Apply speed modifier from ice effects
func apply_speed_modifier(source: String, multiplier: float) -> void:
	speed_modifiers[source] = multiplier
	_update_effective_speed()

# Remove speed modifier
func remove_speed_modifier(source: String) -> void:
	if source in speed_modifiers:
		speed_modifiers.erase(source)
		_update_effective_speed()

# Update effective speed based on all modifiers
func _update_effective_speed() -> void:
	if is_frozen or is_petrified:
		speed = 0.0
		return
	
	var total_multiplier = 1.0
	for modifier in speed_modifiers.values():
		total_multiplier *= modifier
	
	# Apply wind speed modifier
	total_multiplier *= wind_speed_modifier
	
	speed = base_speed * total_multiplier

# Set frost stacks
func set_frost_stacks(stacks: int) -> void:
	frost_stacks = max(0, stacks)
	
	# Apply frost slow effect (2% slow per stack)
	if frost_stacks > 0:
		var frost_slow = 1.0 - (frost_stacks * 0.02)
		apply_speed_modifier("frost", frost_slow)
	else:
		remove_speed_modifier("frost")

# Set frozen state
func set_frozen(frozen: bool, duration: float = 0.0) -> void:
	if frozen == is_frozen:
		return
	
	is_frozen = frozen
	freeze_duration = duration
	
	if is_frozen:
		freeze_timer = duration
		_update_effective_speed()
		# Add visual freeze effect
		_add_freeze_visual_effect()
	else:
		_update_effective_speed()
		# Remove visual freeze effect
		_remove_freeze_visual_effect()

# Apply defense modifier
func apply_defense_modifier(source: String, multiplier: float) -> void:
	defense_modifiers[source] = multiplier
	_update_effective_defense()

# Remove defense modifier
func remove_defense_modifier(source: String) -> void:
	if source in defense_modifiers:
		defense_modifiers.erase(source)
		_update_effective_defense()

# Update effective defense based on all modifiers
func _update_effective_defense() -> void:
	var base_defense = defense_modifiers.get("base", defense)
	var total_multiplier = 1.0
	
	for source in defense_modifiers:
		if source != "base":
			total_multiplier *= defense_modifiers[source]
	
	# Store the original base defense if not already stored
	if not defense_modifiers.has("base"):
		defense_modifiers["base"] = defense
	
	defense = base_defense * total_multiplier

# 土元素效果支持方法

# Set petrified state
func set_petrified(petrified: bool, duration: float = 0.0) -> void:
	if petrified == is_petrified:
		return
	
	is_petrified = petrified
	petrify_duration = duration
	
	if is_petrified:
		petrify_timer = duration
		_update_effective_speed()
		_update_effective_defense()
		# Add visual petrify effect
		_add_petrify_visual_effect()
	else:
		_update_effective_speed()
		_update_effective_defense()
		# Remove visual petrify effect
		_remove_petrify_visual_effect()

# Set weight stacks
func set_weight_stacks(stacks: int) -> void:
	weight_stacks = max(0, stacks)
	
	# Apply weight slow effect (1.5% slow per stack)
	if weight_stacks > 0:
		var weight_slow = 1.0 - (weight_stacks * 0.015)
		apply_speed_modifier("weight", weight_slow)
		
		# Apply defense reduction (1 defense per stack)
		var defense_reduction = weight_stacks * 1.0
		apply_defense_modifier("weight", max(0.1, 1.0 - defense_reduction / 100.0))
	else:
		remove_speed_modifier("weight")
		remove_defense_modifier("weight")

# Set armor break stacks
func set_armor_break_stacks(stacks: int) -> void:
	armor_break_stacks = max(0, stacks)
	
	# Apply armor break effect (5% defense reduction per stack)
	if armor_break_stacks > 0:
		var defense_reduction = armor_break_stacks * 0.05
		apply_defense_modifier("armor_break", max(0.1, 1.0 - defense_reduction))
	else:
		remove_defense_modifier("armor_break")

# Get movement type for compatibility
func get_movement_type() -> String:
	return "ground" if movement_type == MovementType.GROUND else "flying"


# Add freeze visual effect
func _add_freeze_visual_effect() -> void:
	# Create ice crystal effect
	var freeze_effect = ColorRect.new()
	freeze_effect.name = "FreezeEffect"
	freeze_effect.size = Vector2(40, 40)
	freeze_effect.position = Vector2(-20, -20)
	freeze_effect.color = Color.CYAN
	freeze_effect.modulate.a = 0.3
	add_child(freeze_effect)
	
	# Stop any ongoing animations
	set_process(false)

# Remove freeze visual effect
func _remove_freeze_visual_effect() -> void:
	var freeze_effect = get_node_or_null("FreezeEffect")
	if freeze_effect:
		freeze_effect.queue_free()
	
	# Resume processing
	set_process(true)

# Get current frost stacks
func get_frost_stacks() -> int:
	return frost_stacks

# Get frozen state
func get_is_frozen() -> bool:
	return is_frozen

# Add petrify visual effect
func _add_petrify_visual_effect() -> void:
	# Create stone texture effect
	var petrify_effect = ColorRect.new()
	petrify_effect.name = "PetrifyEffect"
	petrify_effect.size = Vector2(40, 40)
	petrify_effect.position = Vector2(-20, -20)
	petrify_effect.color = Color.SADDLE_BROWN
	petrify_effect.modulate.a = 0.6
	add_child(petrify_effect)
	
	# Change sprite to stone texture
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color.GRAY
	
	# Stop any ongoing animations
	set_process(false)

# Remove petrify visual effect
func _remove_petrify_visual_effect() -> void:
	var petrify_effect = get_node_or_null("PetrifyEffect")
	if petrify_effect:
		petrify_effect.queue_free()
	
	# Restore sprite color
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color.WHITE
	
	# Resume processing
	set_process(true)

# Get current weight stacks
func get_weight_stacks() -> int:
	return weight_stacks

# Get current armor break stacks
func get_armor_break_stacks() -> int:
	return armor_break_stacks

# Get petrified state
func get_is_petrified() -> bool:
	return is_petrified

# Get max health for percentage damage calculations
func get_max_health() -> float:
	return max_hp



# Light Element Effect System
var is_blinded: bool = false
var blind_miss_chance: float = 0.0
var blind_timer: float = 0.0
var blind_duration: float = 0.0

var is_judged: bool = false
var judgment_damage_multiplier: float = 1.0
var judgment_timer: float = 0.0
var judgment_duration: float = 0.0
var holy_damage_on_death: bool = false

var active_buffs: Array = []  # Track active buffs for purify effect

# HP条相关变量
var health_bar_container: Control
var health_bar_bg: ColorRect
var health_bar_fg: ColorRect
var health_label: Label

# Set blind status
func set_blinded(blinded: bool, miss_chance: float = 0.50, duration: float = 0.0) -> void:
	is_blinded = blinded
	blind_miss_chance = miss_chance
	blind_duration = duration
	blind_timer = duration
	
	if blinded:
		# Apply visual effects for blind
		modulate = Color(0.7, 0.7, 0.3, 0.8)  # Yellowish tint
	else:
		# Remove visual effects
		reset_visual_modulation()

# Set judgment status
func set_judgment(judged: bool, damage_multiplier: float = 1.20, duration: float = 0.0) -> void:
	is_judged = judged
	judgment_damage_multiplier = damage_multiplier
	judgment_duration = duration
	judgment_timer = duration
	
	if judged:
		# Apply visual effects for judgment
		modulate = Color(1.0, 0.8, 0.2, 0.9)  # Golden tint
	else:
		# Remove visual effects
		reset_visual_modulation()

# Set holy damage on death
func set_holy_damage_on_death(enabled: bool) -> void:
	holy_damage_on_death = enabled

# Purify buffs - remove all active buffs
func purify_buffs() -> void:
	active_buffs.clear()
	# Remove all positive effects
	# This would interact with any buff system the enemy has
	# For now, just clear the buffs array
	print("Enemy purged of all buffs")

# Add buff for tracking (would be called by buff system)
func add_buff(buff_name: String) -> void:
	if not active_buffs.has(buff_name):
		active_buffs.append(buff_name)

# Remove buff
func remove_buff(buff_name: String) -> void:
	active_buffs.erase(buff_name)

# Check if has specific buff
func has_buff(buff_name: String) -> bool:
	return active_buffs.has(buff_name)

# Get blind miss chance
func get_blind_miss_chance() -> float:
	return blind_miss_chance if is_blinded else 0.0

# Get judgment damage multiplier
func get_judgment_damage_multiplier() -> float:
	return judgment_damage_multiplier if is_judged else 1.0

# Reset visual modulation
func reset_visual_modulation() -> void:
	if not is_blinded and not is_judged:
		modulate = Color.WHITE

# Handle light effect timers
func update_light_effects(delta: float) -> void:
	# Update blind timer
	if is_blinded:
		blind_timer -= delta
		if blind_timer <= 0:
			set_blinded(false)
	
	# Update judgment timer
	if is_judged:
		judgment_timer -= delta
		if judgment_timer <= 0:
			set_judgment(false)

# Shadow Effect Methods

# Set corrosion stacks
func set_corrosion_stacks(stacks: int) -> void:
	corrosion_stacks = max(0, stacks)
	_update_effective_defense()

# Set fear effect
func set_feared(feared: bool, miss_chance: float = 0.50, duration: float = 2.0) -> void:
	is_feared = feared
	if feared:
		fear_miss_chance = miss_chance
		fear_duration = duration
		fear_timer = duration
		_add_fear_visual_effect()
	else:
		fear_miss_chance = 0.0
		fear_timer = 0.0
		_remove_fear_visual_effect()

# Apply life drain effect
func apply_life_drain(drain_percent: float) -> void:
	life_drain_stacks += 1
	life_drain_duration = 3.0
	life_drain_timer = 3.0

# Apply healing reduction
func apply_healing_reduction(reduction_percent: float) -> void:
	healing_reduction = reduction_percent

# Remove healing reduction
func remove_healing_reduction() -> void:
	healing_reduction = 0.0

# Set no healing effect
func set_no_healing(no_heal: bool, duration: float = 5.0) -> void:
	no_healing = no_heal
	if no_heal:
		no_healing_timer = duration
		_add_no_healing_visual_effect()
	else:
		no_healing_timer = 0.0
		_remove_no_healing_visual_effect()

# Get corrosion stacks
func get_corrosion_stacks() -> int:
	return corrosion_stacks

# Get fear miss chance
func get_fear_miss_chance() -> float:
	return fear_miss_chance if is_feared else 0.0

# Get life drain percent
func get_life_drain_percent() -> float:
	return life_drain_stacks * 0.10

# Get is feared
func get_is_feared() -> bool:
	return is_feared

# Get is life drained
func get_is_life_drained() -> bool:
	return life_drain_stacks > 0

# Get healing reduction
func get_healing_reduction() -> float:
	return healing_reduction

# Get can heal (checks no healing effect)
func get_can_heal() -> bool:
	return can_heal and not no_healing

# Update shadow effects
func update_shadow_effects(delta: float) -> void:
	# Update fear timer
	if is_feared:
		fear_timer -= delta
		if fear_timer <= 0:
			set_feared(false)
	
	# Update life drain timer
	if life_drain_stacks > 0:
		life_drain_timer -= delta
		if life_drain_timer <= 0:
			life_drain_stacks = max(0, life_drain_stacks - 1)
			if life_drain_stacks > 0:
				life_drain_timer = life_drain_duration
	
	# Update no healing timer
	if no_healing:
		no_healing_timer -= delta
		if no_healing_timer <= 0:
			set_no_healing(false)

# Visual effects for shadow effects
func _add_fear_visual_effect() -> void:
	modulate = Color(0.5, 0.0, 0.5)  # Dark purple
	# Add particle effects or other visual indicators

func _remove_fear_visual_effect() -> void:
	reset_visual_modulation()

func _add_no_healing_visual_effect() -> void:
	modulate = Color(0.3, 0.0, 0.3)  # Dark red
	# Add visual indicators for no healing

func _remove_no_healing_visual_effect() -> void:
	reset_visual_modulation()

# Handle fear movement (move away from source)
func handle_fear_movement(source_position: Vector2, delta: float) -> void:
	if is_feared and not is_frozen and not is_petrified:
		var direction_away = (global_position - source_position).normalized()
		var fear_speed = base_speed * 2.0  # Move faster when feared
		global_position += direction_away * fear_speed * delta

# Apply damage with life steal calculation
func take_damage_with_life_steal(damage: float, attacker: Node) -> void:
	var actual_damage = get_damage(damage)
	
	# Apply life steal to attacker if it has the effect
	if attacker and attacker.has_method("apply_life_steal"):
		var life_steal_percent = get_life_drain_percent()
		if life_steal_percent > 0:
			attacker.apply_life_steal(actual_damage * life_steal_percent)

# Override heal method to account for healing reduction
func heal(amount: float) -> void:
	if no_healing:
		return  # Cannot heal when under no healing effect
	
	var effective_amount = amount
	if healing_reduction > 0:
		effective_amount = amount * (1.0 - healing_reduction)
	
	hp = min(hp + effective_amount, max_hp)
	
	# 更新HP条
	update_health_bar()

# 创建HP条
func create_health_bar():
	# 创建容器
	health_bar_container = Control.new()
	health_bar_container.size = Vector2(40, 8)
	health_bar_container.position = Vector2(-20, -45)  # 在敌人头上方
	health_bar_container.z_index = 20  # 确保HP条显示在最上层
	add_child(health_bar_container)
	
	# 创建背景条
	health_bar_bg = ColorRect.new()
	health_bar_bg.size = Vector2(40, 6)
	health_bar_bg.position = Vector2(0, 1)
	health_bar_bg.color = Color.BLACK
	health_bar_container.add_child(health_bar_bg)
	
	# 创建前景HP条
	health_bar_fg = ColorRect.new()
	health_bar_fg.size = Vector2(40, 6)
	health_bar_fg.position = Vector2(0, 1)
	health_bar_fg.color = Color(0.0, 0.6, 0.0)  # 更深的绿色
	health_bar_container.add_child(health_bar_fg)
	
	# 创建HP数值标签（隐藏）
	health_label = Label.new()
	health_label.visible = false  # 隐藏数字显示
	health_bar_container.add_child(health_label)
	
	# 初始更新
	update_health_bar()

# 更新HP条显示
func update_health_bar():
	if not health_bar_fg or not health_label:
		return
	
	var health_ratio = hp / max_hp
	health_bar_fg.size.x = 40 * health_ratio
	
	# 根据生命值百分比改变颜色
	if health_ratio > 0.6:
		health_bar_fg.color = Color(0.0, 0.6, 0.0)  # 深绿色
	elif health_ratio > 0.3:
		health_bar_fg.color = Color.YELLOW
	else:
		health_bar_fg.color = Color.RED
